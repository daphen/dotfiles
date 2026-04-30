#!/usr/bin/env python3
"""
Waybar center-module daemon. Subscribes to niri's event stream and
prints a fresh JSON line whenever workspace/window state changes — no
polling.

Visualization: per-window bar minimap across every niri workspace.
  █  the focused window
  ▌  the active window of an unfocused workspace
  |  any other window
  ·  placeholder for an empty *focused* workspace
Empty unfocused workspaces are hidden.

Two-tone palette pulled from ~/.config/themes/colors.json:
  semantic.cursor       → focused window (always orange)
  foreground.primary    → other windows on the focused workspace
  foreground.muted      → windows on unfocused workspaces
"""
from __future__ import annotations
import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path

HOME = Path(os.environ["HOME"])
THEME_MODE_FILE = HOME / ".config/theme_mode"
COLORS_FILE = HOME / ".config/themes/colors.json"

RELEVANT_EVENT_RE = re.compile(
    r"^("
    r"Workspaces changed"
    r"|Workspace activated"
    r"|Workspace focused"
    r"|Windows changed"
    r"|Window opened"
    r"|Window closed"
    r"|Window changed"
    r"|Window focus changed"
    r")\b"
)


def read_theme_colors() -> tuple[str, str, str]:
    try:
        mode = THEME_MODE_FILE.read_text().strip() or "dark"
    except OSError:
        mode = "dark"
    try:
        c = json.loads(COLORS_FILE.read_text())
        t = c["themes"].get(mode) or c["themes"]["dark"]
        return (
            t["semantic"]["cursor"],
            t["foreground"]["primary"],
            t["foreground"]["muted"],
        )
    except (OSError, KeyError, json.JSONDecodeError):
        return ("#FF570D", "#EDEDED", "#707B84")


def niri_json(*args: str):
    out = subprocess.run(
        ["niri", "msg", "--json", *args],
        capture_output=True, text=True, timeout=2,
    ).stdout
    return json.loads(out) if out.strip() else None


def window_sort_key(w: dict) -> tuple[int, int, int, int]:
    pos = (w.get("layout") or {}).get("pos_in_scrolling_layout")
    if pos:
        return (0, pos[0], pos[1], w["id"])
    return (1, 0, 0, w["id"])


def render(c_active: str, c_normal: str, c_dim: str) -> str:
    workspaces = niri_json("workspaces") or []
    windows = niri_json("windows") or []
    workspaces_sorted = sorted(
        workspaces, key=lambda w: (w.get("output") or "", w["idx"])
    )

    blocks: list[str] = []
    tooltip_lines: list[str] = []

    for ws in workspaces_sorted:
        ws_windows = sorted(
            [w for w in windows if w.get("workspace_id") == ws["id"]],
            key=window_sort_key,
        )
        count = len(ws_windows)

        if count > 0:
            label = ws.get("name") or f"ws{ws['idx']}"
            tooltip_lines.append(f"{label}: {count} window{'s' if count != 1 else ''}")

        if count == 0:
            if ws.get("is_focused"):
                blocks.append(f"<span color='{c_dim}'>·</span>")
            continue

        parts: list[str] = []
        ws_focused = ws.get("is_focused")
        for w in ws_windows:
            if w.get("is_focused"):
                ch, color = "█", c_active
            elif (not ws_focused) and ws.get("active_window_id") == w["id"]:
                ch, color = "▌", c_normal  # readable even on unfocused ws
            else:
                ch = "|"
                color = c_normal if ws_focused else c_dim
            parts.append(f"<span color='{color}'>{ch}</span>")
        blocks.append("".join(parts))

    text = "  ".join(blocks) if blocks else "·"
    tooltip = "\\n".join(tooltip_lines) or "no windows"
    return json.dumps({"text": text, "tooltip": tooltip, "markup": "pango"})


def emit(line: str) -> None:
    print(line, flush=True)


def daemon() -> int:
    colors = read_theme_colors()
    emit(render(*colors))

    proc = subprocess.Popen(
        ["niri", "msg", "event-stream"],
        stdout=subprocess.PIPE, text=True, bufsize=1,
    )
    assert proc.stdout is not None

    last_render = ""
    last_color_check = 0.0
    for line in proc.stdout:
        if not RELEVANT_EVENT_RE.match(line):
            continue
        # Re-read theme colors at most once per second so a /toggle theme
        # change is reflected without re-stat'ing on every event.
        now = time.time()
        if now - last_color_check > 1.0:
            colors = read_theme_colors()
            last_color_check = now
        out = render(*colors)
        if out != last_render:
            emit(out)
            last_render = out
    return 0


def main() -> int:
    while True:
        try:
            return daemon()
        except Exception as e:
            print(f"niri-minimap daemon error: {e}, reconnecting in 1s…",
                  file=sys.stderr, flush=True)
            time.sleep(1)


if __name__ == "__main__":
    raise SystemExit(main())
