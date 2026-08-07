#!/bin/zsh
set -euo pipefail
(( EUID == 0 )) || { print -u2 "Administrator privileges are required."; exit 1; }

INSTALL_DIR="/usr/local/libexec/low-power-automation"
SUPPORT_DIR="/Library/Application Support/Low Power Automation"
STATE="$SUPPORT_DIR/original-settings"
PLIST="/Library/LaunchDaemons/com.community.low-power-automation.plist"

/bin/launchctl bootout system/com.community.low-power-automation >/dev/null 2>&1 || true
if [[ -f "$STATE" ]]; then
  battery_mode="$(/usr/bin/awk -F= '$1=="battery"{print $2}' "$STATE")"
  ac_mode="$(/usr/bin/awk -F= '$1=="ac"{print $2}' "$STATE")"
  [[ "$battery_mode" =~ '^[0-2]$' ]] && /usr/bin/pmset -b lowpowermode "$battery_mode"
  [[ "$ac_mode" =~ '^[0-2]$' ]] && /usr/bin/pmset -c lowpowermode "$ac_mode"
fi

/bin/rm -f "$PLIST" "$INSTALL_DIR/low-power-watcher.sh" "$INSTALL_DIR/configure.sh" "$INSTALL_DIR/uninstall.sh" "$STATE" "$SUPPORT_DIR/config" /var/log/low-power-automation.log /var/log/low-power-automation-error.log
/bin/rmdir "$INSTALL_DIR" "$SUPPORT_DIR" 2>/dev/null || true
