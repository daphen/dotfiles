
function set_light_theme --description "Set light theme"
  # Store current theme mode
  set -g THEME_MODE "light"

  # Load colors from generated theme file
  set -l theme_file ~/.config/themes/generated/fish/light.theme
  if test -f $theme_file
      source $theme_file
  else
      # Fallback to hardcoded colors if theme file doesn't exist
      set -g fish_color_normal 2D4A3D
      set -g fish_color_command 286983
      set -g fish_color_keyword d7827e
      set -g fish_color_quote 56949f
      set -g fish_color_redirection B8713A
      set -g fish_color_end 56949f
      set -g fish_color_error b4637a
      set -g fish_color_param 2D4A3D
      set -g fish_color_comment 9893a5
      set -g fish_color_selection --background=f4eeee
      set -g fish_color_search_match --background=f4eeee
      set -g fish_color_operator 56949f
      set -g fish_color_escape B8713A
      set -g fish_color_autosuggestion 9893a5

      # Set pager colors
      set -g fish_pager_color_progress 9893a5
      set -g fish_pager_color_prefix 56949f
      set -g fish_pager_color_completion 2D4A3D
      set -g fish_pager_color_description 9893a5
      set -g fish_pager_color_selected_background --background=f4eeee
  end

  # Update FZF colors
  set_fzf_colors

  # Refresh tmux if running
  if tmux info &> /dev/null
    tmux source-file ~/.config/tmux/tmux.conf >/dev/null 2>&1
  end

  echo "☀️ Switched to light theme"
end
