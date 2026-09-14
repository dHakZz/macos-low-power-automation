import Foundation
import IOKit.ps

let configPath = "/Library/Application Support/Low Power Automation/config"
let logPath = "/Library/Logs/Low Power Automation.log"

struct Config {
    var enabled = true
    var onThreshold = 40
    var offThreshold = 50
    var pluggedMode = "automatic"
}

func log(_ message: String) {
    let formatter = ISO8601DateFormatter()
    let line = "\(formatter.string(from: Date())) \(message)\n"
    if let data = line.data(using: .utf8) {
        if !FileManager.default.fileExists(atPath: logPath) {
            FileManager.default.createFile(atPath: logPath, contents: nil)
        }
        if let handle = try? FileHandle(forWritingTo: URL(fileURLWithPath: logPath)) {
            defer { try? handle.close() }
            _ = try? handle.seekToEnd()
            try? handle.write(contentsOf: data)
        }
    }
}

func loadConfig() -> Config? {
    guard let text = try? String(contentsOfFile: configPath, encoding: .utf8) else {
        log("error: configuration could not be read")
        return nil
    }
    var values: [String: String] = [:]
    for line in text.split(separator: "\n") {
        let pair = line.split(separator: "=", maxSplits: 1).map(String.init)
        if pair.count == 2 { values[pair[0]] = pair[1] }
    }
    guard let on = Int(values["onThreshold"] ?? ""),
          let off = Int(values["offThreshold"] ?? ""),
          (10...90).contains(on), (10...95).contains(off), off > on,
          ["automatic", "lowPower", "unchanged"].contains(values["pluggedMode"] ?? "") else {
        log("error: configuration is invalid")
        return nil
    }
    return Config(enabled: values["enabled"] != "false", onThreshold: on,
                  offThreshold: off, pluggedMode: values["pluggedMode"]!)
}

func powerSnapshot() -> (percentage: Int, onBattery: Bool)? {
    guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
          let list = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef] else { return nil }
    for source in list {
        guard let description = IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue() as? [String: Any],
              let current = description[kIOPSCurrentCapacityKey] as? Int,
              let maximum = description[kIOPSMaxCapacityKey] as? Int, maximum > 0,
              let state = description[kIOPSPowerSourceStateKey] as? String else { continue }
        return (Int((Double(current) / Double(maximum) * 100.0).rounded()), state == kIOPSBatteryPowerValue)
    }
    return nil
}

func currentMode(forBattery: Bool) -> Int? {
    let task = Process(); let pipe = Pipe()
    task.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
    task.arguments = ["-g", "custom"]; task.standardOutput = pipe
    try? task.run(); task.waitUntilExit()
    guard let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) else { return nil }
    var inSection = false
    for line in output.split(separator: "\n").map(String.init) {
        if line == (forBattery ? "Battery Power:" : "AC Power:") { inSection = true; continue }
        if inSection && !line.first.map({ $0 == " " || $0 == "\t" })! { break }
        if inSection {
            let fields = line.split(whereSeparator: { $0 == " " || $0 == "\t" })
            if fields.count >= 2 && fields[0] == "lowpowermode" { return Int(fields[1]) }
        }
    }
    return nil
}

func setMode(_ mode: Int, forBattery: Bool, reason: String) {
    guard currentMode(forBattery: forBattery) != mode else { return }
    let task = Process(); task.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
    task.arguments = [forBattery ? "-b" : "-c", "lowpowermode", String(mode)]
    do { try task.run(); task.waitUntilExit() } catch { log("error: pmset could not run: \(error)"); return }
    if task.terminationStatus == 0 { log("mode=\(mode) reason=\(reason)") }
    else { log("error: pmset exited \(task.terminationStatus)") }
}

func evaluate() {
    guard let config = loadConfig(), config.enabled, let power = powerSnapshot() else { return }
    if power.onBattery {
        if power.percentage <= config.onThreshold {
            setMode(1, forBattery: true, reason: "battery \(power.percentage)% <= \(config.onThreshold)%")
        } else if power.percentage >= config.offThreshold {
            setMode(0, forBattery: true, reason: "battery \(power.percentage)% >= \(config.offThreshold)%")
        }
    } else if config.pluggedMode != "unchanged" {
        setMode(config.pluggedMode == "lowPower" ? 1 : 0, forBattery: false, reason: "power adapter connected")
    }
}

@main
struct LowPowerDaemon {
    static func main() {
        let callback: IOPowerSourceCallbackType = { _ in evaluate() }
        evaluate()
        guard let source = IOPSNotificationCreateRunLoopSource(callback, nil)?.takeRetainedValue() else {
            log("error: could not subscribe to power-source changes")
            exit(1)
        }
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .defaultMode)
        let fallback = CFRunLoopTimerCreateWithHandler(nil, CFAbsoluteTimeGetCurrent() + 300, 300, 0, 0) { _ in evaluate() }
        CFRunLoopAddTimer(CFRunLoopGetCurrent(), fallback, .defaultMode)
        log("service started")
        CFRunLoopRun()
    }
}
