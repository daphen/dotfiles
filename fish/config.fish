if status is-interactive
    # Clean Neovim swap files on shell start
    clean_nvim_swap
  fish_add_path /opt/homebrew/bin $HOME/bin /usr/local/bin
end

if test -f ~/.config/fish/secrets.fish
  source ~/.config/fish/secrets.fish
end


abbr -a vim nvim
abbr -a vi nvim
abbr -a lsa ls -la
abbr -a prd pnpm run dev
abbr -a nrd npm run dev

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

# Set prompt colors
set_color normal;
set -g fish_color_normal "#DDDDED"  
set -g fish_color_command "#FF995D"  
set -g fish_color_param "#D6B9A9"  
set -g fish_color_comment "#698893"  
set -g fish_color_keyword "#698893"
set -g fish_color_option "#E2B8A0"
set -g fish_color_error "#D9AE93"  
set -g fish_color_operator "#FF995D"  
set -g fish_color_escape "#697A86"  
set -g fish_color_cwd "#DAD1CE"  
set -g fish_color_search_match "#403d52"  
set -g fish_color_selection "#524f67"  
set -g fish_color_autosuggestion "#5A5A5A"
set -g fish_color_user "#DDDDED"
set -g fish_color_host "#DAD1CE"
set -g fish_color_match "#403d52"
set -g fish_color_history_current "#FF995D"
set -g fish_color_end "#FF995D"
set -g fish_color_quote "#D6B9A9"
set -g fish_color_redirection "#697A86"
set -g fish_color_cancel "#FE5675"
