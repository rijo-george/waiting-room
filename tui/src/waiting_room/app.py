#!/usr/bin/env python3
"""
The Waiting Room — Track open loops in both directions.
  I'm waiting for... | Waiting for me...
"""

import json
import uuid
from datetime import datetime, date
from pathlib import Path
from textual.app import App, ComposeResult
from textual.binding import Binding
from textual.containers import Horizontal, Vertical, ScrollableContainer
from textual.screen import ModalScreen
from textual.widgets import Header, Footer, Label, Static, Button, Input, DataTable

# ── Data ─────────────────────────────────────────────────────────────────────

DATA_DIR = Path.home() / ".waiting-room"
DATA_FILE = DATA_DIR / "data.json"
CONFIG_FILE = DATA_DIR / "config.json"

def load_data():
    DATA_DIR.mkdir(exist_ok=True)
    if DATA_FILE.exists():
        return json.loads(DATA_FILE.read_text())
    return {"waiting_for": [], "waiting_on_me": [], "history": []}

def save_data(data):
    DATA_FILE.write_text(json.dumps(data, indent=2))

def load_config():
    if CONFIG_FILE.exists():
        try:
            return json.loads(CONFIG_FILE.read_text())
        except Exception:
            pass
    return {"theme": "dark"}

def save_config(config):
    DATA_DIR.mkdir(exist_ok=True)
    CONFIG_FILE.write_text(json.dumps(config, indent=2))

# ── Themes ───────────────────────────────────────────────────────────────────

THEMES = {
    "dark": {
        "name": "Dark",
        "screen_bg": "#1c1c2b", "panel_bg": "#212133",
        "text_fg": "#ffffff",
        "header_bg": "#19192d", "header_fg": "#ffffff",
        "footer_bg": "#19192d", "footer_fg": "#878787",
        "panel_border": "#666666", "panel_active_border": "#7a68ed",
        "left_title_bg": "#193a2d", "left_title_fg": "#66ffaa",
        "right_title_bg": "#3a192d", "right_title_fg": "#ff87cc",
        "selected_bg": "#2b2b4c", "selected_fg": "#ffffff",
        "empty_fg": "#878787",
        "status_bg": "#111121", "status_fg": "#878787", "status_border": "#666666",
        "modal_bg": "#19192d", "modal_border": "#7a68ed",
        "modal_title": "#aaaaff", "modal_label": "#878787",
    },
    "light": {
        "name": "Light",
        "screen_bg": "#f4f4f9", "panel_bg": "#ffffff",
        "text_fg": "#21212b",
        "header_bg": "#efeff7", "header_fg": "#21212b",
        "footer_bg": "#efeff7", "footer_fg": "#7f7f8c",
        "panel_border": "#bfbfbf", "panel_active_border": "#594ccc",
        "left_title_bg": "#e5f9ed", "left_title_fg": "#218c54",
        "right_title_bg": "#f9e5ef", "right_title_fg": "#bf337f",
        "selected_bg": "#e5e5f9", "selected_fg": "#21212b",
        "empty_fg": "#7f7f8c",
        "status_bg": "#eaeaf2", "status_fg": "#7f7f8c", "status_border": "#bfbfbf",
        "modal_bg": "#ffffff", "modal_border": "#594ccc",
        "modal_title": "#594ccc", "modal_label": "#7f7f8c",
    },
    "sunset": {
        "name": "Sunset",
        "screen_bg": "#261919", "panel_bg": "#2d1e1e",
        "text_fg": "#fff2e5",
        "header_bg": "#331914", "header_fg": "#fff2e5",
        "footer_bg": "#331914", "footer_fg": "#997f72",
        "panel_border": "#593f33", "panel_active_border": "#ff8c33",
        "left_title_bg": "#3f2d14", "left_title_fg": "#ffbf4c",
        "right_title_bg": "#3f1919", "right_title_fg": "#ff7272",
        "selected_bg": "#4c2d1e", "selected_fg": "#fff2e5",
        "empty_fg": "#997f72",
        "status_bg": "#1e1111", "status_fg": "#997f72", "status_border": "#593f33",
        "modal_bg": "#331e19", "modal_border": "#ff8c33",
        "modal_title": "#ffbf66", "modal_label": "#997f72",
    },
    "ocean": {
        "name": "Ocean",
        "screen_bg": "#141e2d", "panel_bg": "#192638",
        "text_fg": "#e5f2ff",
        "header_bg": "#0f192d", "header_fg": "#e5f2ff",
        "footer_bg": "#0f192d", "footer_fg": "#728ca5",
        "panel_border": "#334760", "panel_active_border": "#3399e5",
        "left_title_bg": "#142d3f", "left_title_fg": "#4cd8f2",
        "right_title_bg": "#1e2647", "right_title_fg": "#99bfff",
        "selected_bg": "#1e3351", "selected_fg": "#e5f2ff",
        "empty_fg": "#728ca5",
        "status_bg": "#0c1423", "status_fg": "#728ca5", "status_border": "#334760",
        "modal_bg": "#141e33", "modal_border": "#3399e5",
        "modal_title": "#66ccff", "modal_label": "#728ca5",
    },
    "forest": {
        "name": "Forest",
        "screen_bg": "#192319", "panel_bg": "#1e2d1e",
        "text_fg": "#eaf4e5",
        "header_bg": "#142314", "header_fg": "#eaf4e5",
        "footer_bg": "#142314", "footer_fg": "#7f937a",
        "panel_border": "#384c38", "panel_active_border": "#66bf66",
        "left_title_bg": "#193819", "left_title_fg": "#8cf28c",
        "right_title_bg": "#332d14", "right_title_fg": "#e5cc7f",
        "selected_bg": "#263f26", "selected_fg": "#eaf4e5",
        "empty_fg": "#7f937a",
        "status_bg": "#0f190f", "status_fg": "#7f937a", "status_border": "#384c38",
        "modal_bg": "#192819", "modal_border": "#66bf66",
        "modal_title": "#8ce58c", "modal_label": "#7f937a",
    },
    "rose": {
        "name": "Rose",
        "screen_bg": "#231923", "panel_bg": "#2d1e2d",
        "text_fg": "#f4eaf4",
        "header_bg": "#281428", "header_fg": "#f4eaf4",
        "footer_bg": "#281428", "footer_fg": "#937a8c",
        "panel_border": "#4c384c", "panel_active_border": "#d866a5",
        "left_title_bg": "#38192d", "left_title_fg": "#ffa5d8",
        "right_title_bg": "#2d193d", "right_title_fg": "#cc99ff",
        "selected_bg": "#3f263f", "selected_fg": "#f4eaf4",
        "empty_fg": "#937a8c",
        "status_bg": "#190f19", "status_fg": "#937a8c", "status_border": "#4c384c",
        "modal_bg": "#281928", "modal_border": "#d866a5",
        "modal_title": "#ff99d8", "modal_label": "#937a8c",
    },
}

def build_css(t):
    """Build the full Textual CSS from a theme dict."""
    return f"""
    Screen {{
        background: {t['screen_bg']};
        color: {t['text_fg']};
    }}

    Header {{
        background: {t['header_bg']};
        color: {t['header_fg']};
        text-style: bold;
    }}

    Footer {{
        background: {t['footer_bg']};
        color: {t['footer_fg']};
    }}

    #main-layout {{
        layout: horizontal;
        height: 1fr;
        padding: 1 2;
        background: {t['screen_bg']};
    }}

    Panel {{
        width: 1fr;
        border: round {t['panel_border']};
        padding: 0 1;
        background: {t['panel_bg']};
    }}

    .panel-active {{
        border: round {t['panel_active_border']};
    }}

    ScrollableContainer {{
        background: {t['panel_bg']};
    }}

    #panel-title-waiting_for {{
        background: {t['left_title_bg']};
        color: {t['left_title_fg']};
        text-style: bold;
        padding: 0 1;
        margin-bottom: 1;
    }}

    #panel-title-waiting_on_me {{
        background: {t['right_title_bg']};
        color: {t['right_title_fg']};
        text-style: bold;
        padding: 0 1;
        margin-bottom: 1;
    }}

    ItemWidget {{
        height: 1;
        background: {t['panel_bg']};
        color: {t['text_fg']};
    }}

    .selected-item {{
        background: {t['selected_bg']};
        color: {t['selected_fg']};
        text-style: bold;
    }}

    .empty-label {{
        color: {t['empty_fg']};
        padding: 1 0;
    }}

    #status-bar {{
        height: 3;
        background: {t['status_bg']};
        padding: 0 2;
        border-top: solid {t['status_border']};
    }}

    #status-text {{
        color: {t['status_fg']};
        padding: 1 0;
    }}

    #modal-box {{
        width: 60;
        height: auto;
        border: round {t['modal_border']};
        background: {t['modal_bg']};
        padding: 2 3;
        margin: 4 10;
    }}

    #history-box {{
        width: 90;
        height: 35;
        border: round {t['modal_border']};
        background: {t['modal_bg']};
        padding: 2 3;
        margin: 2 4;
    }}

    #receipt-text {{
        color: {t['text_fg']};
    }}

    DataTable {{
        background: {t['modal_bg']};
        color: {t['text_fg']};
    }}

    #modal-title {{
        color: {t['modal_title']};
        text-style: bold;
        margin-bottom: 1;
    }}

    #modal-buttons {{
        margin-top: 1;
    }}

    Input {{
        background: {t['panel_bg']};
        color: {t['text_fg']};
    }}

    AddItemModal Label, NudgeModal Label {{
        color: {t['modal_label']};
        margin-top: 1;
    }}

    #theme-grid {{
        layout: horizontal;
        height: auto;
        margin: 1 0;
    }}

    .theme-btn {{
        margin: 0 1;
        min-width: 12;
    }}

    .theme-btn-active {{
        text-style: bold reverse;
    }}
    """

# ── Helpers ──────────────────────────────────────────────────────────────────

def age_days(since_str):
    try:
        since = datetime.fromisoformat(since_str).date()
        return (date.today() - since).days
    except Exception:
        return 0

def age_emoji(days):
    if days < 3:
        return "🟢"
    elif days < 7:
        return "🟡"
    return "🔴"

def fmt_date(iso):
    try:
        return datetime.fromisoformat(iso).strftime("%b %d")
    except Exception:
        return "—"

def parse_expected(text):
    if not text:
        return ""
    for fmt in ("%Y-%m-%d", "%b %d", "%B %d", "%b %d, %Y", "%B %d, %Y", "%d %b", "%d %B"):
        try:
            parsed = datetime.strptime(text, fmt).date()
            if parsed.year == 1900:
                parsed = parsed.replace(year=date.today().year)
            return parsed.isoformat()
        except ValueError:
            continue
    return text

def new_item(who, what, expected="", note=""):
    return {
        "id": str(uuid.uuid4()),
        "who": who,
        "what": what,
        "since": datetime.now().isoformat(),
        "expected": parse_expected(expected),
        "nudges": [],
        "note": note,
    }

def build_item_text(item, selected=False):
    days = age_days(item["since"])
    emoji = age_emoji(days)
    raw_expected = item.get("expected", "")
    expected = f" · due {fmt_date(raw_expected) if 'T' in raw_expected or '-' in raw_expected else raw_expected}" if raw_expected else ""
    nudge_count = len(item.get("nudges", []))
    nudge_str = f" · 📬×{nudge_count}" if nudge_count else ""
    day_str = f"{days}d" if days > 0 else "today"
    text = f"{emoji} {item['who']} · {item['what']} · {day_str}{expected}{nudge_str}"
    prefix = "▶ " if selected else "  "
    return prefix + text

# ── Item Widget ───────────────────────────────────────────────────────────────

class ItemWidget(Static):
    def __init__(self, item: dict, selected: bool = False):
        self._item_data = item
        self._is_selected = selected
        super().__init__(build_item_text(item, selected))
        if selected:
            self.add_class("selected-item")

    def refresh_display(self, selected: bool):
        self._is_selected = selected
        self.update(build_item_text(self._item_data, selected))
        if selected:
            self.add_class("selected-item")
        else:
            self.remove_class("selected-item")

# ── Add Item Modal ────────────────────────────────────────────────────────────

class AddItemModal(ModalScreen):
    BINDINGS = [("escape", "dismiss(None)", "Cancel")]

    def __init__(self, direction: str):
        super().__init__()
        self.direction = direction

    def compose(self) -> ComposeResult:
        label = "I'm waiting for..." if self.direction == "waiting_for" else "They're waiting for me..."
        with Vertical(id="modal-box"):
            yield Label(f"➕ New item — {label}", id="modal-title")
            yield Label("Who? (person / service / thing)")
            yield Input(placeholder="e.g. Priya, AWS Support, Zepto", id="input-who")
            yield Label("What?")
            yield Input(placeholder="e.g. contract, reply, package", id="input-what")
            yield Label("Expected by? (optional, e.g. Apr 10)")
            yield Input(placeholder="optional", id="input-expected")
            yield Label("Note? (optional)")
            yield Input(placeholder="optional context", id="input-note")
            with Horizontal(id="modal-buttons"):
                yield Button("Add", variant="primary", id="btn-add")
                yield Button("Cancel", variant="default", id="btn-cancel")

    def on_button_pressed(self, event: Button.Pressed):
        if event.button.id == "btn-add":
            who = self.query_one("#input-who", Input).value.strip()
            what = self.query_one("#input-what", Input).value.strip()
            expected = self.query_one("#input-expected", Input).value.strip()
            note = self.query_one("#input-note", Input).value.strip()
            if who and what:
                self.dismiss(new_item(who, what, expected, note))
            else:
                self.query_one("#input-who").focus()
        else:
            self.dismiss(None)

# ── Nudge Modal ───────────────────────────────────────────────────────────────

class NudgeModal(ModalScreen):
    BINDINGS = [("escape", "dismiss(None)", "Cancel")]

    def __init__(self, item: dict):
        super().__init__()
        self.item = item

    def compose(self) -> ComposeResult:
        with Vertical(id="modal-box"):
            yield Label(f"📬 Nudge — {self.item['who']} / {self.item['what']}", id="modal-title")
            yield Label("Add a note (optional):")
            yield Input(placeholder="e.g. sent follow-up email", id="input-nudge")
            with Horizontal(id="modal-buttons"):
                yield Button("Log Nudge", variant="primary", id="btn-nudge")
                yield Button("Cancel", variant="default", id="btn-cancel")

    def on_button_pressed(self, event: Button.Pressed):
        if event.button.id == "btn-nudge":
            note = self.query_one("#input-nudge", Input).value.strip()
            self.dismiss(note or "nudged")
        else:
            self.dismiss(None)

# ── Confirm Modal ────────────────────────────────────────────────────────────

class ConfirmModal(ModalScreen):
    BINDINGS = [("escape", "dismiss(False)", "Cancel")]

    def __init__(self, message: str):
        super().__init__()
        self.message = message

    def compose(self) -> ComposeResult:
        with Vertical(id="modal-box"):
            yield Label(self.message, id="modal-title")
            with Horizontal(id="modal-buttons"):
                yield Button("Yes", variant="primary", id="btn-yes")
                yield Button("No", variant="default", id="btn-no")

    def on_button_pressed(self, event: Button.Pressed):
        self.dismiss(event.button.id == "btn-yes")

# ── Theme Picker Modal ───────────────────────────────────────────────────────

class ThemePickerModal(ModalScreen):
    BINDINGS = [("escape", "dismiss(None)", "Cancel")]

    def __init__(self, current_theme: str):
        super().__init__()
        self.current_theme = current_theme

    def compose(self) -> ComposeResult:
        with Vertical(id="modal-box"):
            yield Label("🎨 Choose Theme", id="modal-title")
            with Horizontal(id="theme-grid"):
                for key, t in THEMES.items():
                    btn = Button(t["name"], id=f"theme-{key}", classes="theme-btn")
                    if key == self.current_theme:
                        btn.add_class("theme-btn-active")
                    yield btn
            with Horizontal(id="modal-buttons"):
                yield Button("Cancel", variant="default", id="btn-cancel")

    def on_button_pressed(self, event: Button.Pressed):
        bid = event.button.id
        if bid and bid.startswith("theme-"):
            self.dismiss(bid.removeprefix("theme-"))
        else:
            self.dismiss(None)

# ── Receipt Modal ────────────────────────────────────────────────────────────

class ReceiptModal(ModalScreen):
    BINDINGS = [("escape", "dismiss()", "Close"), ("c", "copy_receipt", "Copy")]

    def __init__(self, item: dict, direction: str):
        super().__init__()
        self.item = item
        self.direction = direction

    def _build_receipt(self):
        i = self.item
        days = i.get("duration_days", age_days(i["since"]))
        dir_label = "I WAITED" if self.direction == "waiting_for" else "THEY WAITED ON ME"
        opened = fmt_date(i.get("since", ""))
        resolved = fmt_date(i.get("resolved_at", ""))
        nudges = i.get("nudges", [])

        lines = []
        lines.append("════════════════════════════════════")
        lines.append("        THE WAITING ROOM")
        lines.append("           — RESOLVED —")
        lines.append("════════════════════════════════════")
        lines.append("")
        lines.append(f"  WHO:       {i['who']}")
        lines.append(f"  WHAT:      {i['what']}")
        lines.append(f"  DIRECTION: {dir_label}")
        lines.append(f"  OPENED:    {opened}")
        lines.append(f"  RESOLVED:  {resolved}")
        if i.get("expected"):
            lines.append(f"  EXPECTED:  {i['expected']}")
        lines.append("")
        lines.append(f"        ~~~~~~~~  {days} {'DAY' if days == 1 else 'DAYS'}  ~~~~~~~~")
        lines.append("")
        if nudges:
            lines.append(f"  FOLLOW-UPS: {len(nudges)}")
            for n in nudges:
                lines.append(f"    → {n.get('note', 'nudged')}")
            lines.append("")
        lines.append("════════════════════════════════════")
        lines.append("    THANK YOU FOR YOUR PATIENCE")
        lines.append("════════════════════════════════════")
        return "\n".join(lines)

    def compose(self) -> ComposeResult:
        with Vertical(id="history-box"):
            yield Label("🧾 Receipt", id="modal-title")
            yield Static(self._build_receipt(), id="receipt-text")
            with Horizontal(id="modal-buttons"):
                yield Button("Copy [c]", variant="primary", id="btn-copy")
                yield Button("Close", variant="default", id="btn-close")

    def action_copy_receipt(self):
        import subprocess
        text = self._build_receipt()
        subprocess.run(["pbcopy"], input=text.encode(), check=True)
        self.notify("📋 Receipt copied to clipboard!")

    def on_button_pressed(self, event: Button.Pressed):
        if event.button.id == "btn-copy":
            self.action_copy_receipt()
        else:
            self.dismiss()

# ── History Screen ─────────────────────────────────────────────────────────────

class HistoryScreen(ModalScreen):
    BINDINGS = [("escape", "dismiss()", "Back"), ("q", "dismiss()", "Back")]

    def __init__(self, history: list):
        super().__init__()
        self.history = history

    def compose(self) -> ComposeResult:
        with Vertical(id="history-box"):
            yield Label("📋 Resolved History", id="modal-title")
            yield DataTable(id="history-table")
            yield Button("Close", variant="default", id="btn-close")

    def on_mount(self):
        table = self.query_one("#history-table", DataTable)
        table.add_columns("Direction", "Who", "What", "Opened", "Resolved", "Days")
        for item in reversed(self.history):
            days = item.get("duration_days", "?")
            direction = "⬅ Waiting for me" if item.get("direction") == "waiting_on_me" else "➡ I waited"
            table.add_row(
                direction,
                item.get("who", ""),
                item.get("what", ""),
                fmt_date(item.get("since", "")),
                fmt_date(item.get("resolved_at", "")),
                str(days),
            )

    def on_button_pressed(self, event: Button.Pressed):
        self.dismiss()

# ── Panel ─────────────────────────────────────────────────────────────────────

class Panel(Vertical):
    def __init__(self, title: str, direction: str, items: list, active: bool = False):
        super().__init__()
        self._title = title
        self.direction = direction
        self._items = list(items)
        self._active = active
        self._cursor = 0
        if active:
            self.add_class("panel-active")

    def compose(self) -> ComposeResult:
        yield Label(self._title, id=f"panel-title-{self.direction}")
        yield ScrollableContainer(id=f"scroll-{self.direction}")

    def on_mount(self):
        self._rebuild()

    def _rebuild(self):
        scroll = self.query_one(f"#scroll-{self.direction}", ScrollableContainer)
        scroll.remove_children()
        if not self._items:
            scroll.mount(Label("  (empty — press [a] to add)", classes="empty-label"))
        else:
            widgets = [
                ItemWidget(item, selected=(i == self._cursor and self._active))
                for i, item in enumerate(self._items)
            ]
            scroll.mount(*widgets)

    def set_active(self, active: bool):
        self._active = active
        if active:
            self.add_class("panel-active")
        else:
            self.remove_class("panel-active")
        self._rebuild()

    def move_cursor(self, delta: int):
        if self._items:
            self._cursor = max(0, min(len(self._items) - 1, self._cursor + delta))
            self._rebuild()

    def current_item(self):
        if self._items and 0 <= self._cursor < len(self._items):
            return self._items[self._cursor], self._cursor
        return None, -1

    def set_items(self, items):
        self._items = list(items)
        if self._cursor >= len(self._items):
            self._cursor = max(0, len(self._items) - 1)
        self._rebuild()

# ── Main App ──────────────────────────────────────────────────────────────────

class WaitingRoomApp(App):

    BINDINGS = [
        Binding("a", "add_item", "Add"),
        Binding("r", "resolve_item", "Resolve"),
        Binding("n", "nudge_item", "Nudge"),
        Binding("h", "show_history", "History"),
        Binding("t", "pick_theme", "Theme"),
        Binding("s", "switch_panel", "Switch", priority=True),
        Binding("left", "switch_panel", "Switch", show=False, priority=True),
        Binding("right", "switch_panel", "Switch", show=False, priority=True),
        Binding("up", "cursor_up", "Up", show=False, priority=True),
        Binding("k", "cursor_up", "Up", show=False, priority=True),
        Binding("down", "cursor_down", "Down", show=False, priority=True),
        Binding("j", "cursor_down", "Down", show=False, priority=True),
        Binding("q", "quit", "Quit", priority=True),
    ]

    TITLE = "🚪 The Waiting Room"

    def __init__(self, theme_name="dark"):
        super().__init__()
        self.data = load_data()
        self._active_panel = "waiting_for"
        self._theme_name = theme_name

    def compose(self) -> ComposeResult:
        yield Header()
        with Horizontal(id="main-layout"):
            yield Panel("➡  I'M WAITING FOR...", "waiting_for", self.data["waiting_for"], active=True)
            yield Panel("⬅  WAITING FOR ME...", "waiting_on_me", self.data["waiting_on_me"], active=False)
        with Horizontal(id="status-bar"):
            yield Label("", id="status-text")
        yield Footer()

    def on_mount(self):
        self.dark = self._theme_name != "light"
        self.update_status()

    def _apply_theme(self, theme_name):
        self._theme_name = theme_name
        config = load_config()
        config["theme"] = theme_name
        save_config(config)
        # Restart the app to apply the new theme cleanly
        self.exit(return_code=42)

    def update_status(self):
        wf = len(self.data["waiting_for"])
        wm = len(self.data["waiting_on_me"])
        resolved = len(self.data["history"])
        oldest = max(
            (age_days(item["since"]) for item in self.data["waiting_for"] + self.data["waiting_on_me"]),
            default=0
        )
        parts = []
        if wf:
            parts.append(f"Waiting on {wf} {'person' if wf == 1 else 'people'}")
        if wm:
            parts.append(f"blocking {wm} {'person' if wm == 1 else 'people'}")
        if oldest:
            parts.append(f"oldest: {oldest}d")
        if resolved:
            parts.append(f"{resolved} resolved")
        text = "  ·  ".join(parts) if parts else "All clear 🎉"
        self.query_one("#status-text", Label).update(text)

    def get_panel(self, direction: str) -> Panel:
        for p in self.query(Panel):
            if p.direction == direction:
                return p
        return None

    def action_switch_panel(self):
        prev = self._active_panel
        self._active_panel = "waiting_on_me" if prev == "waiting_for" else "waiting_for"
        self.get_panel(prev).set_active(False)
        self.get_panel(self._active_panel).set_active(True)

    def action_cursor_up(self):
        self.get_panel(self._active_panel).move_cursor(-1)

    def action_cursor_down(self):
        self.get_panel(self._active_panel).move_cursor(1)

    def action_add_item(self):
        def on_result(item):
            if item:
                self.data[self._active_panel].append(item)
                save_data(self.data)
                self.get_panel(self._active_panel).set_items(self.data[self._active_panel])
                self.update_status()
        self.push_screen(AddItemModal(self._active_panel), on_result)

    def action_resolve_item(self):
        panel = self.get_panel(self._active_panel)
        item, idx = panel.current_item()
        if item is None:
            return

        def on_confirm(confirmed):
            if not confirmed:
                return
            resolved = dict(item)
            resolved["resolved_at"] = datetime.now().isoformat()
            resolved["direction"] = self._active_panel
            resolved["duration_days"] = age_days(item["since"])
            self.data["history"].append(resolved)
            self.data[self._active_panel].pop(idx)
            save_data(self.data)
            panel.set_items(self.data[self._active_panel])
            self.update_status()
            self.push_screen(ReceiptModal(resolved, self._active_panel))

        self.push_screen(
            ConfirmModal(f"Resolve '{item['who']} / {item['what']}'?"),
            on_confirm,
        )

    def action_nudge_item(self):
        panel = self.get_panel(self._active_panel)
        item, idx = panel.current_item()
        if item is None:
            return

        def on_result(note):
            if note:
                self.data[self._active_panel][idx]["nudges"].append({
                    "at": datetime.now().isoformat(),
                    "note": note,
                })
                save_data(self.data)
                panel.set_items(self.data[self._active_panel])
                self.notify(f"📬 Nudge logged for {item['who']}")

        self.push_screen(NudgeModal(item), on_result)

    def action_show_history(self):
        self.push_screen(HistoryScreen(self.data["history"]))

    def action_pick_theme(self):
        def on_result(theme_name):
            if theme_name and theme_name in THEMES:
                self._apply_theme(theme_name)
        self.push_screen(ThemePickerModal(self._theme_name), on_result)

    def action_quit(self):
        self.exit()


def _get_theme_name():
    config = load_config()
    name = config.get("theme", "dark")
    return name if name in THEMES else "dark"

def main():
    while True:
        theme_name = _get_theme_name()
        WaitingRoomApp.CSS = build_css(THEMES[theme_name])
        app = WaitingRoomApp(theme_name=theme_name)
        app.run()
        if app.return_code != 42:
            break

if __name__ == "__main__":
    main()
