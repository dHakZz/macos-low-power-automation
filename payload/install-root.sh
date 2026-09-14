#!/bin/zsh
set -euo pipefail
(( EUID == 0 )) || { print -u2 "Administrator privileges are required."; exit 1; }

SOURCE="${1:A}"; ON="$2"; OFF="$3"; PLUGGED="$4"
INSTALL_DIR="/usr/local/libexec/low-power-automation"
SUPPORT_DIR="/Library/Application Support/Low Power Automation"
STATE="$SUPPORT_DIR/original-settings"; CONFIG="$SUPPORT_DIR/config"
DAEMON_PLIST="/Library/LaunchDaemons/com.community.low-power-automation.plist"
CONSOLE_USER="$(/usr/bin/stat -f '%Su' /dev/console)"; CONSOLE_UID="$(/usr/bin/id -u "$CONSOLE_USER")"
USER_HOME="$(/usr/bin/dscl . -read "/Users/$CONSOLE_USER" NFSHomeDirectory | /usr/bin/awk '{print $2}')"
AGENT="$USER_HOME/Library/LaunchAgents/com.community.low-power-automation.menu.plist"

[[ "$ON" =~ '^[0-9]{2}$' && "$OFF" =~ '^[0-9]{2}$' ]] && (( ON >= 10 && ON <= 90 && OFF > ON && OFF <= 95 )) || { print -u2 "Invalid thresholds."; exit 2; }
[[ "$PLUGGED" == automatic || "$PLUGGED" == lowPower || "$PLUGGED" == unchanged ]] || exit 2
[[ "$CONSOLE_USER" != root && "$CONSOLE_USER" != loginwindow && -d "$SOURCE/payload" && -d "$SOURCE/app/Low Power Automation.app" ]] || { print -u2 "Installer payload is incomplete."; exit 2; }

/bin/mkdir -p "$INSTALL_DIR" "$SUPPORT_DIR" "$USER_HOME/Library/LaunchAgents"
if [[ ! -f "$STATE" ]]; then
  if [[ -f /usr/local/libexec/justin-low-power/original-settings ]]; then
    /usr/bin/install -o root -g wheel -m 600 /usr/local/libexec/justin-low-power/original-settings "$STATE"
  else
    battery="$(/usr/bin/pmset -g custom | /usr/bin/awk '/Battery Power:/{s=1;next} /^[^[:space:]]/{s=0} s&&$1=="lowpowermode"{print $2;exit}')"
    ac="$(/usr/bin/pmset -g custom | /usr/bin/awk '/AC Power:/{s=1;next} /^[^[:space:]]/{s=0} s&&$1=="lowpowermode"{print $2;exit}')"
    /usr/bin/printf 'battery=%s\nac=%s\n' "${battery:-0}" "${ac:-0}" > "$STATE"
  fi
fi

# Stop v1 and v2 components before replacing files.
/bin/launchctl bootout system/com.community.low-power-automation >/dev/null 2>&1 || true
/bin/launchctl bootout "gui/$CONSOLE_UID/com.community.low-power-automation.menu" >/dev/null 2>&1 || true
/bin/launchctl bootout "gui/$CONSOLE_UID/com.justin.low-power-watcher" >/dev/null 2>&1 || true

/usr/bin/install -o root -g wheel -m 755 "$SOURCE/payload/low-power-daemon" "$INSTALL_DIR/low-power-daemon"
/usr/bin/install -o root -g wheel -m 755 "$SOURCE/payload/configure-root.sh" "$INSTALL_DIR/configure.sh"
/usr/bin/install -o root -g wheel -m 755 "$SOURCE/payload/uninstall-root.sh" "$INSTALL_DIR/uninstall.sh"
/usr/bin/install -o root -g wheel -m 644 "$SOURCE/payload/com.community.low-power-automation.plist" "$DAEMON_PLIST"
[[ ! -L "/Applications/Low Power Automation.app" ]] || { print -u2 "Refusing to replace a symbolic link in Applications."; exit 3; }
/bin/rm -rf "/Applications/Low Power Automation.app"
/usr/bin/ditto "$SOURCE/app/Low Power Automation.app" "/Applications/Low Power Automation.app"
/usr/sbin/chown -R root:wheel "/Applications/Low Power Automation.app"
/usr/bin/install -o "$CONSOLE_USER" -g staff -m 644 "$SOURCE/payload/com.community.low-power-automation.menu.plist" "$AGENT"
/usr/bin/printf 'enabled=true\nonThreshold=%s\noffThreshold=%s\npluggedMode=%s\n' "$ON" "$OFF" "$PLUGGED" > "$CONFIG"
/usr/sbin/chown -R root:wheel "$INSTALL_DIR" "$SUPPORT_DIR"; /bin/chmod 600 "$STATE"; /bin/chmod 644 "$CONFIG"
/bin/rm -f "$INSTALL_DIR/low-power-watcher.sh"

# Remove the original prototype's narrowly scoped files after migration.
/bin/rm -f "$USER_HOME/Library/LaunchAgents/com.justin.low-power-watcher.plist" /etc/sudoers.d/justin-low-power-watcher
/bin/rm -f /usr/local/libexec/justin-low-power/low-power-watcher.sh /usr/local/libexec/justin-low-power/run-low-power-watcher.sh /usr/local/libexec/justin-low-power/uninstall.sh /usr/local/libexec/justin-low-power/original-settings
/bin/rmdir /usr/local/libexec/justin-low-power 2>/dev/null || true

/bin/launchctl bootstrap system "$DAEMON_PLIST"
/bin/launchctl bootstrap "gui/$CONSOLE_UID" "$AGENT"
/bin/launchctl kickstart -k system/com.community.low-power-automation
/bin/launchctl kickstart -k "gui/$CONSOLE_UID/com.community.low-power-automation.menu"
