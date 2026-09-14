#!/bin/zsh
set -euo pipefail
SOURCE="${0:A:h}"
[[ -x "$SOURCE/payload/low-power-daemon" && -d "$SOURCE/app/Low Power Automation.app" ]] || { /usr/bin/osascript -e 'display alert "Installer is incomplete" message "Keep every included folder beside this installer." as critical'; exit 1; }

settings="$(/usr/bin/osascript <<'APPLESCRIPT'
set onValue to 40
repeat
  set answerOn to text returned of (display dialog "Turn Low Power Mode on when the battery reaches:" default answer (onValue as text) buttons {"Cancel", "Next"} default button "Next" with title "Low Power Automation v2")
  try
    set onValue to answerOn as integer
    if onValue ≥ 10 and onValue ≤ 90 then exit repeat
  end try
  display alert "Enter a whole number from 10 through 90." as warning
end repeat
set offValue to onValue + 10
repeat
  set answerOff to text returned of (display dialog "Turn Low Power Mode off after the battery rises to:\n\nKeeping this higher than the on level prevents rapid switching." default answer (offValue as text) buttons {"Cancel", "Next"} default button "Next" with title "Low Power Automation v2")
  try
    set offValue to answerOff as integer
    if offValue > onValue and offValue ≤ 95 then exit repeat
  end try
  display alert "Enter a whole number higher than " & onValue & " and no higher than 95." as warning
end repeat
set acChoice to choose from list {"Automatic mode (recommended)", "Low Power Mode", "Leave the current setting unchanged"} with title "When connected to power" with prompt "Choose the energy mode to use while plugged in:" default items {"Automatic mode (recommended)"}
if acChoice is false then error number -128
if item 1 of acChoice starts with "Automatic" then
  set acValue to "automatic"
else if item 1 of acChoice is "Low Power Mode" then
  set acValue to "lowPower"
else
  set acValue to "unchanged"
end if
return (onValue as text) & "|" & (offValue as text) & "|" & acValue
APPLESCRIPT
)" || exit 0
IFS='|' read -r ON OFF PLUGGED <<< "$settings"
[[ "$ON" =~ '^[0-9]{2}$' && "$OFF" =~ '^[0-9]{2}$' ]] && (( ON >= 10 && OFF > ON && OFF <= 95 )) || exit 2

STAGE="$(/usr/bin/mktemp -d /private/tmp/low-power-automation-v2.XXXXXX)"
cleanup() {
  [[ "$STAGE" == /private/tmp/low-power-automation-v2.* && -d "$STAGE" ]] || return 0
  /bin/rm -rf "$STAGE"
}
trap cleanup EXIT
/usr/bin/ditto "$SOURCE/payload" "$STAGE/payload"
/usr/bin/ditto "$SOURCE/app" "$STAGE/app"

/usr/bin/osascript - "$STAGE" "$ON" "$OFF" "$PLUGGED" <<'APPLESCRIPT'
on run argv
  set commandText to quoted form of ((item 1 of argv) & "/payload/install-root.sh") & " " & quoted form of (item 1 of argv) & " " & quoted form of (item 2 of argv) & " " & quoted form of (item 3 of argv) & " " & quoted form of (item 4 of argv)
  try
    do shell script commandText with administrator privileges
    display dialog "Installation complete. Look for the battery-and-arrows icon in the menu bar." buttons {"Done"} default button "Done" with icon note
  on error messageText number errorNumber
    if errorNumber is not -128 then display alert "Installation failed" message messageText as critical
  end try
end run
APPLESCRIPT
