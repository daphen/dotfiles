# Always set up paths
fish_add_path /opt/homebrew/bin $HOME/bin /usr/local/bin

if status is-interactive
    # Clean Neovim swap files on shell start
    clean_nvim_swap
end

# Always apply themes (for both interactive and non-interactive sessions)
# Load theme from centralized system if available, otherwise fallback to direct detection
if test -f ~/.config/themes/generated/fish/dark.theme -a -f ~/.config/themes/generated/fish/light.theme
    # Use centralized theme system
    set -l system_theme (defaults read -g AppleInterfaceStyle 2>/dev/null; or echo "Light")
    if test "$system_theme" = "Dark"
        source ~/.config/themes/generated/fish/dark.theme
        set -g THEME_MODE "dark"
    else
        source ~/.config/themes/generated/fish/light.theme
        set -g THEME_MODE "light"
    end
else
    # Fallback to manual theme functions
    set -l system_theme (defaults read -g AppleInterfaceStyle 2>/dev/null; or echo "Light")
    if test "$system_theme" = "Dark"
        set_dark_theme
    else
        set_light_theme  
    end
end
set_fzf_colors

# Disabled automatic theme signal handler to prevent crashes
# Use manual theme switching instead: toggle_theme, set_dark_theme, set_light_theme

# Check for theme changes on each prompt
function _check_theme_on_prompt --on-event fish_prompt
    check_theme_change
end

if test -f ~/.config/fish/secrets.fish
  source ~/.config/fish/secrets.fish
end

abbr -a vim nvim
abbr -a vi nvim
abbr -a lsa ls -la
abbr -a prd pnpm run dev
abbr -a nrd npm run dev

# Kanata homerow mods setup
function start_kanata
    launchctl load ~/Library/LaunchAgents/com.kanata.daemon.plist 2>/dev/null
    echo "Kanata started via LaunchAgent"
end

function stop_kanata
    launchctl unload ~/Library/LaunchAgents/com.kanata.daemon.plist 2>/dev/null
    echo "Kanata stopped"
end

function restart_kanata
    launchctl unload ~/Library/LaunchAgents/com.kanata.daemon.plist 2>/dev/null
    sleep 1
    launchctl load ~/Library/LaunchAgents/com.kanata.daemon.plist 2>/dev/null
    echo "Kanata restarted"
end

function kanata_status
    if pgrep -x kanata > /dev/null
        echo "✅ Kanata is running (PID: $(pgrep -x kanata))"
        echo "📝 Recent logs:"
        tail -5 /tmp/kanata.log 2>/dev/null || echo "No logs found"
    else
        echo "❌ Kanata is not running"
    end
end

# Kanata now auto-starts via LaunchAgent

set -g fish_clipboard_copy_cmd pbcopy
set -g fish_clipboard_paste_cmd pbpaste

fish_vi_key_bindings

set -gx EDITOR nvim
set -gx VISUAL nvim

zoxide init fish | source

if type -q fzf
  source /opt/homebrew/opt/fzf/shell/key-bindings.fish
  set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --follow --exclude .git'
  set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
  set -gx FZF_ALT_C_COMMAND 'fd --type d --hidden --follow --exclude .git'
end

