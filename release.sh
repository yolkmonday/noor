#!/bin/bash
set -e

VERSION="1.1.0"
APP_NAME="Noor"

echo "Building release..."
swift build -c release

echo "Creating app bundle..."
rm -rf dist
mkdir -p dist

# Copy app bundle
cp -r build/Noor.app dist/

# Copy release binary
cp .build/release/Noor dist/Noor.app/Contents/MacOS/Noor

# Copy resources
cp Noor/Resources/cities.json dist/Noor.app/Contents/Resources/ 2>/dev/null || true

# Sign
codesign --force --sign - --entitlements Noor.entitlements dist/Noor.app

echo "Creating DMG installer..."
rm -f "dist/${APP_NAME}-${VERSION}.dmg"

# create-dmg returns exit code 2 if it can't code-sign the DMG (expected without developer cert)
set +e
create-dmg \
  --volname "$APP_NAME" \
  --volicon "build/Noor.app/Contents/Resources/AppIcon.icns" \
  --background "installer/dmg-background.png" \
  --window-pos 200 120 \
  --window-size 660 400 \
  --icon-size 100 \
  --icon "Noor.app" 170 230 \
  --app-drop-link 490 230 \
  --hide-extension "Noor.app" \
  --no-internet-enable \
  "dist/${APP_NAME}-${VERSION}.dmg" \
  "dist/Noor.app"
CREATE_DMG_EXIT=$?
set -e

if [ $CREATE_DMG_EXIT -ne 0 ] && [ ! -f "dist/${APP_NAME}-${VERSION}.dmg" ]; then
  echo "Error: Failed to create DMG"
  exit 1
fi

echo "Creating ZIP..."
cd dist
zip -r "${APP_NAME}-${VERSION}.zip" Noor.app
cd ..

echo "Calculating SHA256..."
shasum -a 256 dist/*.dmg dist/*.zip

echo "Done! Files in dist/"
ls -la dist/
