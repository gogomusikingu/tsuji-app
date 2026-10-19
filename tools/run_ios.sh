#!/bin/sh
# Build the iPhone app and launch it in the iOS Simulator (needs Xcode).
# To tap through the app, open ios/Tsuji.xcodeproj in Xcode and press Run instead.
set -e
cd "$(dirname "$0")/.."
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
DEV=$(xcrun simctl list devices available | grep -m1 -E "iPhone" | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')
[ -n "$DEV" ] || { echo "No iPhone simulator found. Install one from Xcode > Settings > Components."; exit 1; }
xcodebuild -project ios/Tsuji.xcodeproj -scheme Tsuji -destination "platform=iOS Simulator,id=$DEV" \
    -derivedDataPath .build/ios -quiet build
xcrun simctl boot "$DEV" 2>/dev/null || true
SIM_APP=$(find /Applications/Xcode.app/Contents -maxdepth 6 -iname "Simulator.app" 2>/dev/null | head -1)
if [ -n "$SIM_APP" ]; then open "$SIM_APP"; else echo "Simulator window app not found; the app still runs headless."; fi
xcrun simctl bootstatus "$DEV" -b >/dev/null
xcrun simctl install "$DEV" .build/ios/Build/Products/Debug-iphonesimulator/Tsuji.app
xcrun simctl launch "$DEV" com.gogomusikingu.tsuji
