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

Color palette: bars used to sit directly on the wallpaper (always
dark for our setup), but the new notch waybar theme has a solid
*light-mode* background in light mode. So we now pick the palette
block matching the active theme mode (read from
~/.config/themes/.current-theme), which gives high-contrast bars
against whatever surface the minimap currently sits on. Active
focus colour stays semantic.cursor (orange) in both modes — it's
the only colour cue that should pop, so we want it consistent.

  semantic.cursor       → focused window (orange, both modes)
  foreground.primary    → every other window — mode-dependent: light
                          (#EDEDED-ish) in dark mode, dark
                          (#2D4A3D-ish) in light mode
"""
from __future__ import annotations
import json
import os
import re
import subprocess
import sys
import select
import signal
import time
from pathlib import Path

HOME = Path(os.environ["HOME"])
COLORS_FILE = HOME / ".config/themes/colors.json"
CURRENT_THEME_FILE = HOME / ".config/theme_mode"
ACTIVE_FILE = HOME / ".local/state/wt-stacks/ws/active"

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


def current_theme_mode() -> str:
    """Read the active theme mode from theme-manager's state file.
    Defaults to "dark" if missing or unreadable."""
    try:
        m = CURRENT_THEME_FILE.read_text().strip()
        return m if m in ("dark", "light") else "dark"
    except OSError:
        return "dark"


def read_theme_colors() -> tuple[str, str]:
    """Pull (active, normal) bar colours from the palette block that
    matches the active theme mode. Active stays semantic.cursor
    (orange) in both modes; normal flips light → dark when the system
    switches to light mode so bars stay visible on the light notch."""
    mode = current_theme_mode()
    try:
        c = json.loads(COLORS_FILE.read_text())["themes"][mode]
        return (c["semantic"]["cursor"], c["foreground"]["primary"])
    except (OSError, KeyError, json.JSONDecodeError):
        # Fallbacks: dark mode → light text, light mode → dark text.
        return ("#FF570D", "#EDEDED" if mode == "dark" else "#2D4A3D")


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


def is_hidden_workspace(ws: dict, active: str | None) -> bool:
    """Workspaces that should be filtered out of the minimap row.
    Mirrors ws-focus-workspace-up's filter exactly: any `lovable-*`
    other than the currently-active stack is hidden. That includes
    `lovable-main`, which is only reachable via Super+Ctrl+M from
    within an active worktree — not via Super+J/K — so showing it
    in the minimap was misleading.
    """
    name = ws.get("name") or ""
    if not name.startswith("lovable-"):
        return False
    if name in ("lovable", "lovable-deps"):
        return False
    return name != active


def read_active_stack() -> str | None:
    try:
        return ACTIVE_FILE.read_text().strip() or None
    except OSError:
        return None


def render(c_active: str, c_normal: str) -> str:
    workspaces = niri_json("workspaces") or []
    windows = niri_json("windows") or []
    active_stack = read_active_stack()
    # Hide inactive lovable-<name> workspaces from the minimap so the
    # row only shows the workspaces the user can actually navigate to
    # via Super+J/K (which already filters them) plus normal workspaces.
    workspaces_sorted = sorted(
        [w for w in workspaces if not is_hidden_workspace(w, active_stack)],
        key=lambda w: (w.get("output") or "", w["idx"]),
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
        # extra height extends DOWNWARD past them — i.e. all bars are
        # top-anchored, focused bars extend further DOWN. Sizes are a
        # middle ground between the original 28/22/12 (too tall) and
        # the 20/16/10 first-pass shrink (too small).
        parts: list[str] = []
        ws_focused = ws.get("is_focused")
        for w in ws_windows:
            if w.get("is_focused"):
                size, rise, color = "24000", "-10000", c_active
            elif (not ws_focused) and ws.get("active_window_id") == w["id"]:
                size, rise, color = "18000", "-5000", c_normal
            else:
                size, rise, color = "11000", "0", c_normal
            parts.append(
                f"<span size='{size}' rise='{rise}' color='{color}'>|</span>"
            )
        blocks.append("".join(parts))

    body = " ".join(blocks) if blocks else "·"
    # Invisible anchor pins the line height to the tallest bar so the
    # container doesn't shrink when no focused bar is being rendered.
    anchor = "<span size='24000' rise='-10000'>​</span>"
    text = anchor + body
    tooltip = "\\n".join(tooltip_lines) or "no windows"
    return json.dumps({"text": text, "tooltip": tooltip, "markup": "pango"})


def emit(line: str) -> None:
    print(line, flush=True)


def daemon() -> int:
    # Re-read the palette every render so theme-manager dark↔light
    # toggles propagate without restarting the daemon. The .current-theme
    # file is tiny and cached by the kernel; reading it per event is
    # essentially free.
    colors = read_theme_colors()
    last_render = render(*colors)
    emit(last_render)

    # SIGUSR1 → write a byte to a pipe → wakes select() so we re-render.
    # Used by niri keybinds for layout actions that don't emit events
    # (move-column-left/right, move-window-up/down, etc.) and by
    # theme-manager after a mode toggle so colours update instantly.
    sig_r, sig_w = os.pipe()
    os.set_blocking(sig_r, False)
    os.set_blocking(sig_w, False)
    def _on_sigusr1(signum, frame):
        try: os.write(sig_w, b".")
        except OSError: pass
    signal.signal(signal.SIGUSR1, _on_sigusr1)

    proc = subprocess.Popen(
        ["niri", "msg", "event-stream"],
        stdout=subprocess.PIPE, text=True, bufsize=1,
    )
    assert proc.stdout is not None
    nstdout = proc.stdout

    def maybe_emit():
        nonlocal last_render
        out = render(*read_theme_colors())
        if out != last_render:
            emit(out)
            last_render = out

    while True:
        ready, _, _ = select.select([nstdout, sig_r], [], [])
        if sig_r in ready:
            try: os.read(sig_r, 4096)
            except BlockingIOError: pass
            maybe_emit()
        if nstdout in ready:
            line = nstdout.readline()
            if not line:
                return 0  # niri closed, let supervisor reconnect
            if RELEVANT_EVENT_RE.match(line):
                maybe_emit()


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
