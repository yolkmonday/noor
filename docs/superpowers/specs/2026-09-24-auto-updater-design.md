# Noor Auto Updater — Design

Date: 2026-09-24
Status: approved in chat, pending spec review

## Goal

Users on a Sparkle-enabled Noor build get new versions without visiting GitHub or
running `brew upgrade`: Noor checks once a day, shows what changed, and installs +
relaunches when the user agrees.

Success criteria:
- A Noor build with this feature detects a newer release, downloads it, verifies it,
  replaces itself and relaunches — verified end-to-end before the first real release.
- Updates are rejected unless they carry a valid EdDSA signature from our key AND are
  signed with Developer ID team `K4TMF53N3L`.
- `release.sh` stays the single release entry point; no server or GitHub Pages.
- Homebrew cask keeps working and does not fight the in-app updater.

Non-goals: delta updates, beta/pre-release channels, silent install without consent,
Windows/Linux.

## Context

- Native Swift menu bar app (`LSUIElement`), macOS 14+, arm64, built with SwiftPM
  (`swift build -c release`). No Xcode build in the release path.
- `release.sh` assembles the bundle by hand: copies `build/Noor.app` (gitignored
  template), drops in the release binary, stamps `$VERSION` into Info.plist, signs with
  Developer ID + hardened runtime, builds DMG + ZIP, notarizes and staples.
- Releases: GitHub Releases on public `yolkmonday/noor` (DMG + ZIP) and tap
  `yolkmonday/homebrew-noor` (cask uses the ZIP).

## Design

### 1. Dependency and bundle

- `Package.swift`: add `https://github.com/sparkle-project/Sparkle` (from `2.x`),
  product `Sparkle`, to the `Noor` target.
- `release.sh`, after copying the binary:
  - Copy `.build/release/Sparkle.framework` (the SwiftPM binary artifact) into
    `dist/Noor.app/Contents/Frameworks/`.
  - `install_name_tool -add_rpath @executable_path/../Frameworks` on the binary if the
    rpath is not already present.
- Signing order (inside-out, all `--options runtime --timestamp` with Developer ID):
  1. `Sparkle.framework/Versions/B/XPCServices/Installer.xpc`
  2. `Sparkle.framework/Versions/B/XPCServices/Downloader.xpc`
     (`--preserve-metadata=entitlements`)
  3. `Sparkle.framework/Versions/B/Autoupdate`
  4. `Sparkle.framework/Versions/B/Updater.app`
  5. `Sparkle.framework`
  6. `Noor.app` (with `Noor.entitlements`, as today)
  Then `codesign --verify --deep --strict` before notarizing (unchanged step).
- `run.sh` (debug) gets the same framework copy + rpath so the debug build launches.

### 2. App code

- New `Noor/Services/UpdaterService.swift`: owns one `SPUStandardUpdaterController`
  (`startingUpdater: true`), created at app launch. Exposes:
  - `checkForUpdates()` — user-initiated check; activates the app first
    (`NSApp.activate`) because Noor is an `LSUIElement` app and Sparkle's windows
    would otherwise open behind other apps.
  - `automaticallyChecksForUpdates` (get/set), `canCheckForUpdates` (observable, to
    disable the button while a check runs).
- `SettingsView`: new "Pembaruan" section with
  - button **"Periksa Pembaruan…"**
  - toggle **"Periksa pembaruan otomatis"** bound to
    `automaticallyChecksForUpdates`
  - current version text (`CFBundleShortVersionString`).
- Info.plist keys, stamped into `dist/Noor.app` by `release.sh` with PlistBuddy (same
  as `$VERSION` today — `build/Noor.app` is gitignored, so it cannot be the source of
  truth). `release.sh` holds the values:
  - `SUFeedURL` = `${FEED_URL:-https://github.com/yolkmonday/noor/releases/latest/download/appcast.xml}`
    (env override used by the local test)
  - `SUPublicEDKey` = public key from `generate_keys` (public, safe to commit)
  - `SUEnableAutomaticChecks` = `true`, `SUScheduledCheckInterval` = `86400`
  `Noor/Info.plist` gets the same keys for reference/consistency.
  - Automatic download/install stays off by default; Sparkle's own dialog offers the
    "automatically download and install" checkbox so the user opts in.

### 3. Keys and trust

- Run Sparkle's `generate_keys` once. The private key lives in the login Keychain;
  export a backup to `~/.apple-signing/sparkle_ed25519.key` (chmod 600). Never
  committed.
- Losing the private key means existing installs can no longer verify updates, so the
  backup is required, not optional.
- Sparkle verifies the EdDSA signature and that the new app's code signature matches
  the running app's team — two independent checks.

### 4. Feed and release flow

- `release.sh`, after notarizing and creating the ZIP (made with `ditto`, keeps the
  stapled ticket):
  - Run Sparkle's `generate_appcast` on a staging dir containing only the new ZIP,
    with `--download-url-prefix https://github.com/yolkmonday/noor/releases/download/v$VERSION/`.
    Output: `dist/appcast.xml` with one `<item>` (version, EdDSA signature, length,
    `minimumSystemVersion` 14.0).
  - Optional release notes: if `release-notes/$VERSION.md` exists, pass it so the
    Sparkle dialog shows it.
- Publishing (manual, as today): `gh release create v$VERSION dist/*.dmg dist/*.zip dist/appcast.xml`.
  `releases/latest/download/appcast.xml` then always resolves to the newest feed.
- Homebrew cask: add `auto_updates true`. `brew upgrade` then skips Noor unless
  `--greedy`, so Sparkle and brew don't both try to update it.

### 5. Error handling

Sparkle handles network failures, bad signatures and failed installs itself and shows
standard alerts for user-initiated checks. Background checks fail silently and retry at
the next interval. No custom error UI.

### 6. Testing

- **Local end-to-end before release:**
  1. Build a test v1.2.3 with `FEED_URL=http://localhost:8000/appcast.xml ./release.sh`
     (localhost is exempt from ATS; skip publishing).
  2. Build a signed + notarized v1.2.4 ZIP and `generate_appcast` for it into a local
     dir; serve with `python3 -m http.server 8000`.
  3. Launch 1.2.3 from `/Applications`, click "Periksa Pembaruan…" and confirm: update
     dialog appears → download → install → relaunch shows 1.2.4.
  4. Negative check: tamper the ZIP (or use a wrong EdDSA signature) and confirm
     Sparkle refuses it.
- `codesign --verify --deep --strict` and `spctl --assess` pass on the bundle with
  Sparkle embedded (already part of `release.sh`).
- Then release the real v1.2.3.

### 7. Rollout

- v1.2.2 users have no updater: they update to v1.2.3 once by hand (DMG or
  `brew upgrade --cask noor`). From v1.2.3 on, updates are automatic.
- The v1.2.3 release notes mention this.

## Files touched

- `Package.swift` — Sparkle dependency
- `Noor/Services/UpdaterService.swift` — new
- `Noor/Views/SettingsView.swift` — "Pembaruan" section
- app entry point (wherever services are created) — instantiate `UpdaterService`
- `Noor/Info.plist` — Sparkle keys (reference; bundle values stamped by `release.sh`)
- `release.sh`, `run.sh` — embed + sign Sparkle, generate appcast
- `yolkmonday/homebrew-noor` `Casks/noor.rb` — `auto_updates true`
