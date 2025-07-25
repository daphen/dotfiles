function simple_theme_test --description "Simple theme test"
    echo "Testing theme switching..."
    
    # Apply light theme directly
    source ~/.config/themes/generated/fish/light.theme
    set -g THEME_MODE light
    
    # Set some obvious colors for testing
    set -g fish_color_command red
    set -g fish_color_param blue
    set -g fish_color_error yellow
    
    echo "Light theme applied with test colors"
    echo "Type 'ls' to see if colors changed"
end