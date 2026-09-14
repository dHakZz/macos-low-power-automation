import AppKit

let configPath = "/Library/Application Support/Low Power Automation/config"
let serviceLabel = "system/com.community.low-power-automation"

struct Config {
    var enabled = true; var onThreshold = 40; var offThreshold = 50; var pluggedMode = "automatic"
}

func readConfig() -> Config {
    guard let text = try? String(contentsOfFile: configPath, encoding: .utf8) else { return Config() }
    var values: [String: String] = [:]
    text.split(separator: "\n").forEach { line in
        let pair = line.split(separator: "=", maxSplits: 1).map(String.init); if pair.count == 2 { values[pair[0]] = pair[1] }
    }
    return Config(enabled: values["enabled"] != "false", onThreshold: Int(values["onThreshold"] ?? "40") ?? 40,
                  offThreshold: Int(values["offThreshold"] ?? "50") ?? 50, pluggedMode: values["pluggedMode"] ?? "automatic")
}

func run(_ executable: String, _ arguments: [String]) -> (Int32, String) {
    let task = Process(); let pipe = Pipe(); task.executableURL = URL(fileURLWithPath: executable)
    task.arguments = arguments; task.standardOutput = pipe; task.standardError = pipe
    do { try task.run(); task.waitUntilExit() } catch { return (1, error.localizedDescription) }
    return (task.terminationStatus, String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "")
}

func batteryInfo() -> (Int, Bool) {
    let output = run("/usr/bin/pmset", ["-g", "batt"]).1
    let pct = output.range(of: #"\d+(?=%;)"#, options: .regularExpression).flatMap { Int(output[$0]) } ?? 0
    return (pct, output.contains("Battery Power"))
}

func lowPowerMode(onBattery: Bool) -> Bool {
    let output = run("/usr/bin/pmset", ["-g", "custom"]).1
    let header = onBattery ? "Battery Power:" : "AC Power:"
    var inSection = false
    for line in output.split(separator: "\n").map(String.init) {
        if line == header { inSection = true; continue }
        if inSection && !(line.first == " " || line.first == "\t") { break }
        let fields = line.split(whereSeparator: { $0 == " " || $0 == "\t" })
        if inSection && fields.count >= 2 && fields[0] == "lowpowermode" { return fields[1] != "0" }
    }
    return false
}

func icon(active: Bool, lowPower: Bool, error: Bool = false) -> NSImage {
    let image = NSImage(size: NSSize(width: 22, height: 18), flipped: false) { rect in
        NSColor.labelColor.setStroke(); NSColor.labelColor.setFill()
        let body = NSBezierPath(roundedRect: NSRect(x: 1, y: 4, width: 14, height: 10), xRadius: 2, yRadius: 2)
        body.lineWidth = 1.7; body.stroke()
        NSBezierPath(roundedRect: NSRect(x: 15.7, y: 7, width: 2, height: 4), xRadius: 0.7, yRadius: 0.7).fill()
        if lowPower { NSBezierPath(roundedRect: NSRect(x: 3, y: 6, width: 5, height: 6), xRadius: 1, yRadius: 1).fill() }
        let badge = NSBezierPath(ovalIn: NSRect(x: 11, y: 0.5, width: 10, height: 10)); badge.lineWidth = 1.5; badge.stroke()
        let mark = NSBezierPath(); mark.lineWidth = 1.4; mark.lineCapStyle = .round; mark.lineJoinStyle = .round
        if error { mark.move(to: NSPoint(x: 16, y: 3)); mark.line(to: NSPoint(x: 16, y: 7)); mark.stroke(); NSBezierPath(ovalIn: NSRect(x: 15.3, y: 1.5, width: 1.4, height: 1.4)).fill() }
        else if !active { mark.move(to: NSPoint(x: 14.7, y: 3)); mark.line(to: NSPoint(x: 14.7, y: 7.5)); mark.move(to: NSPoint(x: 17.3, y: 3)); mark.line(to: NSPoint(x: 17.3, y: 7.5)); mark.stroke() }
        else { mark.appendArc(withCenter: NSPoint(x: 16, y: 5.5), radius: 2.5, startAngle: 30, endAngle: 275); mark.stroke(); let arrow = NSBezierPath(); arrow.move(to: NSPoint(x: 13.2, y: 6)); arrow.line(to: NSPoint(x: 13.7, y: 3.8)); arrow.line(to: NSPoint(x: 15.4, y: 5.2)); arrow.fill() }
        return true
    }
    image.isTemplate = true; return image
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    var timer: Timer?
    func applicationDidFinishLaunching(_ notification: Notification) {
        item.button?.image = icon(active: true, lowPower: false); rebuildMenu()
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in self?.rebuildMenu() }
    }
    func rebuildMenu() {
        let config = readConfig(); let power = batteryInfo(); let menu = NSMenu()
        let lowPower = lowPowerMode(onBattery: power.1)
        item.button?.image = icon(active: config.enabled, lowPower: lowPower)
        let status = NSMenuItem(title: "Battery \(power.0)% · \(power.1 ? "On Battery" : "Plugged In") · \(lowPower ? "Low Power" : "Automatic")", action: nil, keyEquivalent: ""); status.isEnabled = false; menu.addItem(status)
        let toggle = NSMenuItem(title: "Automation Enabled", action: #selector(toggleEnabled), keyEquivalent: ""); toggle.target = self; toggle.state = config.enabled ? .on : .off; menu.addItem(toggle)
        menu.addItem(.separator())
        addItem(menu, "Turn On at \(config.onThreshold)%…", #selector(changeOn))
        addItem(menu, "Turn Off at \(config.offThreshold)%…", #selector(changeOff))
        let plugged = NSMenuItem(title: "When Plugged In", action: nil, keyEquivalent: ""); let sub = NSMenu()
        [("Use Automatic Mode", "automatic"), ("Use Low Power Mode", "lowPower"), ("Leave Unchanged", "unchanged")].forEach { title, value in
            let mi = NSMenuItem(title: title, action: #selector(setPluggedMode(_:)), keyEquivalent: ""); mi.target = self; mi.representedObject = value; mi.state = config.pluggedMode == value ? .on : .off; sub.addItem(mi)
        }; plugged.submenu = sub; menu.addItem(plugged)
        menu.addItem(.separator()); addItem(menu, "Check Now", #selector(checkNow)); addItem(menu, "Diagnostics…", #selector(diagnostics)); addItem(menu, "Open Battery Settings…", #selector(openSettings))
        menu.addItem(.separator()); addItem(menu, "Quit Menu Bar App", #selector(quit)); item.menu = menu
    }
    func addItem(_ menu: NSMenu, _ title: String, _ action: Selector) { let mi = NSMenuItem(title: title, action: action, keyEquivalent: ""); mi.target = self; menu.addItem(mi) }
    func configure(_ key: String, _ value: String) {
        let command = "/usr/local/libexec/low-power-automation/configure.sh \(key) \(value)"
        let script = "do shell script \"\(command)\" with administrator privileges"
        if run("/usr/bin/osascript", ["-e", script]).0 != 0 { alert("The setting could not be saved.") }; rebuildMenu()
    }
    @objc func toggleEnabled() { configure("enabled", readConfig().enabled ? "false" : "true") }
    func ask(_ title: String, current: Int, minimum: Int, maximum: Int) -> Int? {
        let alert = NSAlert(); alert.messageText = title; alert.informativeText = "Enter a whole number from \(minimum) through \(maximum)."; alert.addButton(withTitle: "Save"); alert.addButton(withTitle: "Cancel")
        let field = NSTextField(string: String(current)); field.frame = NSRect(x: 0, y: 0, width: 220, height: 24); alert.accessoryView = field
        guard alert.runModal() == .alertFirstButtonReturn, let value = Int(field.stringValue), (minimum...maximum).contains(value) else { return nil }; return value
    }
    @objc func changeOn() { let c = readConfig(); if let v = ask("Turn Low Power Mode On At", current: c.onThreshold, minimum: 10, maximum: min(90, c.offThreshold - 1)) { configure("onThreshold", String(v)) } }
    @objc func changeOff() { let c = readConfig(); if let v = ask("Turn Low Power Mode Off At", current: c.offThreshold, minimum: c.onThreshold + 1, maximum: 95) { configure("offThreshold", String(v)) } }
    @objc func setPluggedMode(_ sender: NSMenuItem) { configure("pluggedMode", sender.representedObject as! String) }
    @objc func checkNow() { _ = run("/usr/bin/osascript", ["-e", "do shell script \"/bin/launchctl kickstart -k \(serviceLabel)\" with administrator privileges"]); rebuildMenu() }
    @objc func diagnostics() {
        let c = readConfig(), p = batteryInfo(), service = run("/bin/launchctl", ["print", serviceLabel])
        let ok = service.0 == 0; let message = "Service: \(ok ? "Installed" : "Not running")\nBattery: \(p.0)% (\(p.1 ? "battery" : "adapter"))\nAutomation: \(c.enabled ? "Enabled" : "Paused")\nThresholds: On at \(c.onThreshold)%, off at \(c.offThreshold)%\nPlugged in: \(c.pluggedMode)"
        alert(message, title: ok ? "Low Power Automation is Healthy" : "Low Power Automation Needs Attention")
    }
    @objc func openSettings() { NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Battery-Settings.extension")!) }
    @objc func quit() { NSApplication.shared.terminate(nil) }
    func alert(_ message: String, title: String = "Low Power Automation") { let a = NSAlert(); a.messageText = title; a.informativeText = message; a.runModal() }
}

let app = NSApplication.shared; let delegate = AppDelegate(); app.delegate = delegate; app.setActivationPolicy(.accessory); app.run()
