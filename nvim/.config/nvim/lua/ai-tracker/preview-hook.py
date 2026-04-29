#!/usr/bin/env python3
"""
PreToolUse hook for ai-tracker.

Intercepts Edit/Write/MultiEdit tool calls from Claude Code, writes the
proposed change to ~/.cache/ai-tracker-pending/requests/, and blocks until
nvim writes a decision file in responses/.

Pass-through (lets Claude's normal permission flow proceed) when:
  - nvim isn't running with the preview module active (no live heartbeat)
  - the tool isn't one we preview
  - the request times out (default 5 min)
  - any unexpected error

Wire up in ~/.claude/settings.json:
  {
    "hooks": {
      "PreToolUse": [
        { "matcher": "Edit|Write|MultiEdit",
          "hooks": [{ "type": "command",
                      "command": "/abs/path/to/preview-hook.py" }] } ]
    }
  }
"""

import json
import os
import sys
import time
import uuid
from pathlib import Path

PREVIEW_TOOLS = {"Edit", "Write", "MultiEdit"}

# Permission modes where we DO want to gate the call. In any other mode
# (acceptEdits, auto, dontAsk, bypassPermissions, plan, ...) the user has
# opted out of prompts, so we passthrough silently.
GATING_MODES = {"default"}

PENDING_DIR = Path.home() / ".cache" / "ai-tracker-pending"
REQUESTS_DIR = PENDING_DIR / "requests"
RESPONSES_DIR = PENDING_DIR / "responses"
HEARTBEAT = PENDING_DIR / ".alive"
DISABLED = PENDING_DIR / ".disabled"

TIMEOUT_SECONDS = 300
HEARTBEAT_STALE_SECONDS = 10
POLL_INTERVAL = 0.1


def passthrough():
    sys.exit(0)


def emit(decision: str, reason: str | None = None):
    out = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": decision,
        }
    }
    if reason:
        out["hookSpecificOutput"]["permissionDecisionReason"] = reason
    print(json.dumps(out))
    sys.exit(0)


def read_heartbeat() -> dict | None:
    """Return parsed heartbeat dict {pid, project_root} or None if dead/missing."""
    if not HEARTBEAT.exists():
        return None
    try:
        st = HEARTBEAT.stat()
    except OSError:
        return None
    if time.time() - st.st_mtime > HEARTBEAT_STALE_SECONDS:
        return None
    try:
        raw = HEARTBEAT.read_text().strip()
    except OSError:
        return None
    # Backward compat: accept plain integer pid as well as JSON.
    try:
        data = json.loads(raw)
    except json.JSONDecodeError:
        try:
            data = {"pid": int(raw), "project_root": None}
        except ValueError:
            return None
    pid = data.get("pid")
    if not isinstance(pid, int):
        return None
    try:
        os.kill(pid, 0)
    except OSError:
        return None
    return data


def path_under(file_path: str, root: str) -> bool:
    try:
        fp = Path(file_path).resolve()
        rp = Path(root).resolve()
    except OSError:
        return False
    try:
        fp.relative_to(rp)
    except ValueError:
        return False
    return True


def write_atomic(path: Path, content: str) -> None:
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(content)
    tmp.replace(path)


def main() -> None:
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, OSError):
        passthrough()

    tool_name = payload.get("tool_name")
    tool_input = payload.get("tool_input", {}) or {}

    if tool_name not in PREVIEW_TOOLS:
        passthrough()
    file_path = tool_input.get("file_path")
    if not file_path:
        passthrough()

    # Auto-skip when the user is in a non-prompting mode.
    permission_mode = payload.get("permission_mode") or "default"
    if permission_mode not in GATING_MODES:
        passthrough()

    heartbeat = read_heartbeat()
    if not heartbeat:
        passthrough()
    if DISABLED.exists():
        passthrough()

    # Project scoping: only intercept edits to files under nvim's project.
    # If nvim has no project root, skip everything (don't ambush user with
    # diffs from other projects on the machine).
    project_root = heartbeat.get("project_root")
    if not project_root:
        passthrough()
    if not path_under(file_path, project_root):
        passthrough()

    REQUESTS_DIR.mkdir(parents=True, exist_ok=True)
    RESPONSES_DIR.mkdir(parents=True, exist_ok=True)

    request_id = str(uuid.uuid4())
    request_path = REQUESTS_DIR / f"{request_id}.json"
    response_path = RESPONSES_DIR / f"{request_id}.json"

    request = {
        "id": request_id,
        "tool_name": tool_name,
        "tool_input": tool_input,
        "session_id": payload.get("session_id"),
        "cwd": payload.get("cwd"),
        "permission_mode": permission_mode,
        "timestamp": time.time(),
    }
    try:
        write_atomic(request_path, json.dumps(request))
    except OSError:
        passthrough()

    deadline = time.time() + TIMEOUT_SECONDS
    while time.time() < deadline:
        if response_path.exists():
            try:
                response = json.loads(response_path.read_text())
            except (json.JSONDecodeError, OSError):
                time.sleep(POLL_INTERVAL)
                continue
            try:
                response_path.unlink()
            except OSError:
                pass
            try:
                request_path.unlink()
            except OSError:
                pass

            decision = response.get("decision")
            if decision == "allow":
                emit("allow")
            elif decision == "deny":
                emit("deny", response.get("reason") or "Rejected via nvim")
            else:
                passthrough()
        time.sleep(POLL_INTERVAL)

    try:
        request_path.unlink()
    except OSError:
        pass
    passthrough()


if __name__ == "__main__":
    try:
        main()
    except Exception:
        passthrough()
