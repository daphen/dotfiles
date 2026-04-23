function devbox --description "Spawn a fresh Docker container with my portable dev env + drop into fish"
    set -l image $argv[1]
    if test -z "$image"
        set image "ubuntu:24.04"
    end

    # Mount host's gh auth read-only so the container has my GitHub token
    # automatically. Useful for cloning private repos during testing without
    # running `gh auth login` every time. Path is inside the container's /tmp
    # because root's $HOME changes during the bootstrap.
    set -l gh_mount
    if test -d "$HOME/.config/gh"
        set gh_mount -v "$HOME/.config/gh":/tmp/host-gh:ro
    end

    # One-shot: install apt deps → curl bootstrap → exec fish
    # - hm-session-vars.sh adds ~/.nix-profile/bin to PATH so fish is findable
    # - /tmp/host-gh is copied into /root/.config/gh so gh commands work immediately
    docker run -it --rm $gh_mount "$image" bash -c '
        if command -v apt-get >/dev/null 2>&1; then
            apt-get update -qq && apt-get install -y -qq curl ca-certificates
        elif command -v apk >/dev/null 2>&1; then
            apk add --no-cache curl ca-certificates
        elif command -v dnf >/dev/null 2>&1; then
            dnf install -y curl ca-certificates
        fi &&
        curl -sL https://raw.githubusercontent.com/daphen/nixos-portable-config/main/bootstrap.sh | bash &&
        if [ -d /tmp/host-gh ]; then
            mkdir -p "$HOME/.config/gh" && cp -r /tmp/host-gh/. "$HOME/.config/gh/" && chmod -R u+rw "$HOME/.config/gh"
            echo "==> GitHub auth copied from host"
        fi &&
        . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" 2>/dev/null
        export PATH="$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH"
        exec fish
    '
end
