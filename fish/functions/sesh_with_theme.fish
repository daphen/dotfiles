function sesh_with_theme --description "Launch sesh with current FZF theme"
    # First, update our local environment from tmux if available
    if test -n "$TMUX"
        # Get the FZF opts from tmux global environment
        set -l tmux_fzf (tmux show-environment -g FZF_DEFAULT_OPTS 2>/dev/null)
        if test -n "$tmux_fzf"
            # Extract the value after the = sign
            set -gx FZF_DEFAULT_OPTS (string replace 'FZF_DEFAULT_OPTS=' '' -- "$tmux_fzf")
        end
    end
    
    # If still no FZF opts or not in tmux, get from system theme
    if test -z "$FZF_DEFAULT_OPTS"
        set -l current_theme (defaults read -g AppleInterfaceStyle 2>/dev/null || echo "Light")
        
        if test "$current_theme" = "Dark"
            set -gx FZF_DEFAULT_OPTS "--color=bg+:#1B1B1B --color=bg:#181818 --color=spinner:#8A9AA6 --color=hl:#FF7B72 --color=fg:#EDEDED --color=header:#FF7B72 --color=info:#8A9AA6 --color=pointer:#FF570D --color=marker:#FF570D --color=fg+:#EDEDED --color=prompt:#8A9AA6 --color=hl+:#FF7B72"
        else
            set -gx FZF_DEFAULT_OPTS "--color=bg+:#FDF6E3 --color=bg:#FDF6E3 --color=spinner:#4A7C59 --color=hl:#ED333B --color=fg:#2D4A3D --color=header:#ED333B --color=info:#4A7C59 --color=pointer:#FF570D --color=marker:#FF570D --color=fg+:#2D4A3D --color=prompt:#4A7C59 --color=hl+:#ED333B"
        end
    end
    
    # Run sesh with the updated environment
    /opt/homebrew/bin/sesh $argv
end
