function fish_user_key_bindings
  if functions -q fzf_key_bindings
      fzf_key_bindings
  end

  # Remove default Alt+C binding in both modes
  bind -M insert -e \ec
  bind -M default -e \ec

  # Custom bindings for both insert and normal modes
  # Bindings for CTRL+E
  bind -M insert \ce fzf-cd-widget
  bind -M default \ce fzf-cd-widget

  # Bindings for CTRL+F
  bind -M insert \cf fzf-file-widget
  bind -M default \cf fzf-file-widget

  # Use system clipboard for vi mode yank and paste
  bind -M default y 'commandline | pbcopy'
  bind -M default p 'commandline -i (pbpaste)'
  bind -M visual y 'commandline | pbcopy'
end
