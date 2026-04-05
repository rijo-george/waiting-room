# 🚪 The Waiting Room

> Track open loops in both directions — things you're waiting on, and things others are waiting on from you.

Most productivity tools track tasks. **The Waiting Room tracks dependencies** — the invisible blockers that stall you and the places where *you're* the bottleneck.

---

## Screenshot

```
┌─ ➡  I'M WAITING FOR... ──────────────┐┌─ ⬅  WAITING FOR ME... ─────────────────┐
│                                       ││                                         │
│ ▶ 🔴 Priya · contract · 12d · due Apr8││   🟡 Rohan · deck feedback · 4d        │
│   🟡 AWS Support · ticket · 5d       ││   🟢 Client · proposal · 1d            │
│   🟢 Zepto · package · 1d            ││                                         │
│                                       ││                                         │
└───────────────────────────────────────┘└─────────────────────────────────────────┘
  Waiting on 3 people  ·  blocking 2 people  ·  oldest: 12d
```

---

## Install

```bash
pip install textual
```

Then run:

```bash
python3 waiting_room.py
```

Data is stored at `~/.waiting-room/data.json` — no cloud, no accounts.

---

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `Tab` | Switch between panels |
| `↑` / `↓` or `k` / `j` | Move cursor |
| `a` | Add item to active panel |
| `r` | Resolve selected item |
| `n` | Log a nudge (follow-up) |
| `h` | View history (resolved items) |
| `q` | Quit |

---

## How it works

**Two panels:**
- **I'm waiting for...** — people/services blocking you (Priya's contract, AWS ticket, courier)
- **Waiting for me...** — people you're blocking (team member waiting on your decision, client waiting on proposal)

**Age coloring:**
- 🟢 < 3 days — fresh
- 🟡 3–7 days — getting stale
- 🔴 7+ days — needs action

**Nudge log:** Press `n` to log a follow-up without closing the item. Tracks *how many times* you've had to chase something.

**Resolve:** Press `r` to close an item. It moves to history with duration tracked.

---

## Why this exists

Most open loops live in your head as background noise. The Waiting Room externalizes them — you see at a glance if you're being blocked, if you're blocking others, and how long things have been stalled.

The goal: **zero items over 7 days.** That's it.

---

## Philosophy

> "Most projects don't fail at the work. They fail at the waiting."

Built in the spirit of getting things *unblocked*. Small tool, big clarity.

---

## License

MIT
