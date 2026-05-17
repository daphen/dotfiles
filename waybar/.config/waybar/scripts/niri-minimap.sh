#!/usr/bin/env python3
"""
Waybar center-module daemon. Subscribes to niri's JSON event stream
and prints a fresh JSON line whenever workspace/window state changes —
no polling, no subprocess calls in the render path.

Visualization: per-window bar minimap across every niri workspace.
  █  the focused window
  ▌  the active window of an unfocused workspace
  |  any other window
  ·  placeholder for an empty *focused* workspace
Empty unfocused workspaces are hidden.

Color palette: bars used to sit directly on the wallpaper (always
dark for our setup), but the new notch waybar theme has a solid
*light-mode* background in light mode. So we pick the palette block
matching the active theme mode (read from ~/.config/theme_mode),
giving high-contrast bars against whatever surface the minimap
currently sits on. Active focus colour stays semantic.cursor
(orange) in both modes — it's the only colour cue that should pop.

  semantic.cursor       → focused window (orange, both modes)
  foreground.primary    → every other window — mode-dependent: light
                          (#EDEDED-ish) in dark mode, dark
                          (#2D4A3D-ish) in light mode

Architecture: niri's JSON event stream sends `WorkspacesChanged` and
`WindowsChanged` as the FIRST two events on every new connection
(full snapshots), then delta events for individual changes. We mirror
the state in two dicts and update on each delta — no `niri msg`
subprocess invocations per render. Result: render path is pure
in-memory dict walks, sub-millisecond, indistinguishable from niri's
own focus-border switch.
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
        return ("#FF570D", "#EDEDED" if mode == "dark" else "#2D4A3D")


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


def render(workspaces: dict, windows: dict,
           c_active: str, c_normal: str) -> str:
    """Build the waybar JSON line from in-memory state. No I/O on the
    hot path — just dict iteration + string assembly."""
    active_stack = read_active_stack()
    workspaces_sorted = sorted(
        [w for w in workspaces.values()
         if not is_hidden_workspace(w, active_stack)],
        key=lambda w: (w.get("output") or "", w["idx"]),
    )

    # Group windows by workspace_id once.
    windows_by_ws: dict[int, list[dict]] = {}
    for w in windows.values():
        windows_by_ws.setdefault(w.get("workspace_id"), []).append(w)

    blocks: list[str] = []
    tooltip_lines: list[str] = []

    for ws in workspaces_sorted:
        ws_windows = sorted(windows_by_ws.get(ws["id"], []), key=window_sort_key)
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
        # extra height extends DOWNWARD past them — i.e. all bars
        # are top-anchored, focused bars extend further DOWN.
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


# Events that should provoke a re-render after state update. Anything
# else (keyboard layout, casts, overview state) is irrelevant to the
# minimap.
RELEVANT_EVENTS = frozenset({
    "WorkspacesChanged",
    "WindowsChanged",
    "WorkspaceActivated",
    "WorkspaceActiveWindowChanged",
    "WindowOpenedOrChanged",
    "WindowClosed",
    "WindowFocusChanged",
    "WindowLayoutsChanged",
})


def apply_event(name: str, data: dict,
                workspaces: dict, windows: dict) -> None:
    """Mutate the in-memory state caches in response to one niri event.
    Field names below are exactly what niri emits in its JSON event
    schema."""
    if name == "WorkspacesChanged":
        workspaces.clear()
        for w in data.get("workspaces", []):
            workspaces[w["id"]] = w

    elif name == "WindowsChanged":
        windows.clear()
        for w in data.get("windows", []):
            windows[w["id"]] = w

    elif name == "WorkspaceActivated":
        ws_id = data.get("id")
        focused = data.get("focused", False)
        target = workspaces.get(ws_id)
        if target is None:
            return
        target_output = target.get("output")
        # Within an output: only the activated workspace is `is_active`.
        # Globally: if `focused` is true, this workspace becomes the
        # focused one; all others lose is_focused.
        for w in workspaces.values():
            if w.get("output") == target_output:
                w["is_active"] = (w["id"] == ws_id)
            if focused:
                w["is_focused"] = (w["id"] == ws_id)

    elif name == "WorkspaceActiveWindowChanged":
        ws_id = data.get("workspace_id")
        if ws_id in workspaces:
            workspaces[ws_id]["active_window_id"] = data.get("active_window_id")

    elif name == "WindowOpenedOrChanged":
        w = data.get("window")
        if not w:
            return
        windows[w["id"]] = w
        # If this window is now focused, propagate to others.
        if w.get("is_focused"):
            for other in windows.values():
                if other["id"] != w["id"]:
                    other["is_focused"] = False

    elif name == "WindowClosed":
        wid = data.get("id")
        windows.pop(wid, None)

    elif name == "WindowFocusChanged":
        focused_id = data.get("id")
        for w in windows.values():
            w["is_focused"] = (w["id"] == focused_id)

    elif name == "WindowLayoutsChanged":
        # niri emits `WindowLayoutsChanged` with a `changes` list of
        # [id, layout] pairs when scrolling / resizing reflows tiles.
        # Layout drives `pos_in_scrolling_layout` which the sort uses.
        for change in data.get("changes", []) or []:
            try:
                wid, layout = change[0], change[1]
            except (KeyError, IndexError, TypeError):
                continue
            w = windows.get(wid)
            if w is not None:
                w["layout"] = layout


def emit(line: str) -> None:
    print(line, flush=True)


def daemon() -> int:
    workspaces: dict = {}
    windows: dict = {}

    # SIGUSR1 → write a byte to a pipe → wakes select() so we
    # re-render. Used by niri keybinds for layout actions that don't
    # emit events (move-column-left/right, move-window-up/down) and by
    # theme-manager after a mode toggle so colours update instantly.
    sig_r, sig_w = os.pipe()
    os.set_blocking(sig_r, False)
    os.set_blocking(sig_w, False)
    def _on_sigusr1(signum, frame):
        try: os.write(sig_w, b".")
        except OSError: pass
    signal.signal(signal.SIGUSR1, _on_sigusr1)

    proc = subprocess.Popen(
        ["niri", "msg", "--json", "event-stream"],
        stdout=subprocess.PIPE, text=True, bufsize=1,
    )
    assert proc.stdout is not None
    nstdout = proc.stdout

    last_render = ""

    def maybe_emit():
        nonlocal last_render
        out = render(workspaces, windows, *read_theme_colors())
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
            line = line.strip()
            if not line:
                continue
            try:
                event = json.loads(line)
            except json.JSONDecodeError:
                continue
            # niri events are single-key dicts: {"EventName": {data}}
            if not isinstance(event, dict) or len(event) != 1:
                continue
            name, data = next(iter(event.items()))
            if not isinstance(data, dict):
                continue
            apply_event(name, data, workspaces, windows)
            if name in RELEVANT_EVENTS:
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
