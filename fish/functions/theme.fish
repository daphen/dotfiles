function theme --description "Manage fish themes"
  if count $argv > /dev/null
    if test "$argv[1]" = "light"
      set_light_theme
    else if test "$argv[1]" = "dark"
      set_dark_theme
    else if test "$argv[1]" = "toggle"
      if test "$THEME_MODE" = "dark"
        set_light_theme
      else
        set_dark_theme
      end
    else
      echo "Unknown theme: $argv[1]"
      echo "Usage: theme [light|dark|toggle]"
      return 1
    end
  else
    # No arguments, show current theme
    echo "Current theme: $THEME_MODE"
    echo "Usage: theme [light|dark|toggle]"
  end
end
