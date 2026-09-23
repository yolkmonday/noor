# Noor Auto Updater Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Noor checks for, downloads, verifies and installs new versions by itself via Sparkle 2, released through the existing `release.sh` + GitHub Releases flow.

**Architecture:** Sparkle 2 comes in as a SwiftPM binary dependency. `release.sh`/`run.sh` embed `Sparkle.framework` into the hand-built bundle, sign it inside-out, and stamp the Sparkle Info.plist keys (via one shared helper script). A small `UpdaterService` singleton owns the `SPUStandardUpdaterController`; Settings gets a "Pembaruan" section. `release.sh` emits a one-item `appcast.xml` that is uploaded as a release asset, so `releases/latest/download/appcast.xml` is the feed.

**Tech Stack:** Swift 5.9, SwiftUI `MenuBarExtra`, SwiftPM, Sparkle 2.10.0, bash, `codesign`/`notarytool`, `gh`.

**Spec:** `docs/superpowers/specs/2026-09-24-auto-updater-design.md`

## Global Constraints

- macOS 14+, arm64 only (`LSMinimumSystemVersion` 14.0, cask `depends_on arch: :arm64`).
- Sparkle `from: "2.10.0"` (latest release as of 2026-09-24).
- Signing identity: `Developer ID Application: Ari Padrian (K4TMF53N3L)`; every Mach-O and bundle signed with `--options runtime --timestamp`.
- Notary keychain profile: `notary` (already stored).
- Feed URL: `https://github.com/yolkmonday/noor/releases/latest/download/appcast.xml`, overridable with env `FEED_URL`.
- `SUEnableAutomaticChecks` = true, `SUScheduledCheckInterval` = 86400, automatic install OFF by default.
- EdDSA private key: login Keychain + backup at `~/.apple-signing/sparkle_ed25519.key` (chmod 600). Never in the repo.
- UI copy is Bahasa Indonesia: section "Pembaruan", button "Periksa Pembaruan…", toggle "Periksa pembaruan otomatis".
- Commit messages: English, lowercase, concise, no Co-Authored-By.
- No test target exists in this repo (SwiftPM executable only). Verification is scripted shell checks + a local end-to-end update run; do not add a test target for this feature.

## Review Focus

1. **Feed missing/unreachable** (offline, or a release published without `appcast.xml`): a user-initiated check shows Sparkle's error alert; background checks stay silent; the app doesn't crash. Pinned in Task 2 Step 7.
2. **Update window hidden behind other apps**: Noor is `LSUIElement`, so Sparkle's windows must come to the front when the user clicks "Periksa Pembaruan…". Pinned in Task 2 Step 7.
3. **Panel dismissed mid-check**: the `MenuBarExtra` panel closes on focus loss; the updater must live in the app (singleton), not the view, so the check continues. Pinned in Task 2 Step 7.
4. **Tampered or wrongly signed update**: Sparkle must refuse to install it. Pinned in Task 4 Step 6.
5. **App run from a read-only location** (mounted DMG / App Translocation): installing must fail with an alert, not corrupt anything. Pinned in Task 4 Step 7.

---

## File Structure

| File | Responsibility |
|---|---|
| `Package.swift` | add Sparkle dependency |
| `scripts/sparkle-bundle.sh` (new) | shared helpers: embed Sparkle into a bundle, stamp Sparkle plist keys, sign Sparkle inside-out |
| `release.sh` | call helpers; generate `appcast.xml` |
| `run.sh` | call helpers so the debug build launches with Sparkle |
| `Noor/Services/UpdaterService.swift` (new) | owns `SPUStandardUpdaterController`; check, auto-check flag, version |
| `Noor/NoorApp.swift` | start `UpdaterService` at launch |
| `Noor/Views/SettingsView.swift` | "Pembaruan" section; real version in "Tentang" |
| `Noor/Info.plist` | Sparkle keys (reference only) |
| `yolkmonday/homebrew-noor` `Casks/noor.rb` | `auto_updates true`, bump version |

---

### Task 1: Embed and sign Sparkle in the bundle

**Files:**
- Modify: `Package.swift`
- Create: `scripts/sparkle-bundle.sh`
- Modify: `release.sh` (after "Copy release binary", and the "# Sign" block)
- Modify: `run.sh` (after binary copy, and the signing line)

**Interfaces:**
- Produces: `scripts/sparkle-bundle.sh` defining bash functions
  - `sparkle_embed <app_path> <build_dir>` — copies `<build_dir>/Sparkle.framework` into `<app_path>/Contents/Frameworks/` and ensures rpath `@executable_path/../Frameworks` on `<app_path>/Contents/MacOS/Noor`
  - `sparkle_sign <app_path> <identity>` — signs Sparkle's nested code inside-out (identity `-` allowed for ad-hoc debug builds)
  - `sparkle_stamp_plist <app_path> <feed_url> <public_ed_key>` — defined in Task 2 (same file)
  - `SPARKLE_BIN` — path to Sparkle CLI tools (`.build/artifacts/sparkle/Sparkle/bin`)

- [ ] **Step 1: Add the dependency**

`Package.swift`:

```swift
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Noor",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(path: "adhan-swift"),
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.10.0")
    ],
    targets: [
        .executableTarget(
            name: "Noor",
            dependencies: [
                .product(name: "Adhan", package: "adhan-swift"),
                .product(name: "Sparkle", package: "Sparkle")
            ],
            path: "Noor",
            exclude: ["Info.plist", "Noor.entitlements", "Adhan", "Resources"]
        )
    ]
)
```

- [ ] **Step 2: Build and locate the artifacts**

Run: `swift build -c release && ls -d .build/release/Sparkle.framework .build/artifacts/sparkle/Sparkle/bin/generate_appcast && otool -l .build/release/Noor | grep -A2 LC_RPATH`
Expected: both paths print; rpath list shows `@loader_path` (no `@executable_path/../Frameworks` yet). If the framework lives elsewhere, `find .build -name Sparkle.framework -maxdepth 4` and use that path in Step 3.

- [ ] **Step 3: Write the helper script**

`scripts/sparkle-bundle.sh`:

```bash
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
```

- [ ] **Step 4: Wire it into `release.sh`**

Near the top, after `NOTARY_PROFILE=...`:

```bash
source "$(dirname "$0")/scripts/sparkle-bundle.sh"
```

After the `cp .build/release/Noor dist/Noor.app/Contents/MacOS/Noor` line:

```bash
# Embed Sparkle (auto updater)
sparkle_embed dist/Noor.app .build/release
```

Replace the `# Sign with Developer ID ...` block with:

```bash
# Sign with Developer ID + hardened runtime (required for notarization).
# Nested Sparkle code first, then the app.
sparkle_sign dist/Noor.app "$SIGN_IDENTITY"
codesign --force --options runtime --timestamp \
  --sign "$SIGN_IDENTITY" --entitlements Noor.entitlements dist/Noor.app
codesign --verify --deep --strict dist/Noor.app
```

- [ ] **Step 5: Wire it into `run.sh`**

After `cd "$(dirname "$0")"`:

```bash
source scripts/sparkle-bundle.sh
```

After the `cp .build/debug/Noor ...` line:

```bash
sparkle_embed build/Noor.app .build/debug
```

Replace `codesign --force --sign - --entitlements Noor.entitlements build/Noor.app` with:

```bash
sparkle_sign build/Noor.app -
codesign --force --sign - --entitlements Noor.entitlements build/Noor.app
```

- [ ] **Step 6: Verify the release bundle (no notarization yet)**

Run the full release (re-notarizes 1.2.2 locally; nothing is published): `./release.sh 2>&1 | tail -12`
Expected: `status: Accepted` and both `spctl` lines `accepted`. Then:
- `codesign --verify --deep --strict --verbose=2 dist/Noor.app` → `valid on disk`, `satisfies its Designated Requirement`
- `codesign -dv dist/Noor.app/Contents/Frameworks/Sparkle.framework 2>&1 | grep -E 'Authority=Developer ID Application|flags=.*runtime'` → both match
- `open dist/Noor.app` → menu bar icon appears; `log show --last 1m --predicate 'process == "Noor"' | grep -i -E 'dyld|Library not loaded'` → nothing.
Quit the app afterwards.

- [ ] **Step 7: Verify the debug bundle**

Run: `./run.sh`
Expected: app launches, no dyld error. Quit it.

- [ ] **Step 8: Commit**

```bash
git add Package.swift Package.resolved scripts/sparkle-bundle.sh release.sh run.sh
git commit -m "build: embed and sign sparkle framework"
```

---

### Task 2: Updater service, keys and settings UI

**Files:**
- Modify: `scripts/sparkle-bundle.sh` (add `sparkle_stamp_plist`)
- Modify: `release.sh`, `run.sh` (call it)
- Create: `Noor/Services/UpdaterService.swift`
- Modify: `Noor/NoorApp.swift:8-11` (`init`)
- Modify: `Noor/Views/SettingsView.swift` (new section before "Tentang"; version text at ~line 305)
- Modify: `Noor/Info.plist`

**Interfaces:**
- Consumes: `sparkle-bundle.sh` from Task 1, `SPARKLE_BIN`.
- Produces:
  - `sparkle_stamp_plist <app_path> <feed_url> <public_ed_key>`
  - `release.sh` variables `SPARKLE_PUBLIC_KEY`, `FEED_URL`
  - `@MainActor final class UpdaterService: ObservableObject` with `static let shared`, `@Published private(set) var canCheckForUpdates: Bool`, `var automaticallyChecksForUpdates: Bool { get set }`, `func checkForUpdates()`, `static var currentVersion: String`

- [ ] **Step 1: Generate the EdDSA key and back it up**

Run: `.build/artifacts/sparkle/Sparkle/bin/generate_keys`
Expected: prints `<string>BASE64…</string>` for `SUPublicEDKey` (macOS may ask to allow Keychain access — allow). Copy the base64 value.
Then: `.build/artifacts/sparkle/Sparkle/bin/generate_keys -x ~/.apple-signing/sparkle_ed25519.key && chmod 600 ~/.apple-signing/sparkle_ed25519.key && ls -l ~/.apple-signing/sparkle_ed25519.key`
Expected: file exists, `-rw-------`.

- [ ] **Step 2: Add the plist stamping helper**

Append to `scripts/sparkle-bundle.sh`:

```bash
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
```

- [ ] **Step 3: Call it from `release.sh` and `run.sh`**

`release.sh`, after `NOTARY_PROFILE=...` (replace `<KEY>` with the Step 1 value — it is public, safe to commit):

```bash
SPARKLE_PUBLIC_KEY="<KEY>"
FEED_URL="${FEED_URL:-https://github.com/yolkmonday/noor/releases/latest/download/appcast.xml}"
```

`release.sh`, right after the existing PlistBuddy version-stamp line:

```bash
sparkle_stamp_plist dist/Noor.app "$FEED_URL" "$SPARKLE_PUBLIC_KEY"
```

`run.sh`, after `sparkle_embed ...` (same key value; debug builds point at the real feed):

```bash
sparkle_stamp_plist build/Noor.app \
  "https://github.com/yolkmonday/noor/releases/latest/download/appcast.xml" "<KEY>"
```

Also add the same four keys to `Noor/Info.plist` inside the top-level `<dict>`:

```xml
    <key>SUFeedURL</key>
    <string>https://github.com/yolkmonday/noor/releases/latest/download/appcast.xml</string>
    <key>SUPublicEDKey</key>
    <string><KEY></string>
    <key>SUEnableAutomaticChecks</key>
    <true/>
    <key>SUScheduledCheckInterval</key>
    <integer>86400</integer>
```

- [ ] **Step 4: Write `UpdaterService`**

`Noor/Services/UpdaterService.swift`:

```swift
import AppKit
import Combine
import Sparkle

/// Owns the Sparkle updater for the app's lifetime. Lives outside the views so a
/// check keeps running when the MenuBarExtra panel closes.
@MainActor
final class UpdaterService: ObservableObject {
    static let shared = UpdaterService()

    @Published private(set) var canCheckForUpdates = false

    private let controller: SPUStandardUpdaterController
    private var cancellable: AnyCancellable?

    private init() {
        controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        cancellable = controller.updater.publisher(for: \.canCheckForUpdates)
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.canCheckForUpdates = $0 }
    }

    var automaticallyChecksForUpdates: Bool {
        get { controller.updater.automaticallyChecksForUpdates }
        set {
            objectWillChange.send()
            controller.updater.automaticallyChecksForUpdates = newValue
        }
    }

    func checkForUpdates() {
        // LSUIElement app: without this Sparkle's window opens behind other apps
        NSApp.activate(ignoringOtherApps: true)
        controller.checkForUpdates(nil)
    }

    static var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "-"
    }
}
```

- [ ] **Step 5: Start it at launch**

`Noor/NoorApp.swift`, `init()` becomes:

```swift
    init() {
        // Set notification delegate for azan playback
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        // Start Sparkle so scheduled update checks run from launch
        _ = UpdaterService.shared
    }
```

- [ ] **Step 6: Settings UI**

In `SettingsView`, add a property next to the other state:

```swift
    @ObservedObject private var updater = UpdaterService.shared
```

Insert before `// MARK: - Tentang`:

```swift
                    // MARK: - Pembaruan
                    SettingsSection(title: "Pembaruan") {
                        VStack(spacing: 1) {
                            SettingsToggleRow(
                                icon: "arrow.triangle.2.circlepath",
                                title: "Periksa pembaruan otomatis",
                                subtitle: "Cek versi baru sekali sehari",
                                isOn: Binding(
                                    get: { updater.automaticallyChecksForUpdates },
                                    set: { updater.automaticallyChecksForUpdates = $0 }
                                )
                            )

                            Button {
                                updater.checkForUpdates()
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.down.circle")
                                        .font(.system(size: 14))
                                        .foregroundStyle(.secondary)
                                        .frame(width: 24)
                                    Text("Periksa Pembaruan…")
                                        .font(.subheadline)
                                    Spacer()
                                }
                                .padding(10)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .disabled(!updater.canCheckForUpdates)
                        }
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                    }

```

In the "Tentang" section replace `Text("1.0.0")` with `Text(UpdaterService.currentVersion)`.

- [ ] **Step 7: Verify (covers Review Focus 1–3)**

1. `./run.sh` → open panel → Settings: "Pembaruan" section visible, "Tentang" shows `1.2.2`.
2. Click "Periksa Pembaruan…" → a Sparkle window appears **in front** (the live feed has no `appcast.xml` yet, so expect Sparkle's "update error" alert). Focus 1 + 2.
3. Click it again, then immediately click elsewhere so the panel closes → the Sparkle alert still appears; app does not crash. Focus 3.
4. Toggle "Periksa pembaruan otomatis" off, quit, relaunch → still off (`defaults read com.noor.app SUEnableAutomaticChecks` → `0`). Toggle back on.
5. Turn Wi-Fi off, `defaults delete com.noor.app SULastCheckTime`, relaunch: no alert appears at launch (background checks are silent). Turn Wi-Fi back on.
6. `swift build -c release 2>&1 | grep -i warning` → no new warnings from `UpdaterService.swift`.

- [ ] **Step 8: Commit**

```bash
git add scripts/sparkle-bundle.sh release.sh run.sh Noor/Services/UpdaterService.swift Noor/NoorApp.swift Noor/Views/SettingsView.swift Noor/Info.plist
git commit -m "feat: in-app updates via sparkle"
```

---

### Task 3: Appcast generation in the release flow

**Files:**
- Modify: `release.sh` (after "Creating ZIP", before "Calculating SHA256")

**Interfaces:**
- Consumes: `SPARKLE_BIN`, `VERSION`, `APP_NAME`, notarized `dist/${APP_NAME}-${VERSION}.zip`.
- Produces: `dist/appcast.xml` (one `<item>` for `$VERSION`); optional input `release-notes/$VERSION.html`.

- [ ] **Step 1: Add appcast generation**

In `release.sh`, after the ZIP block (`cd ..` following `ditto`):

```bash
echo "Generating appcast..."
APPCAST_STAGING="$(mktemp -d)"
cp "dist/${APP_NAME}-${VERSION}.zip" "$APPCAST_STAGING/"
# Release notes shown in Sparkle's dialog, if present (same basename as the archive)
if [ -f "release-notes/${VERSION}.html" ]; then
  cp "release-notes/${VERSION}.html" "$APPCAST_STAGING/${APP_NAME}-${VERSION}.html"
fi
# Signs the ZIP with the EdDSA key from the login Keychain
"$SPARKLE_BIN/generate_appcast" \
  --download-url-prefix "https://github.com/yolkmonday/noor/releases/download/v${VERSION}/" \
  --embed-release-notes \
  -o dist/appcast.xml \
  "$APPCAST_STAGING"
rm -rf "$APPCAST_STAGING"
```

Change the final `shasum` line to also list the appcast: `shasum -a 256 dist/*.dmg dist/*.zip dist/appcast.xml`.

- [ ] **Step 2: Check the flag names against the bundled tool**

Run: `.build/artifacts/sparkle/Sparkle/bin/generate_appcast --help | grep -E 'download-url-prefix|embed-release-notes|-o '`
Expected: all three present. If `--embed-release-notes` is absent in this version, drop that flag (notes are then linked instead of embedded) and note it in the commit message.

- [ ] **Step 3: Run a release build and inspect the appcast**

Run: `./release.sh 2>&1 | tail -15 && cat dist/appcast.xml`
Expected: exactly one `<item>`, containing `sparkle:version="1.2.2"` (current `VERSION`), `url="https://github.com/yolkmonday/noor/releases/download/v1.2.2/Noor-1.2.2.zip"`, a non-empty `sparkle:edSignature`, `length=` equal to `stat -f %z dist/Noor-1.2.2.zip`, and `<sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>`.

- [ ] **Step 4: Verify the signature independently**

Run: `.build/artifacts/sparkle/Sparkle/bin/sign_update --verify dist/Noor-1.2.2.zip "$(grep -o 'edSignature="[^"]*"' dist/appcast.xml | cut -d'"' -f2)"`
Expected: exit 0, no error. If `--verify` is unsupported in this version, compare with `sign_update dist/Noor-1.2.2.zip` output — same `edSignature`.

- [ ] **Step 5: Commit**

```bash
git add release.sh
git commit -m "build: generate sparkle appcast on release"
```

---

### Task 4: Local end-to-end update test

No repo changes; this gates the real release. Work in `/tmp/noor-e2e`.

**Interfaces:**
- Consumes: `release.sh` with `FEED_URL` override (Task 2), appcast generation (Task 3).

- [ ] **Step 1: Build the "new" version 1.2.4 with a local feed**

```bash
sed -i '' 's/^VERSION=".*"/VERSION="1.2.4"/' release.sh
FEED_URL=http://localhost:8000/appcast.xml ./release.sh
mkdir -p /tmp/noor-e2e/feed
cp dist/Noor-1.2.4.zip /tmp/noor-e2e/feed/
cp dist/Noor-1.2.4.zip /tmp/noor-e2e/Noor-1.2.4.zip.good   # pristine copy for Step 7
# Local appcast: same signature, URL pointing at localhost
sed 's#https://github.com/yolkmonday/noor/releases/download/v1.2.4/#http://localhost:8000/#' dist/appcast.xml > /tmp/noor-e2e/feed/appcast.xml
```

- [ ] **Step 2: Build the "old" version 1.2.3 with the same local feed**

```bash
sed -i '' 's/^VERSION=".*"/VERSION="1.2.3"/' release.sh
FEED_URL=http://localhost:8000/appcast.xml ./release.sh
```

- [ ] **Step 3: Install 1.2.3 and serve the feed**

```bash
osascript -e 'quit app "Noor"'; rm -rf /Applications/Noor.app
ditto dist/Noor.app /Applications/Noor.app
cd /tmp/noor-e2e/feed && python3 -m http.server 8000   # run in background
open /Applications/Noor.app
```

- [ ] **Step 4: Run the update**

Settings → "Periksa Pembaruan…".
Expected: Sparkle dialog "Noor 1.2.4 tersedia" (Sparkle's own wording) in front → Install → download → app quits and relaunches. Settings → Tentang shows `1.2.4`.
Evidence: `defaults read /Applications/Noor.app/Contents/Info CFBundleShortVersionString` → `1.2.4`; http.server log shows GETs for `appcast.xml` and `Noor-1.2.4.zip`.

- [ ] **Step 5: Confirm the installed app is still notarized**

Run: `spctl --assess --type execute -v /Applications/Noor.app`
Expected: `accepted`, `source=Notarized Developer ID`.

- [ ] **Step 6: Negative test — tampered update is refused (Review Focus 4)**

```bash
osascript -e 'quit app "Noor"'
rm -rf /Applications/Noor.app && ditto dist/Noor.app /Applications/Noor.app   # dist/ still holds 1.2.3
printf 'x' >> /tmp/noor-e2e/feed/Noor-1.2.4.zip   # breaks the EdDSA signature
open /Applications/Noor.app
```
Settings → "Periksa Pembaruan…" → Install.
Expected: Sparkle reports the update is improperly signed and refuses; `/Applications/Noor.app` stays 1.2.3.

- [ ] **Step 7: Read-only location (Review Focus 5)**

Restore the good zip: `cp /tmp/noor-e2e/Noor-1.2.4.zip.good /tmp/noor-e2e/feed/Noor-1.2.4.zip`. Quit Noor, `hdiutil attach dist/Noor-1.2.3.dmg`, run Noor from the mounted volume, check for updates, Install.
Expected: Sparkle shows an error/asks to move the app; nothing crashes; the DMG volume is unchanged. Detach afterwards.

- [ ] **Step 8: Clean up**

```bash
pkill -f "http.server 8000"; rm -rf /tmp/noor-e2e
git checkout release.sh            # VERSION back to 1.2.2
git status --short                 # expect clean
```

---

### Task 5: Release v1.2.3 and update the cask

**Files:**
- Modify: `release.sh` (`VERSION="1.2.3"`), `Noor/Info.plist` (`1.2.3`)
- Create: `release-notes/1.2.3.html`
- Modify: `yolkmonday/homebrew-noor` → `Casks/noor.rb`

- [ ] **Step 1: Bump version and write release notes**

```bash
sed -i '' 's/^VERSION=".*"/VERSION="1.2.3"/' release.sh
sed -i '' 's#<string>1\.2\.2</string>#<string>1.2.3</string>#g' Noor/Info.plist
mkdir -p release-notes
```

`release-notes/1.2.3.html`:

```html
<h2>Noor 1.2.3</h2>
<ul>
  <li>Pembaruan otomatis: Noor kini mengecek dan memasang versi baru sendiri.</li>
  <li>Menu Pengaturan → Pembaruan untuk cek manual atau mematikan cek otomatis.</li>
</ul>
```

- [ ] **Step 2: Build, notarize, generate appcast**

Run: `./release.sh`
Expected: `status: Accepted`, `spctl` accepted for DMG and app, `dist/appcast.xml` with one item for 1.2.3 and URL `.../download/v1.2.3/Noor-1.2.3.zip`.

- [ ] **Step 3: Commit, tag, push, publish**

```bash
git add release.sh Noor/Info.plist release-notes/1.2.3.html
git commit -m "chore: bump version to 1.2.3"
git tag v1.2.3 && git push origin main v1.2.3
gh release create v1.2.3 dist/Noor-1.2.3.dmg dist/Noor-1.2.3.zip dist/appcast.xml \
  --title v1.2.3 \
  --notes "Pembaruan otomatis lewat Sparkle. Pengguna 1.2.2: update manual sekali ini (DMG atau \`brew upgrade --cask noor\`); setelah itu otomatis."
```

- [ ] **Step 4: Verify the live feed**

Run: `curl -sL https://github.com/yolkmonday/noor/releases/latest/download/appcast.xml | grep -E 'sparkle:version|url='`
Expected: `1.2.3` and the v1.2.3 ZIP URL. And `curl -sIL <that url> | grep -E '^HTTP' | tail -1` → `200`.

- [ ] **Step 5: Update the cask**

In a clone of `yolkmonday/homebrew-noor`, `Casks/noor.rb`: set `version "1.2.3"`, `sha256` to `shasum -a 256 dist/Noor-1.2.3.zip` (compute from the local file; the release asset is byte-identical — confirm with `gh release download v1.2.3 -R yolkmonday/noor -p Noor-1.2.3.zip -O - | shasum -a 256`), and add a line after `depends_on arch: :arm64`:

```ruby
  auto_updates true
```

```bash
git commit -am "noor 1.2.3: auto_updates" && git push
```

- [ ] **Step 6: Verify Homebrew**

Run: `brew update && brew info --cask yolkmonday/noor/noor | head -3 && brew audit --cask yolkmonday/noor/noor`
Expected: shows 1.2.3, audit has no errors about `auto_updates` or sha256.
