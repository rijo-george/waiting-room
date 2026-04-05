# The Waiting Room

**Your follow-ups have a home now.**

Track every open loop in both directions — who owes you, and who you're blocking. Native macOS app + terminal TUI, sharing the same local data.

![WR](macos/AppIcon.png)

## Download

**[Download DMG (macOS)](https://github.com/rijo-george/waiting-room/releases/latest)** — Universal binary, signed & notarized. Works on Apple Silicon and Intel.

**Terminal TUI:**
```bash
pip install textual
python3 tui/waiting_room.py
```

## Features

- **Two-panel view** — Left: what you're waiting on. Right: what others need from you.
- **Age indicators** — Green (fresh), yellow (getting old), red (overdue). At a glance.
- **Nudge tracking** — Log every follow-up with timestamps.
- **Resolve & archive** — Done items move to history with duration tracking.
- **6 themes** — Dark, Light, Sunset, Ocean, Forest, Rose. Synced between apps.
- **100% local** — Data lives in `~/.waiting-room/`. No accounts, no cloud, no tracking.
- **iCloud sync** — Automatically syncs across Macs via iCloud Drive.

## Killer Features

### The Receipt
Every resolved item gets a receipt — like a shop receipt for accountability. Who, what, how long, how many nudges. Copy and share it.

### Clipboard Radar
Copy an email that says "I'll send it by Friday" — the app detects it and offers to create a wait item, pre-filled. Zero typing.

### Zen Mode
Press `Z` for a fullscreen ambient display of all your open loops. Your screen becomes your accountability board.

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `A` | Add item |
| `R` | Resolve |
| `N` | Nudge |
| `H` | History |
| `T` | Theme picker |
| `Z` | Zen mode |
| `S` / `Tab` | Switch panel |
| `J` / `K` | Navigate up/down |
| `Q` | Quit (TUI) |

## Data Storage

Both apps read/write the same files:

```
~/.waiting-room/
├── data.json      ← items, history, nudges
└── config.json    ← theme preference
```

With iCloud Drive enabled, data syncs to `~/Library/Mobile Documents/com~apple~CloudDocs/WaitingRoom/` and a symlink keeps the TUI compatible.

## Building from Source

**macOS app:**
```bash
cd macos
bash build-app.sh        # Build + sign
bash build-dmg.sh        # Build + sign + notarize DMG
```
Requires Swift 5.9+ and macOS 14+.

**TUI:**
```bash
pip install textual
python3 tui/waiting_room.py
```
Requires Python 3.10+.

## License

MIT
