#!/bin/zsh
set -euo pipefail
ROOT="${0:A:h:h}"
BUILD="$ROOT/build"
CACHE="$BUILD/module-cache"
SDK="$(/usr/bin/xcrun --show-sdk-path)"
/bin/mkdir -p "$CACHE" "$ROOT/app/Low Power Automation.app/Contents/MacOS"
for arch in arm64 x86_64; do
  /usr/bin/xcrun swiftc -module-cache-path "$CACHE" -parse-as-library -target "$arch-apple-macos13.0" -sdk "$SDK" "$ROOT/src/LowPowerDaemon.swift" -o "$BUILD/low-power-daemon-$arch" -framework IOKit
  /usr/bin/xcrun swiftc -module-cache-path "$CACHE" -target "$arch-apple-macos13.0" -sdk "$SDK" "$ROOT/src/MenuBarApp.swift" -o "$BUILD/menu-$arch" -framework AppKit
done
/usr/bin/lipo -create "$BUILD/low-power-daemon-arm64" "$BUILD/low-power-daemon-x86_64" -output "$ROOT/payload/low-power-daemon"
/usr/bin/lipo -create "$BUILD/menu-arm64" "$BUILD/menu-x86_64" -output "$ROOT/app/Low Power Automation.app/Contents/MacOS/Low Power Automation"
if ! /usr/bin/cmp -s "$ROOT/app/Info.plist" "$ROOT/app/Low Power Automation.app/Contents/Info.plist"; then
  /usr/bin/ditto "$ROOT/app/Info.plist" "$ROOT/app/Low Power Automation.app/Contents/Info.plist"
fi
/usr/bin/xattr -cr "$ROOT/app/Low Power Automation.app"
/usr/bin/codesign --force --sign - "$ROOT/payload/low-power-daemon"
/usr/bin/codesign --force --deep --sign - "$ROOT/app/Low Power Automation.app"
