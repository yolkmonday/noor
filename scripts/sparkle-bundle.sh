#!/bin/bash
# Shared Sparkle helpers for release.sh and run.sh. Source, don't execute.

SPARKLE_BIN=".build/artifacts/sparkle/Sparkle/bin"

# Copy Sparkle.framework into the bundle and make the binary find it there.
sparkle_embed() {
  local app="$1" build_dir="$2"
  local bin="$app/Contents/MacOS/Noor"
  mkdir -p "$app/Contents/Frameworks"
  rm -rf "$app/Contents/Frameworks/Sparkle.framework"
  # -R keeps the framework's internal symlinks (Versions/Current etc.)
  cp -R "$build_dir/Sparkle.framework" "$app/Contents/Frameworks/"
  if ! otool -l "$bin" | grep -q "@executable_path/../Frameworks"; then
    install_name_tool -add_rpath "@executable_path/../Frameworks" "$bin"
  fi
}

# Sign Sparkle's nested code inside-out. Must run before signing the app.
sparkle_sign() {
  local app="$1" identity="$2"
  local fw="$app/Contents/Frameworks/Sparkle.framework"
  local opts=(--force --options runtime --sign "$identity")
  # Ad-hoc debug signatures can't carry a secure timestamp
  [ "$identity" != "-" ] && opts+=(--timestamp)
  codesign "${opts[@]}" "$fw/Versions/B/XPCServices/Installer.xpc"
  codesign "${opts[@]}" --preserve-metadata=entitlements "$fw/Versions/B/XPCServices/Downloader.xpc"
  codesign "${opts[@]}" "$fw/Versions/B/Autoupdate"
  codesign "${opts[@]}" "$fw/Versions/B/Updater.app"
  codesign "${opts[@]}" "$fw"
}

# Write Sparkle's Info.plist keys into the bundle (build/Noor.app is gitignored,
# so the bundle template can't be the source of truth).
sparkle_stamp_plist() {
  local app="$1" feed_url="$2" public_key="$3"
  local plist="$app/Contents/Info.plist"
  local pb=/usr/libexec/PlistBuddy
  for key in SUFeedURL SUPublicEDKey SUEnableAutomaticChecks SUScheduledCheckInterval; do
    $pb -c "Delete :$key" "$plist" 2>/dev/null || true
  done
  $pb -c "Add :SUFeedURL string $feed_url" \
      -c "Add :SUPublicEDKey string $public_key" \
      -c "Add :SUEnableAutomaticChecks bool true" \
      -c "Add :SUScheduledCheckInterval integer 86400" \
      "$plist"
}
