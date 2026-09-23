#!/bin/bash
# Build and run Noor app

set -e

cd "$(dirname "$0")"
source scripts/sparkle-bundle.sh

echo "Building..."
swift build

echo "Updating bundle..."
cp .build/debug/Noor build/Noor.app/Contents/MacOS/Noor
sparkle_embed build/Noor.app .build/debug
# Keep the debug bundle version in sync with Noor/Info.plist
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" Noor/Info.plist)
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" -c "Set :CFBundleVersion $VERSION" build/Noor.app/Contents/Info.plist
sparkle_stamp_plist build/Noor.app \
  "https://github.com/yolkmonday/noor/releases/latest/download/appcast.xml" "LBjgYuTgmzTSgbE0hJNg4qdwI+0lNblnGDyGdDBvo44="
cp Noor/Resources/cities.json build/Noor.app/Contents/Resources/ 2>/dev/null || true
# Azan sounds (AzanService looks them up by id, e.g. azan_makkah.mp3)
cp azan/*.mp3 build/Noor.app/Contents/Resources/
# Outfit fonts (Info.plist ATSApplicationFontsPath = ".")
cp Noor/Resources/Fonts/*.ttf build/Noor.app/Contents/Resources/

echo "Signing with entitlements..."
sparkle_sign build/Noor.app -
codesign --force --sign - --entitlements Noor.entitlements build/Noor.app

echo "Launching..."
pkill -f "Noor.app" 2>/dev/null || true
sleep 0.3
open build/Noor.app

echo "Done!"
