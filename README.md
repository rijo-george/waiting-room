# The Waiting Room

**Your follow-ups have a home now.**

Track every open loop in both directions — who owes you, and who you're blocking. Native macOS + iOS apps, sharing the same data via iCloud.

![WR](macos/AppIcon.png)

## Download

**[Download for Mac](https://github.com/rijo-george/waiting-room/releases/latest)** — Universal binary, signed & notarized. Works on Apple Silicon and Intel.

**[Get on the App Store (iOS)](https://apps.apple.com/app/the-waiting-room/id0000000000)** — iPhone & iPad.

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

### iOS
- Built with SwiftUI for iPhone & iPad
- Side-by-side panels on iPad, segmented control on iPhone
- Swipe to resolve, swipe to nudge
- Haptic feedback, native share sheet for receipts

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

## Data Storage

Both apps read/write the same files via iCloud Drive:

```
~/Library/Mobile Documents/com~apple~CloudDocs/WaitingRoom/
├── data.json      ← items, history, nudges
└── config.json    ← theme preference
```

If iCloud Drive is not available, data falls back to `~/.waiting-room/` on Mac or the app's Documents directory on iOS.

## Building from Source

**macOS app:**
```bash
cd macos
bash build-app.sh        # Build + sign
bash build-dmg.sh        # Build + sign + notarize DMG
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

## License

MIT
