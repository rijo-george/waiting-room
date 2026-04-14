# Changelog

All notable changes to The Waiting Room are documented here.

## [Unreleased]

### Added
- **Test suites** for both macOS and iOS (ISO8601 parsing, merge logic, models, themes, age colors)
- **GitHub Actions CI** — automated build and test on every push and PR
- **CONTRIBUTING.md** with build instructions and architecture overview
- This **CHANGELOG.md**

### Fixed
- **Website** — rebuilt `index.html` to use the full `style.css`/`script.js` design system (was using disconnected inline styles)
- **README** — corrected data storage paths, removed placeholder App Store link, fixed version references, added test and architecture documentation
- **macOS entitlements** — added iCloud container and app group entitlements to match iOS
- **.gitignore** — added Xcode artifacts, removed tracked binaries (`.app` bundle, `.dmg.zip`, `.xcodeproj`)

### Changed
- Exposed merge logic via `testMerge()` for unit testing on both platforms

---

## [2.1.0] — 2026-03-28

### Fixed
- Reload on app activation and re-establish file monitor on rename
- Fix concurrent add data loss: merge on load instead of replacing
- Fix iCloud sync: add file coordination, merge logic, and file monitoring
- Fix macOS launch failure by using direct iCloud container path

### Changed
- Updated download links to v2.1.0 release

---

## [2.0.0] — 2026-03-15

### Added
- **iOS app** — native SwiftUI for iPhone & iPad
  - Side-by-side panels on iPad, segmented control on iPhone
  - Swipe to resolve, swipe to nudge
  - Haptic feedback on actions
  - Native share sheet for receipts
  - `NSMetadataQuery` for iCloud file change monitoring
- **Shared iCloud container** (`iCloud.com.rijo.waitingroom`) for cross-device sync
- App group container for potential widget sharing
- Clipboard Radar adapted for iOS (respects paste prompt)

### Removed
- TUI (terminal) interface
- Zen mode

### Changed
- iCloud storage moved from `com~apple~CloudDocs/WaitingRoom` to shared ubiquity container
- macOS app migrates data from legacy locations automatically
- Symlink `~/.waiting-room` → iCloud container for backwards compatibility

---

## [1.1.1] — 2026-03-10

### Fixed
- Use Textual `$variables` in CSS, not hardcoded hex

---

## [1.1.0] — 2026-03-08

### Changed
- Use Textual Theme API instead of CSS-only approach
- Pinned `textual>=8.0,<9` to fix rendering on other Macs
- Synced TUI theme colors exactly with macOS app

---

## [1.0.0] — 2026-03-01

### Added
- macOS app built with SwiftUI
- Two-panel view (waiting for / waiting on me)
- Age indicators (green < 3d, yellow 3–7d, red > 7d)
- Nudge tracking with timestamps
- Resolve & archive with duration tracking
- 6 themes (Dark, Light, Sunset, Ocean, Forest, Rose)
- The Receipt — shareable accountability record for resolved items
- Clipboard Radar with NLP name extraction
- Full keyboard navigation (A/R/N/H/T + vim keys)
- iCloud Drive sync
- Local fallback to `~/.waiting-room/`
- Signed and notarized DMG distribution
