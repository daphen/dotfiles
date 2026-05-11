#!/usr/bin/env bash
# Claude Code Notification hook: replace the generic
# "Claude is waiting for your input" text with a notification that
# names the project/worktree, so multiple concurrent Claude sessions
# are distinguishable in the notification center.
#
# Mechanics:
#   - Claude sends its own default notification regardless — we can't
#     suppress it from the hook. A mako rule (`[app-name=kitty
#     summary="Claude Code"] invisible=1`) hides the default so only
#     our custom one shows.
#   - Our custom notification uses kitty's OSC 99 protocol via
#     `kitten notify --only-print-escape-code`, written directly to
#     /dev/tty so it reaches the kitty instance that fired the hook.
#     Kitty registers a default action that focuses the originating
#     window when invoked via makoctl — which is what the Super+i
#     dispatcher relies on.
#   - We pick a distinct summary ("Claude · <label>") so the mako rule
#     above doesn't accidentally hide our notification too.
#
# Stdin: JSON with at least `cwd`, `message`, optionally `title`.
# Stdout: ignored (Claude only writes hook stdout to debug logs).

input=$(cat)

cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)
message=$(printf '%s' "$input" | jq -r '.message // "Waiting for input"' 2>/dev/null)

# Prefer the worktree-style label (last two path segments — usually
# `<project>-<worktree>` for ws-createwt-spawned dirs) so two
# concurrent worktrees in the same project remain distinguishable.
# Fall back to the directory basename.
if [ -n "$cwd" ]; then
    base=$(basename "$cwd")
    parent=$(basename "$(dirname "$cwd")")
    case "$base" in
        # If we look like `~/work/lovable.daphen-<name>` style
        # already, show just the basename — the parent is noise.
        *daphen-*|*.daphen-*)
            label="$base"
            ;;
        *)
            # Otherwise include the immediate parent for context, but
            # don't if parent is `home`, `~`, or similarly generic.
            case "$parent" in
                home|"$USER"|"~"|/) label="$base" ;;
                *) label="$parent/$base" ;;
            esac
            ;;
    esac
else
    label="$(basename "$PWD" 2>/dev/null || echo claude)"
fi

# Write the OSC sequence to the kitty instance hosting this Claude
# session. Try /dev/tty first (works when Claude Code attaches the
# subprocess to the real tty), then fall back to a guessed slave pty
# under the parent kitty process. If both fail, use notify-send with
# --app-name=kitty so the Super+i dispatcher still routes correctly
# (just without the focus-on-invoke action that kitty's OSC carries).
emit_osc() {
    kitten notify \
        --only-print-escape-code \
        "Claude · $label" \
        "$message" 2>/dev/null
}

if [ -w /dev/tty ]; then
    emit_osc >/dev/tty 2>/dev/null && exit 0
fi

# Fallback: locate the parent kitty process's slave-pty and write
# there. PPID chain → first ancestor whose comm is "kitty".
pid=$PPID
for _ in 1 2 3 4 5 6 7 8 9 10; do
    [ -z "$pid" ] || [ "$pid" -le 1 ] && break
    comm=$(ps -o comm= -p "$pid" 2>/dev/null)
    if [ "$comm" = "kitty" ]; then
        tty=$(readlink "/proc/$pid/fd/0" 2>/dev/null)
        case "$tty" in
            /dev/pts/*)
                if [ -w "$tty" ]; then
                    emit_osc >"$tty" 2>/dev/null && exit 0
                fi
                ;;
        esac
        break
    fi
    pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
done

# Last resort: regular libnotify. Doesn't carry kitty's focus action,
# but Super+i still routes to the kitty case in the dispatcher.
notify-send --app-name=kitty "Claude · $label" "$message" 2>/dev/null || true
