
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

  # Update Tide prompt colors
  set -l tide_theme_file ~/.config/themes/generated/tide/light.theme
  if test -f $tide_theme_file
      # Execute each line to ensure universal variables are updated
      for line in (cat $tide_theme_file | grep "^set -U")
          eval $line
      end
  end


  # Force Tide to reload with new colors
  # Clear tide prompt cache to force regeneration
  set -e _tide_prompt_cache
  set -e _tide_right_prompt_cache
  
  # If tide reload exists, use it
  if type -q tide
      tide reload >/dev/null 2>&1 || true
  end
  
  # Force prompt redraw
  commandline -f repaint

  # Set system theme preference for GTK apps and browsers
  # Update GTK 3.0 settings
  if test -f ~/.config/gtk-3.0/settings.ini
      if grep -q "gtk-application-prefer-dark-theme" ~/.config/gtk-3.0/settings.ini
          sed -i 's/^gtk-application-prefer-dark-theme=.*/gtk-application-prefer-dark-theme=0/' ~/.config/gtk-3.0/settings.ini
      else
          sed -i '/\[Settings\]/a gtk-application-prefer-dark-theme=0' ~/.config/gtk-3.0/settings.ini
      end
  end

  # Update GTK 4.0 settings
  if test -f ~/.config/gtk-4.0/settings.ini
      if grep -q "gtk-application-prefer-dark-theme" ~/.config/gtk-4.0/settings.ini
          sed -i 's/^gtk-application-prefer-dark-theme=.*/gtk-application-prefer-dark-theme=0/' ~/.config/gtk-4.0/settings.ini
      else
          sed -i '/\[Settings\]/a gtk-application-prefer-dark-theme=0' ~/.config/gtk-4.0/settings.ini
      end
  end

  # Set color scheme via gsettings if available (for portals)
  if command -v gsettings >/dev/null 2>&1
      gsettings set org.gnome.desktop.interface color-scheme 'prefer-light' 2>/dev/null || true
      # Restart xdg-desktop-portal to pick up the new setting (non-blocking)
      systemctl --user restart xdg-desktop-portal.service 2>/dev/null &
  end

  # Update Mako notification daemon
  set -l mako_theme ~/.config/themes/generated/mako/light.theme
  if test -f $mako_theme
      cp $mako_theme ~/.config/mako/config
      if pgrep -x mako >/dev/null 2>&1
          makoctl reload 2>/dev/null &
      end
  end

  # Update Waybar
  set -l waybar_theme ~/.config/themes/generated/waybar/light.theme
  if test -f $waybar_theme
      cp $waybar_theme ~/.config/waybar/style.css
      if pgrep -x waybar >/dev/null 2>&1
          killall -SIGUSR2 waybar 2>/dev/null &
      end
  end

  # Update spotify-player (restart to apply theme)
  set -l spotify_theme ~/.config/themes/generated/spotify-player/light.theme
  if test -f $spotify_theme
      cp $spotify_theme ~/.config/spotify-player/theme.toml
      # Restart if running
      if pgrep -x spotify_player >/dev/null 2>&1
          pkill -x spotify_player
          sleep 0.2
          spotify_player -d &
      end
  end

  # Update Rofi theme
  if test -f ~/.config/rofi/config.rasi
      sed -i 's/@import "dark.rasi"/@import "light.rasi"/' ~/.config/rofi/config.rasi
  end

  # Note: Neovim will auto-reload via file watcher on ~/.config/theme_mode
end
