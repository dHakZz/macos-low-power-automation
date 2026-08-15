# Low Power Automation

A lightweight, dependency-free macOS automation that turns Low Power Mode on at a battery percentage you choose.

> [!IMPORTANT]
> **Beta compatibility:** v1.0.0 Beta 1 has been tested only on a MacBook Neo running macOS 26.6. Other Mac laptops that support Low Power Mode may work, but have not yet been verified.

## What it does

Low Power Automation runs quietly in the background and manages Low Power Mode based on the Mac's power source and current battery level.

- Turns Low Power Mode **on** at or below your chosen battery threshold
- Turns Low Power Mode **off** above the threshold
- Turns Low Power Mode **off** while connected to power
- Checks once when the service starts and every 60 seconds afterward
- Supports any whole-number threshold from **10% through 90%**
- Starts automatically as a system LaunchDaemon
- Uses only built-in macOS tools—no third-party dependencies
- Runs entirely on your Mac with no networking, analytics, or data collection

## Download

**[Download the installer bundle](https://github.com/dHakZz/macos-low-power-automation/archive/refs/heads/main.zip)**

After unzipping it, keep the three `.command` files and the `payload` folder together.

## Install

1. Download and unzip the installer bundle.
2. Double-click **Install Low Power Automation.command**.
3. Enter a whole-number threshold from **10 through 90**. The installer starts with 50% as the suggested value.
4. Enter an administrator password when macOS asks.
5. Wait for the **Low Power Automation is installed** message.

If macOS blocks the unsigned installer, Control-click **Install Low Power Automation.command**, choose **Open**, then confirm **Open**. The included scripts are source-readable if you would like to review them first.

## Threshold behavior

| Power state | Battery level | Low Power Mode |
| --- | --- | --- |
| On battery | At or below the threshold | On |
| On battery | Above the threshold | Off |
| Connected to power | Any level | Off |

The check runs when the background service starts and once every 60 seconds after that.

To choose a different threshold later, double-click **Change Threshold.command**, enter a new value from 10 through 90, and approve the administrator prompt. The new setting is saved and checked immediately; reinstalling is not required.

## Requirements

- A Mac laptop that supports Low Power Mode
- Administrator access for installation, threshold changes, and removal
- For this beta, a willingness to test outside the verified MacBook Neo and macOS 26.6 configuration

Low Power Automation uses Apple's built-in `pmset` command. Its background process runs as a root-owned LaunchDaemon because changing system power settings requires administrator privileges.

## Uninstall

Double-click **Uninstall Low Power Automation.command** and approve the administrator prompt.

The uninstaller removes the LaunchDaemon, installed scripts, saved configuration, and logs. When available, it also restores the battery and AC Low Power Mode settings recorded during the first installation.

## Troubleshooting

- **macOS says the installer cannot be opened:** Control-click the installer, choose **Open**, then confirm **Open**.
- **The installer says it is incomplete:** Keep the `payload` folder beside the three `.command` files and try again.
- **The threshold changer says the automation is not installed:** Run **Install Low Power Automation.command** first.
- **Low Power Mode has not changed yet:** Allow up to 60 seconds, then verify the service using the command below.

```sh
sudo launchctl print system/com.community.low-power-automation
```

`runs` should increase over time, and `last exit code = 0` indicates a successful check. A state of `not running` is normal between the one-minute checks. Errors written by the background process are stored at `/var/log/low-power-automation-error.log`.

If the problem continues, [open a bug report](https://github.com/dHakZz/macos-low-power-automation/issues/new/choose) with your Mac model, macOS version, selected threshold, and what you expected to happen.

## Included files

| File | Purpose |
| --- | --- |
| `Install Low Power Automation.command` | Chooses the initial threshold and installs the automation |
| `Change Threshold.command` | Updates the threshold without reinstalling |
| `Uninstall Low Power Automation.command` | Removes the automation and restores saved power settings |
| `payload/` | Contains the readable LaunchDaemon and shell-script source |

## Privacy

There are no accounts, network connections, analytics, advertising, or collected data. Everything runs locally using macOS system tools.

## Help test other Macs

This beta has only been verified on a MacBook Neo running macOS 26.6. If you try it on another Mac, please [share your results](https://github.com/dHakZz/macos-low-power-automation/issues/new/choose), including the Mac model, macOS version, selected threshold, and whether installation, automatic switching, threshold changes, and uninstallation worked.

## License

Released under the [MIT License](LICENSE).
