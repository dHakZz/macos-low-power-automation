# Low Power Automation v1.0.0 Beta 1

## Compatibility notice

This beta has been tested only on a MacBook Neo running macOS 26.6. It may work on other Mac laptops that support Low Power Mode, but those configurations have not yet been tested.

## Features

- Enables Low Power Mode at a battery percentage selected during installation.
- Supports thresholds from 10% through 90%.
- Disables Low Power Mode above the threshold or when connected to power.
- Checks at startup and once every 60 seconds.
- Includes a separate threshold-changing utility.
- Includes an uninstaller that restores the original energy settings.
- Uses no network connections, analytics, or third-party dependencies.

## Testing requests

When reporting results, include the Mac model, macOS version, selected threshold, and whether installation, automatic switching, threshold changes, and uninstallation worked.

## Important

This beta is unsigned. macOS may require users to Control-click the installer and select **Open**. Administrator access is required because changing system power settings requires elevated privileges.
