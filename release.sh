#!/bin/bash
set -e

VERSION="1.2.2"
APP_NAME="Noor"
SIGN_IDENTITY="${SIGN_IDENTITY:-Developer ID Application: Ari Padrian (K4TMF53N3L)}"
# Notary credentials live in the keychain, created once with:
#   xcrun notarytool store-credentials notary --apple-id <id> --team-id K4TMF53N3L --password <app-specific>
NOTARY_PROFILE="${NOTARY_PROFILE:-notary}"

source "$(dirname "$0")/scripts/sparkle-bundle.sh"

echo "Building release..."
swift build -c release

echo "Creating app bundle..."
rm -rf dist
mkdir -p dist

# Copy app bundle
cp -r build/Noor.app dist/

# Copy release binary
cp .build/release/Noor dist/Noor.app/Contents/MacOS/Noor

# Embed Sparkle (auto updater)
sparkle_embed dist/Noor.app .build/release

# Stamp version into the bundle (build/Noor.app is gitignored, so it can drift)
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" -c "Set :CFBundleVersion $VERSION" dist/Noor.app/Contents/Info.plist

# Copy resources
cp Noor/Resources/cities.json dist/Noor.app/Contents/Resources/ 2>/dev/null || true

# Sign with Developer ID + hardened runtime (required for notarization).
# Nested Sparkle code first, then the app.
sparkle_sign dist/Noor.app "$SIGN_IDENTITY"
codesign --force --options runtime --timestamp \
  --sign "$SIGN_IDENTITY" --entitlements Noor.entitlements dist/Noor.app
codesign --verify --deep --strict dist/Noor.app

echo "Creating DMG installer..."
rm -f "dist/${APP_NAME}-${VERSION}.dmg"

# create-dmg may return non-zero even when the DMG was written; checked below
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
  --codesign "$SIGN_IDENTITY" \
  "dist/${APP_NAME}-${VERSION}.dmg" \
  "dist/Noor.app"
CREATE_DMG_EXIT=$?
set -e

if [ $CREATE_DMG_EXIT -ne 0 ] && [ ! -f "dist/${APP_NAME}-${VERSION}.dmg" ]; then
  echo "Error: Failed to create DMG"
  exit 1
fi

echo "Notarizing DMG..."
xcrun notarytool submit "dist/${APP_NAME}-${VERSION}.dmg" --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "dist/${APP_NAME}-${VERSION}.dmg"
# The DMG ticket covers the app inside it; staple the app too so the ZIP works offline
xcrun stapler staple dist/Noor.app
spctl --assess --type open --context context:primary-signature -v "dist/${APP_NAME}-${VERSION}.dmg"
spctl --assess --type execute -v dist/Noor.app

echo "Creating ZIP..."
cd dist
# ditto keeps extended attributes (stapled ticket) that plain zip drops
ditto -c -k --keepParent Noor.app "${APP_NAME}-${VERSION}.zip"
cd ..

echo "Calculating SHA256..."
shasum -a 256 dist/*.dmg dist/*.zip

echo "Done! Files in dist/"
ls -la dist/
