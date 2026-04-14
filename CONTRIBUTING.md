# Contributing to The Waiting Room

Thanks for your interest in contributing! This is a small, focused app — pull requests that keep it that way are welcome.

## Getting Started

### Prerequisites

- **macOS 14+** (Sonoma or later)
- **Xcode 16+** (for iOS builds)
- **Swift 5.9+**
- **xcodegen** (for iOS project generation): `brew install xcodegen`

### macOS App

The macOS app uses Swift Package Manager:

```bash
cd macos
swift build        # Debug build
swift test         # Run unit tests
swift build -c release --arch arm64 --arch x86_64  # Universal release build
```

To run the app locally:
```bash
swift build && .build/debug/WaitingRoom
```

### iOS App

The iOS app uses [xcodegen](https://github.com/yonaskolb/XcodeGen) to generate its Xcode project:

```bash
cd ios
xcodegen generate
open WaitingRoom.xcodeproj
```

Set your development team in Xcode signing settings, then build and run.

To run tests from the command line:
```bash
cd ios
xcodegen generate
xcodebuild test \
  -project WaitingRoom.xcodeproj \
  -scheme WaitingRoom \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

### Website

The marketing site lives in `docs/` and is served via GitHub Pages. Open `docs/index.html` in a browser to preview locally.

## Project Structure

```
macos/Sources/          # macOS app source
macos/Tests/            # macOS unit tests
ios/WaitingRoom/        # iOS app source
ios/WaitingRoomTests/   # iOS unit tests
docs/                   # Marketing website
```

### Key Files

| File | Role |
|------|------|
| `Models.swift` | Data structures, ISO8601 parsing, storage location, merge logic |
| `Store.swift` (iOS) | File I/O, iCloud sync, NSFileCoordinator, merge-on-load |
| `ContentView.swift` | Main UI, keyboard shortcuts, panel layout |
| `ClipboardRadar.swift` | NLP-powered clipboard monitoring |
| `Theme.swift` | 6 theme definitions, config persistence |
| `ReceiptView.swift` | "Shop receipt" UI for resolved items |

### Data Flow

1. `WaitingRoomStore` holds all state in a `@Published var data: WaitingData`
2. On load: reads `data.json` → merges with in-memory state → updates UI
3. On save: reads latest from disk → merges with in-memory → writes atomically
4. File monitor detects external changes → triggers reload → merge

The merge is a union by item ID. Local items appear first (preserving user's order), then remote-only items are appended. Items in history are excluded from active lists.

## Guidelines

- **No new dependencies.** The app has zero third-party packages. Keep it that way.
- **Write tests.** Every new model or logic change should have corresponding tests.
- **Keep the two apps in sync.** If you change the data model, update both macOS and iOS.
- **Don't break iCloud sync.** The JSON format is the contract between platforms.
- **Match the existing code style.** SwiftUI views, MARK sections, environment objects.

## Testing

Run tests before submitting a PR:

```bash
# macOS
cd macos && swift test

# iOS
cd ios && xcodegen generate && xcodebuild test \
  -project WaitingRoom.xcodeproj \
  -scheme WaitingRoom \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

CI runs both automatically on every push and PR to `main`.

## Releases

macOS releases are built with `build-dmg.sh`, which creates a signed and notarized DMG. Only the repo owner can do this (requires Developer ID signing identity).

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
