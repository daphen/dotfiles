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
import subprocess
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
REQUESTS_ROOT = PENDING_DIR / "requests"
RESPONSES_DIR = PENDING_DIR / "responses"
HEARTBEATS_DIR = PENDING_DIR / "heartbeats"
SESSIONS_DIR = PENDING_DIR / "claude-sessions"
DISABLED = PENDING_DIR / ".disabled"
PAUSED = PENDING_DIR / ".paused"

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


def read_ppid(pid: int) -> int | None:
    try:
        with open(f"/proc/{pid}/status") as f:
            for line in f:
                if line.startswith("PPid:"):
                    return int(line.split()[1])
    except (OSError, ValueError):
        pass
    return None


def niri_windows() -> list | None:
    """Return niri's window list, or None if niri isn't running / fails."""
    try:
        result = subprocess.run(
            ["niri", "msg", "--json", "windows"],
            capture_output=True, text=True, timeout=2, check=False,
        )
    except (FileNotFoundError, subprocess.TimeoutExpired, OSError):
        return None
    if result.returncode != 0 or not result.stdout:
        return None
    try:
        data = json.loads(result.stdout)
    except json.JSONDecodeError:
        return None
    return data if isinstance(data, list) else None


def kitty_window_for_pid_chain(pid: int) -> int | None:
    """Walk up the process tree from pid; return the kitty window id whose
    foreground process matches an ancestor pid. Returns None if kitten isn't
    available or no match found."""
    try:
        result = subprocess.run(
            ["kitten", "@", "ls"],
            capture_output=True, text=True, timeout=2, check=False,
        )
    except (FileNotFoundError, subprocess.TimeoutExpired, OSError):
        return None
    if result.returncode != 0 or not result.stdout:
        return None
    try:
        data = json.loads(result.stdout)
    except json.JSONDecodeError:
        return None
    if not isinstance(data, list):
        return None

    # Build set of ancestor pids
    ancestors = set()
    cur = pid
    depth = 0
    while cur and cur != 1 and depth < 50:
        ancestors.add(cur)
        cur = read_ppid(cur)
        depth += 1

    for ow in data:
        for tab in ow.get("tabs", []):
            for win in tab.get("windows", []):
                for proc in win.get("foreground_processes", []):
                    if proc.get("pid") in ancestors:
                        return win.get("id")
    return None


def record_claude_session(claude_pid: int, claude_ws: int | None) -> None:
    """Write a session record so nvim can address Claude directly without
    fragile process-name matching. Keyed by niri workspace (or 'default')."""
    try:
        SESSIONS_DIR.mkdir(parents=True, exist_ok=True)
    except OSError:
        return
    record = {
        "pid": claude_pid,
        "niri_workspace_id": claude_ws,
        "kitty_window_id": kitty_window_for_pid_chain(claude_pid),
        "timestamp": time.time(),
    }
    key = str(claude_ws) if claude_ws is not None else "default"
    path = SESSIONS_DIR / f"{key}.json"
    tmp = path.with_suffix(".json.tmp")
    try:
        tmp.write_text(json.dumps(record))
        tmp.replace(path)
    except OSError:
        pass


def find_workspace_for_pid_chain(pid: int, windows: list) -> int | None:
    """Walk up the process tree from pid; return the niri workspace_id of the
    first ancestor that has a niri window."""
    pid_to_ws = {w.get("pid"): w.get("workspace_id") for w in windows
                 if w.get("pid") is not None and w.get("workspace_id") is not None}
    current = pid
    depth = 0
    while current and current != 1 and depth < 50:
        if current in pid_to_ws:
            return pid_to_ws[current]
        current = read_ppid(current)
        depth += 1
    return None


def git_common_dir_for(path: str) -> str | None:
    """Return absolute git common dir for path, or None if not in a repo."""
    p = Path(path)
    d = p.parent if p.is_file() else p
    try:
        result = subprocess.run(
            ["git", "-C", str(d), "rev-parse", "--git-common-dir"],
            capture_output=True, text=True, timeout=2, check=False,
        )
    except (FileNotFoundError, subprocess.TimeoutExpired, OSError):
        return None
    if result.returncode != 0 or not result.stdout:
        return None
    common = result.stdout.strip()
    cp = Path(common)
    if not cp.is_absolute():
        cp = Path(d, common)
    try:
        return str(cp.resolve())
    except OSError:
        return None


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


def find_target_nvim(file_path: str) -> int | None:
    """Scan all heartbeats; return the pid of an nvim whose project contains
    file_path AND whose niri workspace matches Claude's. Falls back to
    project-only matching if niri isn't available. Cleans up stale heartbeats
    opportunistically."""
    if not HEARTBEATS_DIR.exists():
        return None

    # Resolve Claude's niri workspace once. If niri isn't running, this
    # stays None and we skip the workspace filter entirely.
    windows = niri_windows()
    claude_ws = None
    if windows:
        claude_ws = find_workspace_for_pid_chain(os.getppid(), windows)

    prefix_candidates = []
    repo_candidates = []  # nvims in same git repo, no path prefix match
    file_common_dir = None  # lazy

    for hb in HEARTBEATS_DIR.iterdir():
        if hb.suffix != ".json":
            continue
        try:
            st = hb.stat()
        except OSError:
            continue
        if time.time() - st.st_mtime > HEARTBEAT_STALE_SECONDS:
            try:
                hb.unlink()
            except OSError:
                pass
            continue
        try:
            data = json.loads(hb.read_text())
        except (json.JSONDecodeError, OSError):
            continue
        pid = data.get("pid")
        if not isinstance(pid, int):
            continue
        try:
            os.kill(pid, 0)
        except OSError:
            try:
                hb.unlink()
            except OSError:
                pass
            continue

        # Workspace filter — applied to both prefix and repo candidates.
        nvim_ws = data.get("niri_workspace_id")
        if claude_ws is not None and nvim_ws is not None and claude_ws != nvim_ws:
            continue

        project_root = data.get("project_root")
        if project_root and path_under(file_path, project_root):
            prefix_candidates.append((pid, project_root, nvim_ws))
            continue

        # Same-repo fallback: nvim is in some other worktree of the repo
        # the file lives in. Useful when only one worktree's nvim is open.
        nvim_common = data.get("git_common_dir")
        if nvim_common:
            if file_common_dir is None:
                file_common_dir = git_common_dir_for(file_path) or ""
            if file_common_dir and file_common_dir == nvim_common:
                repo_candidates.append((pid, project_root or "", nvim_ws))

    def rank(c):
        pid, root, nvim_ws = c
        ws_match = 1 if (claude_ws is not None and nvim_ws == claude_ws) else 0
        return (ws_match, len(root))

    if prefix_candidates:
        prefix_candidates.sort(key=rank, reverse=True)
        return prefix_candidates[0][0]
    if repo_candidates:
        repo_candidates.sort(key=rank, reverse=True)
        return repo_candidates[0][0]
    return None


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

    # Pause wins over everything: even in auto mode, deny edits while paused.
    # (The settings.json matcher scopes the hook to Edit/Write/MultiEdit, so
    # reads/Bash continue to flow.)
    if PAUSED.exists():
        emit("deny", "Edits paused via nvim (toggle off with <C-g><leader>)")

    if tool_name not in PREVIEW_TOOLS:
        passthrough()
    file_path = tool_input.get("file_path")
    if not file_path:
        passthrough()

    # Auto-skip when the user is in a non-prompting mode.
    permission_mode = payload.get("permission_mode") or "default"
    if permission_mode not in GATING_MODES:
        passthrough()

    if DISABLED.exists():
        passthrough()

    # Resolve Claude's niri workspace once. Used both for routing and for
    # the session record below.
    _windows = niri_windows()
    claude_ws = find_workspace_for_pid_chain(os.getppid(), _windows) if _windows else None

    # Record this Claude session so nvim's ask-Claude feature can address
    # this exact instance instead of guessing by scanning kitty windows.
    # Done before routing so even passthrough cases populate the registry.
    record_claude_session(os.getppid(), claude_ws)

    # Find a live nvim whose project_root contains this file.
    target_pid = find_target_nvim(file_path)
    if not target_pid:
        passthrough()

    target_inbox = REQUESTS_ROOT / str(target_pid)
    target_inbox.mkdir(parents=True, exist_ok=True)
    RESPONSES_DIR.mkdir(parents=True, exist_ok=True)

    request_id = str(uuid.uuid4())
    request_path = target_inbox / f"{request_id}.json"
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
