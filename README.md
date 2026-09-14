# Low Power Automation 2.0

A native, privacy-friendly macOS menu-bar utility that manages Apple's built-in Low Power Mode.

**[Download Low Power Automation v2.0.0 Beta 1](https://github.com/dHakZz/macos-low-power-automation/releases/download/v2.0.0-beta.1/Low-Power-Automation-v2.0.0.zip)**

## What's new

- Native menu-bar control using the battery + automation icon
- Reacts to macOS battery and charger events instead of launching a script every minute
- Five-minute fallback check for reliability
- Separate on/off thresholds (hysteresis) to prevent rapid switching
- Plugged-in choices: Automatic, Low Power, or Leave Unchanged
- Pause/resume, Check Now, Battery Settings, and built-in diagnostics
- Starts automatically and migrates/removes the earlier prototype
- Restores the user's original power settings when uninstalled

## How it behaves

| Situation | Result |
| --- | --- |
| Battery reaches the **on** threshold | Low Power Mode turns on |
| Battery rises to the **off** threshold | Low Power Mode turns off |
| Battery is between the two thresholds | Current mode is preserved |
| Power adapter is connected | Uses your selected plugged-in policy |

The gap between the thresholds prevents the mode from repeatedly switching when the battery is near one percentage. The service normally reacts to macOS power events and performs one fallback check every five minutes. It makes no network requests and has negligible idle overhead.

## Install

1. Unzip the download.
2. Control-click **Install Low Power Automation.command**, choose **Open**, and confirm.
3. Choose the on threshold, off threshold, and plugged-in behavior.
4. Enter an administrator password when asked.

The menu-bar app installs in `/Applications`. The power service runs separately, so choosing **Quit Menu Bar App** hides the controls without stopping the automation. Log out and back in to reopen it, or open **Low Power Automation** from Applications.

Upgrading from version 1 is supported. The installer stops and removes the older service after preserving the original power settings.

## Verify and troubleshoot

Choose **Diagnostics…** from the menu-bar icon. The panel shows the service, battery, thresholds, and current policy in plain language.

Technical check:

```sh
sudo launchctl print system/com.community.low-power-automation
```

Logs are stored at `/Library/Logs/Low Power Automation.log`. No network requests, analytics, accounts, or third-party dependencies are used.

If something goes wrong, [open an issue](https://github.com/dHakZz/macos-low-power-automation/issues/new/choose) and include the Diagnostics results, Mac model, and macOS version.

## Uninstall

Run **Uninstall Low Power Automation.command** and approve the administrator prompt. The app, background service, configuration, and logs are removed. The battery and plugged-in settings saved during the first installation are restored when available.

## Security and privacy

The menu-bar app runs as the signed-in user. A small root-owned service performs only local battery checks and calls Apple's built-in `pmset` utility when the energy mode needs to change. Configuration changes require an administrator prompt. All Swift and shell source is included in this repository for review.

## Repository layout

| Path | Purpose |
| --- | --- |
| `Source/` | Native Swift menu-bar app and event-driven service |
| `app/` | App metadata; the release ZIP also contains the built app bundle |
| `payload/` | LaunchDaemon, login item, and privileged helper source |
| `Developer/` | Reproducible universal build script |

## Compatibility and distribution

Built as a universal app for Intel and Apple silicon Macs running macOS 13 or newer. Low Power Mode must be supported by the Mac.

This community build is ad-hoc signed for integrity, but it is not Developer ID signed or notarized, so Gatekeeper may require the Control-click/Open flow. A warning-free public release requires an Apple Developer ID and notarization.

## License

Released under the [MIT License](LICENSE).
