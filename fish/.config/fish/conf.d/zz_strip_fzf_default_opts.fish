# FZF colors are delivered via FZF_DEFAULT_OPTS_FILE (file-backed, theme-aware).
# Two cleanups so the theme tracks toggles even from long-lived parent
# processes (kitty/niri) that captured a pre-migration env:
#   1. Unset FZF_DEFAULT_OPTS — when set it overrides the file.
#   2. Re-export FZF_DEFAULT_OPTS_FILE in case the parent's env predates the
#      home-manager sessionVariables change.
set -e FZF_DEFAULT_OPTS
set -gx FZF_DEFAULT_OPTS_FILE "$HOME/.config/fzf/opts.conf"
