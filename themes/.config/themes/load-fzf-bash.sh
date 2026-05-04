#!/usr/bin/env bash
# Source-able from POSIX shells. Sets FZF_DEFAULT_OPTS from the
# current theme so scripts spawned by niri (which inherit a stale
# environment from the session that started the compositor) get the
# right colors.
#
# Usage:
#   source "$HOME/.config/themes/load-fzf-bash.sh"
#
# The fish-syntax fzf theme uses `set -gx VAR "..."` which converts
# directly to `export VAR="..."` with a single sed substitution.

THEME_MODE=$(cat "$HOME/.config/theme_mode" 2>/dev/null || echo dark)
__fzf_theme_file="$HOME/.config/themes/generated/fzf/${THEME_MODE}.theme"
if [ -f "$__fzf_theme_file" ]; then
    eval "$(sed -E 's/^set -gx ([A-Za-z_]+) /export \1=/' "$__fzf_theme_file")"
fi
unset __fzf_theme_file
