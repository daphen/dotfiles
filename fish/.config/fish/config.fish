# Disable default fish greeting
set -g fish_greeting

# Add local bin to PATH for custom scripts
fish_add_path -p ~/.local/bin
# Always set up paths
fish_add_path $HOME/bin

if status is-interactive
    # Keybindings
    bind \e\cr 'reload'  # Alt+Ctrl+R to reload Fish
    bind \cs\ct 'toggle_theme'  # Super+Ctrl+T to toggle theme (if terminal supports it)
    bind \e\ct 'toggle_theme'  # Alt+Ctrl+T as fallback

    # Aliases
    alias r='reload'
    alias rl='reload'
    alias rr='reload_all'
    alias tt='toggle_theme'
end

# Always apply themes (for both interactive and non-interactive sessions)
# Load theme from centralized system if available, otherwise fallback to direct detection
if test -f ~/.config/themes/generated/fish/dark.theme -a -f ~/.config/themes/generated/fish/light.theme
    # Use centralized theme system
    # Check theme from file (created by theme toggle system)
    set -l system_theme "light"
    if test -f ~/.config/theme_mode
        set system_theme (cat ~/.config/theme_mode)
    end

    if test "$system_theme" = "dark"
        source ~/.config/themes/generated/fish/dark.theme
        set -g THEME_MODE "dark"
    else
        source ~/.config/themes/generated/fish/light.theme
        set -g THEME_MODE "light"
    end
else
    # Fallback to manual theme functions
    set -l system_theme "light"
    if test -f ~/.config/theme_mode
        set system_theme (cat ~/.config/theme_mode)
    end

    if test "$system_theme" = "dark"
        set_dark_theme
    else
        set_light_theme
    end
end
set_fzf_colors

# Disabled automatic theme signal handler to prevent crashes
# Use manual theme switching instead: toggle_theme, set_dark_theme, set_light_theme

if test -f ~/.config/fish/secrets.fish
  source ~/.config/fish/secrets.fish
end

abbr -a vim nvim
abbr -a vi nvim
abbr -a lsa ls -la
abbr -a prd pnpm run dev
abbr -a nrd npm run dev

set -g fish_clipboard_copy_cmd wl-copy
set -g fish_clipboard_paste_cmd wl-paste

fish_vi_key_bindings

set -gx EDITOR nvim
set -gx VISUAL nvim

if command -v zoxide >/dev/null 2>&1
    zoxide init fish | source
end

if type -q fzf
  # FZF key bindings (using fzf --fish for modern setup)
  fzf --fish | source
  set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --follow --exclude .git'
  set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
  set -gx FZF_ALT_C_COMMAND 'fd --type d --hidden --follow --exclude .git'
end


nvm use system >/dev/null 2>&1
# oc function defined in ~/.config/fish/functions/oc.fish (uses Max subscription)

# Show system info with fastfetch only when SHOW_FASTFETCH env var is set
# This is triggered by Super+Shift+D in niri (spawns kitty with --env SHOW_FASTFETCH=1)
if status is-interactive; and test -n "$SHOW_FASTFETCH"
    sleep 0.1; fastfetch
end

alias drag='dragon-drop -x -T -i -s 48'
set -gx GTK_THEME Adwaita:dark
