if status is-interactive
  fish_add_path /opt/homebrew/bin $HOME/bin /usr/local/bin
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
  set -gx FZF_CTRL_E_COMMAND 'fd --type d --hidden --follow --exclude .git'
end

# Set prompt colors
set_color normal;
set -g fish_color_normal "#DDDDED"  
set -g fish_color_command "#D09D8A"  
set -g fish_color_param "#D6B9A9"  
set -g fish_color_comment "#698893"  
set -g fish_color_error "#D9AE93"  
set -g fish_color_operator "#CE9079"  
set -g fish_color_escape "#697A86"  
set -g fish_color_cwd "#DAD1CE"  
set -g fish_color_search_match "#403d52"  
set -g fish_color_selection "#524f67"  
set -g fish_color_autosuggestion "#5A5A5A"
set -g fish_color_user "#DDDDED"
set -g fish_color_host "#DAD1CE"
set -g fish_color_match "#403d52"
set -g fish_color_history_current "#D09D8A"
set -g fish_color_end "#CE9079"
set -g fish_color_quote "#D6B9A9"
set -g fish_color_redirection "#697A86"
set -g fish_color_cancel "#FE5675"
