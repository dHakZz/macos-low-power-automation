#!/bin/zsh
set -euo pipefail
(( EUID == 0 )) || { print -u2 "Administrator privileges are required."; exit 1; }
THRESHOLD="${1:-}"
[[ "$THRESHOLD" =~ '^[0-9]{2}$' ]] && (( THRESHOLD >= 10 && THRESHOLD <= 90 )) || { print -u2 "Threshold must be 10–90."; exit 1; }
/usr/bin/printf 'threshold=%s\n' "$THRESHOLD" > "/Library/Application Support/Low Power Automation/config"
/usr/sbin/chown root:wheel "/Library/Application Support/Low Power Automation/config"
/bin/chmod 644 "/Library/Application Support/Low Power Automation/config"
/bin/launchctl kickstart -k system/com.community.low-power-automation
