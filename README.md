# Low Power Automation for macOS

A lightweight, dependency-free macOS automation that enables Low Power Mode at a battery percentage selected by the user.

> **Beta compatibility notice:** This release has been tested only on a MacBook Neo running macOS 26.6. It may work on other Mac laptops that support Low Power Mode, but those configurations have not yet been tested.

## Behavior

- On battery at or below the chosen threshold: Low Power Mode turns on.
- On battery above the threshold: Low Power Mode turns off.
- Connected to power: Low Power Mode turns off.
- Checks at startup and every 60 seconds.
- Supports thresholds from 10% through 90%.

## Installation

1. Double-click **Install Low Power Automation.command**.
2. Choose a percentage.
3. Enter an administrator password when macOS asks.

If macOS blocks the unsigned community script, Control-click it, choose **Open**, then confirm **Open**. Review the included source before installing if desired.

## Change the threshold

Double-click **Change Threshold.command** and choose a new percentage.

## Uninstall

Double-click **Uninstall Low Power Automation.command**. The uninstaller restores the battery and AC Low Power Mode settings recorded during the first installation.

## Requirements and privacy

- A Mac laptop that supports Low Power Mode.
- This beta has been verified only on a MacBook Neo running macOS 26.6.
- Administrator access during installation, configuration changes, and removal.
- No third-party dependencies, network access, analytics, or collected data.

The automation uses Apple's built-in `pmset` command. Its background process is installed as a root-owned LaunchDaemon because changing system power settings requires administrator privileges.

## Verify operation

Run:

```sh
sudo launchctl print system/com.community.low-power-automation
```

`runs` should increase over time and `last exit code = 0` indicates success. A state of `not running` is normal between one-minute checks.

## Community distribution

This bundle is source-readable but unsigned. For broad distribution without Gatekeeper's Control-click flow, package, sign, and notarize it with an Apple Developer ID certificate.

## Help test other Macs

If you try this beta on another Mac, please report:

- Mac model
- macOS version
- Selected battery threshold
- Whether installation completed
- Whether Low Power Mode switched correctly
- Whether changing the threshold worked
- Whether uninstallation restored the previous settings
