function devbox --description "Spawn a fresh Docker container with my portable dev env + drop into fish"
    set -l image $argv[1]
    if test -z "$image"
        set image "ubuntu:24.04"
    end

    set -l gh_mount
    if test -d "$HOME/.config/gh"
        set gh_mount -v "$HOME/.config/gh":/tmp/host-gh:ro
    end

    docker run -it --rm $gh_mount "$image" bash -c '
        # Install apt/dnf/apk deps
        if command -v apt-get >/dev/null 2>&1; then
            apt-get update -qq && apt-get install -y -qq curl ca-certificates
        elif command -v apk >/dev/null 2>&1; then
            apk add --no-cache curl ca-certificates
        elif command -v dnf >/dev/null 2>&1; then
            dnf install -y curl ca-certificates
        fi

        # Run the bootstrap (downloads Nix, installs home-manager, deploys env)
        curl -sL https://raw.githubusercontent.com/daphen/nixos-portable-config/main/bootstrap.sh | bash || exit 1

        # Copy gh auth from the read-only host mount
        if [ -d /tmp/host-gh ]; then
            mkdir -p "$HOME/.config/gh"
            cp -r /tmp/host-gh/. "$HOME/.config/gh/"
            chmod -R u+rw "$HOME/.config/gh"
            echo "==> GitHub auth copied from host"
        fi

        # Find fish on the home-manager profile path and exec into it.
        # Standalone HM uses ~/.local/state/nix/profile/bin (newer) or
        # ~/.nix-profile/bin (older). /nix/var/nix/profiles/default/bin is for
        # system-wide Nix. Cover all three in PATH.
        export PATH="$HOME/.local/state/nix/profile/bin:$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH"

        if command -v fish >/dev/null 2>&1; then
            exec fish
        else
            echo "!! fish not found on PATH after bootstrap. PATH=$PATH"
            echo "!! Searching for fish binary..."
            find "$HOME" /nix -maxdepth 6 -name fish -type f 2>/dev/null | head -5
            exec bash
        fi
    '
end
