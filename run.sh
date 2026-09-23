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
cp Noor/Resources/cities.json build/Noor.app/Contents/Resources/ 2>/dev/null || true

echo "Signing with entitlements..."
sparkle_sign build/Noor.app -
codesign --force --sign - --entitlements Noor.entitlements build/Noor.app

echo "Launching..."
pkill -f "Noor.app" 2>/dev/null || true
sleep 0.3
open build/Noor.app

echo "Done!"
