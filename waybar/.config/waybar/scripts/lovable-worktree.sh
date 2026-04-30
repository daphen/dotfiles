#!/usr/bin/env python3
"""
Waybar custom module: shows the active lovable stack name (the
worktree). Hides itself entirely when no lovable-* workspace is the
focused stack.

Daemon mode: subscribes to niri's event stream and re-emits only
when the active stack changes.

The active stack name is read from ~/.local/state/wt-stacks/ws/active
(written by ws-tracker on every workspace-focus event).
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
ACTIVE_FILE = HOME / ".local/state/wt-stacks/ws/active"

RELEVANT_EVENT_RE = re.compile(
    r"^(Workspace focused|Workspaces changed|Workspace activated)\b"
)


def render() -> str:
    try:
        active = ACTIVE_FILE.read_text().strip()
    except OSError:
        active = ""
    if not active or not active.startswith("lovable-") or active == "lovable-deps":
        return json.dumps({"text": "", "class": "empty", "tooltip": ""})
    stack = active.removeprefix("lovable-")
    return json.dumps({
        "text": stack,
        "class": "lovable",
        "tooltip": f"active worktree: {stack}",
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
