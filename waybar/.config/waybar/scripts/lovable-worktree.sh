#!/usr/bin/env python3
"""
Waybar custom module: shows the worktree name when the CURRENTLY
focused workspace is a lovable-<name> stack. Hides itself any time
the user is not on a lovable stack workspace.

Daemon mode: subscribes to niri's event stream, re-emits only when
the visible state would change.
"""
from __future__ import annotations
import json
import os
import re
import subprocess
import sys
import time

RELEVANT_EVENT_RE = re.compile(
    r"^(Workspace focused|Workspaces changed|Workspace activated)\b"
)


def niri_json(*args: str):
    out = subprocess.run(
        ["niri", "msg", "--json", *args],
        capture_output=True, text=True, timeout=2,
    ).stdout
    return json.loads(out) if out.strip() else None


def render() -> str:
    workspaces = niri_json("workspaces") or []
    fw = next((w for w in workspaces if w.get("is_focused")), None)
    fname = (fw.get("name") if fw else "") or ""
    if (not fname.startswith("lovable-")) or fname in ("lovable", "lovable-deps"):
        return json.dumps({"text": "", "class": "empty", "tooltip": ""})
    stack_name = fname.removeprefix("lovable-")

    # Just the worktree name — the dot row was dropped because
    # ws-reorder pins the active workspace at the bottom of the
    # lovable group, so the active dot kept moving in the row
    # instead of tracking visual order. Use Super+T to switch.
    other = sorted(
        (w.get("name") or "").removeprefix("lovable-")
        for w in workspaces
        if (w.get("name") or "").startswith("lovable-")
        and w.get("name") not in ("lovable", "lovable-deps")
        and not w.get("is_focused")
    )
    tooltip_lines = [f"focused worktree: {stack_name}"]
    if other:
        tooltip_lines.append("other: " + ", ".join(other))
    return json.dumps({
        "text": stack_name,
        "class": "lovable",
        "tooltip": "\\n".join(tooltip_lines),
    })


def emit(line: str) -> None:
    print(line, flush=True)


def daemon() -> int:
    last = render()
    emit(last)
    proc = subprocess.Popen(
        ["niri", "msg", "event-stream"],
        stdout=subprocess.PIPE, text=True, bufsize=1,
    )
    assert proc.stdout is not None
    for line in proc.stdout:
        if not RELEVANT_EVENT_RE.match(line):
            continue
        out = render()
        if out != last:
            emit(out)
            last = out
    return 0


def main() -> int:
    while True:
        try:
            return daemon()
        except Exception as e:
            print(f"lovable-worktree daemon error: {e}, reconnecting in 1s…",
                  file=sys.stderr, flush=True)
            time.sleep(1)


if __name__ == "__main__":
    raise SystemExit(main())
