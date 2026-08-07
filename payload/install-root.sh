#!/bin/zsh
set -euo pipefail
(( EUID == 0 )) || { print -u2 "Administrator privileges are required."; exit 1; }

SOURCE_DIR="${1:A}"
THRESHOLD="$2"
INSTALL_DIR="/usr/local/libexec/low-power-automation"
SUPPORT_DIR="/Library/Application Support/Low Power Automation"
STATE="$SUPPORT_DIR/original-settings"
CONFIG="$SUPPORT_DIR/config"
PLIST="/Library/LaunchDaemons/com.community.low-power-automation.plist"

[[ "$THRESHOLD" =~ '^[0-9]{2}$' ]] && (( THRESHOLD >= 10 && THRESHOLD <= 90 )) || { print -u2 "Threshold must be 10–90."; exit 1; }
[[ -d "$SOURCE_DIR/payload" ]] || { print -u2 "Installer payload is missing."; exit 1; }

/bin/mkdir -p "$INSTALL_DIR" "$SUPPORT_DIR"
if [[ ! -f "$STATE" ]]; then
  battery_mode="$(/usr/bin/pmset -g custom | /usr/bin/awk '/Battery Power:/{s=1;next} /^[^[:space:]]/{s=0} s && $1=="lowpowermode"{print $2;exit}')"
  ac_mode="$(/usr/bin/pmset -g custom | /usr/bin/awk '/AC Power:/{s=1;next} /^[^[:space:]]/{s=0} s && $1=="lowpowermode"{print $2;exit}')"
  /usr/bin/printf 'battery=%s\nac=%s\n' "${battery_mode:-0}" "${ac_mode:-0}" > "$STATE"
fi

/bin/launchctl bootout system/com.community.low-power-automation >/dev/null 2>&1 || true
/usr/bin/install -o root -g wheel -m 755 "$SOURCE_DIR/payload/low-power-watcher.sh" "$INSTALL_DIR/low-power-watcher.sh"
/usr/bin/install -o root -g wheel -m 755 "$SOURCE_DIR/payload/configure-root.sh" "$INSTALL_DIR/configure.sh"
/usr/bin/install -o root -g wheel -m 755 "$SOURCE_DIR/payload/uninstall-root.sh" "$INSTALL_DIR/uninstall.sh"
/usr/bin/install -o root -g wheel -m 644 "$SOURCE_DIR/payload/com.community.low-power-automation.plist" "$PLIST"
/usr/bin/printf 'threshold=%s\n' "$THRESHOLD" > "$CONFIG"
/usr/sbin/chown -R root:wheel "$INSTALL_DIR" "$SUPPORT_DIR"
/bin/chmod 600 "$STATE"
/bin/chmod 644 "$CONFIG"
/bin/launchctl bootstrap system "$PLIST"
/bin/launchctl kickstart -k system/com.community.low-power-automation
