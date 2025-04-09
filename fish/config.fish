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

