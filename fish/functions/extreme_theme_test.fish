function extreme_theme_test --description "Extreme theme test with obvious colors"
    echo "Testing with VERY obvious colors..."
    
    # Set extremely obvious colors
    set -g fish_color_command ff0000  # Bright red
    set -g fish_color_param 00ff00    # Bright green
    set -g fish_color_error ffff00    # Bright yellow
    set -g fish_color_quote 0000ff    # Bright blue
    set -g fish_color_normal ff00ff   # Bright magenta
    
    echo "Set extreme colors - now type some commands"
    echo "Commands should be RED, parameters GREEN"
    echo "Type: ls -la (ls should be red, -la should be green)"
end