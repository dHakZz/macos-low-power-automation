#!/bin/zsh
set -euo pipefail

HELPER="/usr/local/libexec/low-power-automation/configure.sh"
if [[ ! -x "$HELPER" ]]; then
  /usr/bin/osascript -e 'display alert "Low Power Automation is not installed" message "Run the installer first." as warning'
  exit 1
fi

current="$(/usr/bin/awk -F= '$1=="threshold" {print $2}' /Library/Application\ Support/Low\ Power\ Automation/config 2>/dev/null || true)"
[[ "$current" =~ '^[0-9]{2}$' ]] || current=50

threshold="$(/usr/bin/osascript - "$current" <<'APPLESCRIPT'
on run argv
  set defaultThreshold to item 1 of argv
  repeat
    set response to display dialog "Choose the new battery percentage." default answer defaultThreshold buttons {"Cancel", "Save"} default button "Save" with title "Low Power Automation"
    set enteredValue to text returned of response
    try
      set thresholdValue to enteredValue as integer
      if thresholdValue ≥ 10 and thresholdValue ≤ 90 then return thresholdValue as text
    end try
    display alert "Enter a whole number from 10 through 90." as warning
    set defaultThreshold to enteredValue
  end repeat
end run
APPLESCRIPT
)" || exit 0

[[ "$threshold" =~ '^[0-9]{2}$' ]] && (( threshold >= 10 && threshold <= 90 )) || exit 1

/usr/bin/osascript - "$threshold" <<'APPLESCRIPT'
on run argv
  set thresholdValue to item 1 of argv
  try
    do shell script "/usr/local/libexec/low-power-automation/configure.sh " & quoted form of thresholdValue with administrator privileges
    display dialog "The threshold is now " & thresholdValue & "%." buttons {"Done"} default button "Done" with icon note
  on error errorMessage number errorNumber
    if errorNumber is not -128 then display alert "Update failed" message errorMessage as critical
  end try
end run
APPLESCRIPT
