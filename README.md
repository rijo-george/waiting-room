# The Waiting Room

**Your follow-ups have a home now.**

Track every open loop in both directions — who owes you, and who you're blocking. Native macOS + iOS apps, sharing the same data via iCloud.

![WR](macos/AppIcon.png)

## Download

**[Download for Mac](https://github.com/rijo-george/waiting-room/releases/latest)** — Universal binary, signed & notarized. Works on Apple Silicon and Intel.

**iOS** — Coming soon to the App Store. Build from source today (see below).

## Features

- **Two-panel view** — Left: what you're waiting on. Right: what others need from you.
- **Age indicators** — Green (fresh), yellow (getting old), red (overdue). At a glance.
- **Nudge tracking** — Log every follow-up with timestamps.
- **Resolve & archive** — Done items move to history with duration tracking.
- **6 themes** — Dark, Light, Sunset, Ocean, Forest, Rose. Synced across devices.
- **iCloud sync** — Automatically syncs across Macs and iPhones via iCloud Drive.
- **100% yours** — No accounts, no tracking. Data lives locally and syncs through your own iCloud.

## Killer Features

### The Receipt
Every resolved item gets a receipt — like a shop receipt for accountability. Who, what, how long, how many nudges. Copy and share it.

### Clipboard Radar
Copy an email that says "I'll send it by Friday" — the app detects it and offers to create a wait item, pre-filled. Zero typing.

## Apps

### macOS
- Built with SwiftUI
- Full keyboard shortcuts (A/R/N/H/T + vim keys)
- Clipboard Radar with NLP name extraction
- Requires macOS 14 (Sonoma) or later

### iOS
- Built with SwiftUI for iPhone & iPad
- Side-by-side panels on iPad, segmented control on iPhone
- Swipe to resolve, swipe to nudge
- Haptic feedback, native share sheet for receipts
- Requires iOS 17 or later

## Keyboard Shortcuts (macOS)

| Key | Action |
|-----|--------|
| `A` | Add item |
| `R` | Resolve |
| `N` | Nudge |
| `H` | History |
| `T` | Theme picker |
| `S` / `Tab` | Switch panel |
| `J` / `K` | Navigate up/down |
| `←` / `→` | Switch panel |

## Data Storage

Both apps read/write the same files via iCloud Drive using a shared ubiquity container:

```
~/Library/Mobile Documents/iCloud~com~rijo~waitingroom/Documents/
├── data.json      ← items, history, nudges
└── config.json    ← theme preference
```

If iCloud Drive is not available, data falls back to `~/.waiting-room/` on Mac or the app's Documents directory on iOS.

**Sync behavior:**
- Changes are written with `NSFileCoordinator` to prevent concurrent write corruption
- On load, local and remote data are merged by union of item IDs
- Items that appear in history (resolved) are automatically removed from active lists
- File system events and `NSMetadataQuery` trigger automatic reloads

## Building from Source

**macOS app:**
```bash
cd macos
swift build              # Debug build
swift test               # Run tests
bash build-app.sh        # Release build + sign
bash build-dmg.sh        # Release build + sign + notarize DMG
```
Requires Swift 5.9+ and macOS 14+.

**iOS app:**
```bash
cd ios
brew install xcodegen    # One-time setup
xcodegen generate        # Generate Xcode project
open WaitingRoom.xcodeproj
```
Set your development team in Xcode, then build and run. Requires Xcode 16+ and iOS 17+.

**Running tests:**
```bash
# macOS
cd macos && swift test

# iOS (via Xcode)
cd ios && xcodegen generate
xcodebuild test -project WaitingRoom.xcodeproj -scheme WaitingRoom -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Architecture

```
waiting-room/
├── macos/                 # macOS app (Swift Package)
│   ├── Sources/           # App source files
│   ├── Tests/             # Unit tests
│   ├── Package.swift      # SPM manifest
│   └── build-*.sh         # Build & distribution scripts
├── ios/                   # iOS app (xcodegen)
│   ├── WaitingRoom/       # App source files
│   ├── WaitingRoomTests/  # Unit tests
│   └── project.yml        # xcodegen config
└── docs/                  # Marketing website (GitHub Pages)
    ├── index.html
    ├── style.css
    └── script.js
```

Both apps share the same data model (`WaitingItem`, `Nudge`, `WaitingData`) and storage format. The data layer is intentionally duplicated rather than shared via a Swift package, because the storage resolution logic differs between platforms (iCloud ubiquity container API on iOS vs. direct filesystem path on macOS).

## License

MIT
