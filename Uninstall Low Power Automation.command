#!/bin/zsh
set -euo pipefail

if [[ ! -x /usr/local/libexec/low-power-automation/uninstall.sh ]]; then
  /usr/bin/osascript -e 'display alert "Nothing to uninstall" message "Low Power Automation is not installed on this Mac."'
  exit 0
fi

/usr/bin/osascript <<'APPLESCRIPT'
try
  do shell script "/usr/local/libexec/low-power-automation/uninstall.sh" with administrator privileges
  display dialog "Low Power Automation was removed. Previous Low Power Mode settings were restored when available." buttons {"Done"} default button "Done" with icon note
on error errorMessage number errorNumber
  if errorNumber is not -128 then display alert "Uninstall failed" message errorMessage as critical
end try
APPLESCRIPT
