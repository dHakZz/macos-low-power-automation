#!/bin/zsh
set -euo pipefail
(( EUID == 0 )) || { print -u2 "Administrator privileges are required."; exit 1; }

KEY="${1:-}"; VALUE="${2:-}"
CONFIG="/Library/Application Support/Low Power Automation/config"
[[ -f "$CONFIG" ]] || { print -u2 "Low Power Automation is not installed."; exit 1; }

case "$KEY" in
  enabled) [[ "$VALUE" == true || "$VALUE" == false ]] || exit 2 ;;
  onThreshold) [[ "$VALUE" =~ '^[0-9]{2}$' ]] && (( VALUE >= 10 && VALUE <= 90 )) || exit 2 ;;
  offThreshold) [[ "$VALUE" =~ '^[0-9]{2}$' ]] && (( VALUE >= 11 && VALUE <= 95 )) || exit 2 ;;
  pluggedMode) [[ "$VALUE" == automatic || "$VALUE" == lowPower || "$VALUE" == unchanged ]] || exit 2 ;;
  *) exit 2 ;;
esac

on="$(/usr/bin/awk -F= '$1=="onThreshold"{print $2}' "$CONFIG")"
off="$(/usr/bin/awk -F= '$1=="offThreshold"{print $2}' "$CONFIG")"
[[ "$KEY" == onThreshold ]] && on="$VALUE"
[[ "$KEY" == offThreshold ]] && off="$VALUE"
(( on < off )) || { print -u2 "The off threshold must be higher than the on threshold."; exit 2; }

TEMP="$(/usr/bin/mktemp "/Library/Application Support/Low Power Automation/config.XXXXXX")"
/usr/bin/awk -F= -v key="$KEY" -v value="$VALUE" 'BEGIN{found=0} $1==key{print key "=" value; found=1; next} {print} END{if(!found) print key "=" value}' "$CONFIG" > "$TEMP"
/usr/sbin/chown root:wheel "$TEMP"; /bin/chmod 644 "$TEMP"; /bin/mv -f "$TEMP" "$CONFIG"
/bin/launchctl kickstart -k system/com.community.low-power-automation
