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

Color palette: bars sit directly on the (dark) wallpaper, so colors
are always pulled from the *dark* theme block of colors.json,
regardless of which theme mode is active. Falls back to hardcoded
defaults if the file is missing.
  semantic.cursor       → focused window (orange)
  foreground.primary    → every other window (light, same on focused
                          and unfocused workspaces alike)
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


def read_theme_colors() -> tuple[str, str]:
    """Always returns the dark-mode palette so bars stay readable on
    the wallpaper regardless of active theme."""
    try:
        c = json.loads(COLORS_FILE.read_text())["themes"]["dark"]
        return (c["semantic"]["cursor"], c["foreground"]["primary"])
    except (OSError, KeyError, json.JSONDecodeError):
        return ("#FF570D", "#EDEDED")


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


def render(c_active: str, c_normal: str) -> str:
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
                blocks.append(f"<span color='{c_normal}'>·</span>")
            continue

        # All bars use the same | glyph; font_size varies per state
        # so heights differ. A negative `rise` lowers the larger
        # glyphs so their TOPS align with the inactive bars and the
        # extra height extends DOWNWARD past them.
        parts: list[str] = []
        ws_focused = ws.get("is_focused")
        for w in ws_windows:
            if w.get("is_focused"):
                size, rise, color = "16000", "-4000", c_active
            elif (not ws_focused) and ws.get("active_window_id") == w["id"]:
                size, rise, color = "13000", "-2000", c_normal
            else:
                size, rise, color = "9000", "0", c_normal
            parts.append(
                f"<span size='{size}' rise='{rise}' color='{color}'>|</span>"
            )
        blocks.append("".join(parts))

    # Single regular space between workspaces. Tighter values
    # (U+200A hair, U+2009 thin) overlapped or ran characters into each
    # other given the negative letter_spacing applied within blocks.
    # When focused on a lovable-<name> workspace, prefix the bar
    # row with the worktree name in light text. Otherwise the
    # minimap is just bars.
    focused = next((w for w in workspaces_sorted if w.get("is_focused")), None)
    label_prefix = ""
    if focused:
        n = focused.get("name") or ""
        if n.startswith("lovable-") and n not in ("lovable", "lovable-deps"):
            stack = n.removeprefix("lovable-")
            label_prefix = f"<span color='{c_normal}'>{stack}</span>  "

    text = label_prefix + (" ".join(blocks) if blocks else "·")
    tooltip = "\\n".join(tooltip_lines) or "no windows"
    return json.dumps({"text": text, "tooltip": tooltip, "markup": "pango"})


def emit(line: str) -> None:
    print(line, flush=True)


def daemon() -> int:
    # Bar colors are locked to dark-mode and don't follow theme switches,
    # so we read them once at startup.
    colors = read_theme_colors()
    last_render = render(*colors)
    emit(last_render)

    proc = subprocess.Popen(
        ["niri", "msg", "event-stream"],
        stdout=subprocess.PIPE, text=True, bufsize=1,
    )
    assert proc.stdout is not None

    for line in proc.stdout:
        if not RELEVANT_EVENT_RE.match(line):
            continue
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
