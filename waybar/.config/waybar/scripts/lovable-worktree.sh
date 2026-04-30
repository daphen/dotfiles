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


def stack_workspaces(workspaces: list[dict]) -> list[dict]:
    """Stack workspaces only — `lovable-<name>` excluding the legacy
    `lovable` and `lovable-deps`. Sorted by output then idx so the
    visual order matches the workspace stack."""
    out = [
        w for w in workspaces
        if (w.get("name") or "").startswith("lovable-")
        and w.get("name") not in ("lovable", "lovable-deps")
    ]
    out.sort(key=lambda w: (w.get("output") or "", w.get("idx") or 0))
    return out


def render() -> str:
    workspaces = niri_json("workspaces") or []
    fw = next((w for w in workspaces if w.get("is_focused")), None)
    fname = (fw.get("name") if fw else "") or ""
    if (not fname.startswith("lovable-")) or fname in ("lovable", "lovable-deps"):
        return json.dumps({"text": "", "class": "empty", "tooltip": ""})
    stack_name = fname.removeprefix("lovable-")

    # Dot row: one per stack workspace, filled = focused. Spacing is a
    # thin space (U+2009) so dots feel like a unit.
    dots: list[str] = []
    for w in stack_workspaces(workspaces):
        dots.append("●" if w.get("is_focused") else "○")
    dot_row = " ".join(dots)

    text = f"{stack_name}  {dot_row}" if dot_row else stack_name
    tooltip_lines = [f"focused worktree: {stack_name}"]
    other = [
        (w.get("name") or "").removeprefix("lovable-")
        for w in stack_workspaces(workspaces)
        if not w.get("is_focused")
    ]
    if other:
        tooltip_lines.append("inactive: " + ", ".join(other))
    return json.dumps({
        "text": text,
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
