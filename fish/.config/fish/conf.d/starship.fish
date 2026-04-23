# Load the Starship prompt. This is sourced explicitly because config.fish
# is out-of-store-symlinked from dotfiles, so home-manager's
# programs.starship.enableFishIntegration cannot inject into config.fish.
# Putting it in conf.d/ means every fish shell loads it on startup.
if command -v starship >/dev/null 2>&1
    starship init fish | source
end
