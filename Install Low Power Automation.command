#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"

if [[ ! -f "$SCRIPT_DIR/payload/install-root.sh" ]]; then
  /usr/bin/osascript -e 'display alert "Installer is incomplete" message "Keep the payload folder beside this installer and try again." as critical'
  exit 1
fi

threshold="$(/usr/bin/osascript <<'APPLESCRIPT'
set defaultThreshold to "50"
repeat
  set response to display dialog "Choose the battery percentage at which Low Power Mode should turn on." default answer defaultThreshold buttons {"Cancel", "Install"} default button "Install" with title "Low Power Automation"
  set enteredValue to text returned of response
  try
    set thresholdValue to enteredValue as integer
    if thresholdValue ≥ 10 and thresholdValue ≤ 90 then return thresholdValue as text
  end try
  display alert "Enter a whole number from 10 through 90." as warning
  set defaultThreshold to enteredValue
end repeat
APPLESCRIPT
)" || exit 0

[[ "$threshold" =~ '^[0-9]{2}$' ]] && (( threshold >= 10 && threshold <= 90 )) || exit 1

STAGING_DIR="$(/usr/bin/mktemp -d /private/tmp/low-power-automation.XXXXXX)"
cleanup() {
  [[ "$STAGING_DIR" == /private/tmp/low-power-automation.* && -d "$STAGING_DIR" ]] || return 0
  /bin/rm -f "$STAGING_DIR/payload/low-power-watcher.sh" "$STAGING_DIR/payload/com.community.low-power-automation.plist" "$STAGING_DIR/payload/install-root.sh" "$STAGING_DIR/payload/uninstall-root.sh" "$STAGING_DIR/payload/configure-root.sh"
  /bin/rmdir "$STAGING_DIR/payload" "$STAGING_DIR" 2>/dev/null || true
}
trap cleanup EXIT
/usr/bin/ditto "$SCRIPT_DIR/payload" "$STAGING_DIR/payload"

/usr/bin/osascript - "$STAGING_DIR" "$threshold" <<'APPLESCRIPT'
on run argv
  set sourceFolder to item 1 of argv
  set thresholdValue to item 2 of argv
  set shellCommand to quoted form of (sourceFolder & "/payload/install-root.sh") & " " & quoted form of sourceFolder & " " & quoted form of thresholdValue
  try
    do shell script shellCommand with administrator privileges
    display dialog "Low Power Automation is installed.\n\nLow Power Mode will turn on at " & thresholdValue & "% or below while on battery, and turn off above that level or when connected to power." buttons {"Done"} default button "Done" with icon note
  on error errorMessage number errorNumber
    if errorNumber is -128 then
      display alert "Installation cancelled" message "No additional changes were made."
    else
      display alert "Installation failed" message errorMessage as critical
    end if
  end try
end run
APPLESCRIPT
