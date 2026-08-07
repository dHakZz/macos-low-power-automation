#!/bin/zsh
set -euo pipefail

readonly CONFIG="/Library/Application Support/Low Power Automation/config"
readonly PMSET=/usr/bin/pmset
readonly LOGGER=/usr/bin/logger

threshold="$(/usr/bin/awk -F= '$1=="threshold" {print $2}' "$CONFIG" 2>/dev/null || true)"
if [[ ! "$threshold" =~ '^[0-9]{2}$' ]] || (( threshold < 10 || threshold > 90 )); then
  $LOGGER -t low-power-automation "Invalid or missing threshold configuration"
  exit 1
fi

battery_status="$($PMSET -g batt)"
percentage="$(printf '%s\n' "$battery_status" | /usr/bin/sed -nE 's/.*[[:space:]]([0-9]{1,3})%;.*/\1/p' | /usr/bin/head -n 1)"
if [[ ! "$percentage" =~ '^[0-9]{1,3}$' ]] || (( percentage < 0 || percentage > 100 )); then
  $LOGGER -t low-power-automation "Could not read a valid battery percentage"
  exit 1
fi

if printf '%s\n' "$battery_status" | /usr/bin/head -n 1 | /usr/bin/grep -q "Battery Power"; then
  (( percentage <= threshold )) && desired=1 || desired=0
  current="$($PMSET -g custom | /usr/bin/awk '/Battery Power:/{s=1;next} /^[^[:space:]]/{s=0} s && $1=="lowpowermode"{print $2;exit}')"
  if [[ "$current" != "$desired" ]]; then
    $PMSET -b lowpowermode "$desired"
    $LOGGER -t low-power-automation "Battery ${percentage}% (threshold ${threshold}%): set Low Power Mode to ${desired}"
  fi
else
  current="$($PMSET -g custom | /usr/bin/awk '/AC Power:/{s=1;next} /^[^[:space:]]/{s=0} s && $1=="lowpowermode"{print $2;exit}')"
  if [[ "$current" != "0" ]]; then
    $PMSET -c lowpowermode 0
    $LOGGER -t low-power-automation "Connected to power: disabled Low Power Mode"
  fi
fi
