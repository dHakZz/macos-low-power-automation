#!/bin/zsh
set -euo pipefail
if [[ ! -x /usr/local/libexec/low-power-automation/uninstall.sh ]]; then
  /usr/bin/osascript -e 'display alert "Low Power Automation is not installed."'; exit 0
fi
/usr/bin/osascript <<'APPLESCRIPT'
try
  do shell script "/usr/local/libexec/low-power-automation/uninstall.sh" with administrator privileges
  display dialog "Low Power Automation was removed and the original energy settings were restored when available." buttons {"Done"} default button "Done" with icon note
on error messageText number errorNumber
  if errorNumber is not -128 then display alert "Uninstall failed" message messageText as critical
end try
APPLESCRIPT
