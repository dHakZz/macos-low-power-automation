#!/bin/zsh
set -euo pipefail
(( EUID == 0 )) || { print -u2 "Administrator privileges are required."; exit 1; }
INSTALL_DIR="/usr/local/libexec/low-power-automation"; SUPPORT_DIR="/Library/Application Support/Low Power Automation"
STATE="$SUPPORT_DIR/original-settings"; CONSOLE_USER="$(/usr/bin/stat -f '%Su' /dev/console)"; CONSOLE_UID="$(/usr/bin/id -u "$CONSOLE_USER")"
USER_HOME="$(/usr/bin/dscl . -read "/Users/$CONSOLE_USER" NFSHomeDirectory | /usr/bin/awk '{print $2}')"; AGENT="$USER_HOME/Library/LaunchAgents/com.community.low-power-automation.menu.plist"
/bin/launchctl bootout system/com.community.low-power-automation >/dev/null 2>&1 || true
/bin/launchctl bootout "gui/$CONSOLE_UID/com.community.low-power-automation.menu" >/dev/null 2>&1 || true
if [[ -f "$STATE" ]]; then
  battery="$(/usr/bin/awk -F= '$1=="battery"{print $2}' "$STATE")"; ac="$(/usr/bin/awk -F= '$1=="ac"{print $2}' "$STATE")"
  [[ "$battery" =~ '^[0-2]$' ]] && /usr/bin/pmset -b lowpowermode "$battery"
  [[ "$ac" =~ '^[0-2]$' ]] && /usr/bin/pmset -c lowpowermode "$ac"
fi
/bin/rm -f /Library/LaunchDaemons/com.community.low-power-automation.plist "$AGENT" "$INSTALL_DIR/low-power-daemon" "$INSTALL_DIR/low-power-watcher.sh" "$INSTALL_DIR/configure.sh" "$INSTALL_DIR/uninstall.sh" "$STATE" "$SUPPORT_DIR/config"
/bin/rmdir "$INSTALL_DIR" "$SUPPORT_DIR" 2>/dev/null || true
[[ ! -L "/Applications/Low Power Automation.app" ]] || { print -u2 "Refusing to remove a symbolic link in Applications."; exit 3; }
/bin/rm -rf "/Applications/Low Power Automation.app"
