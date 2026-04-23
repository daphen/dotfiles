function devbox --description "Spawn a fresh Docker container with my portable dev env + drop into fish"
    set -l image $argv[1]
    if test -z "$image"
        set image "ubuntu:24.04"
    end

    # Extract host's GitHub token so the container can auth without dbus/keyring.
    # gh auth token reads from wherever gh stores credentials (keyring on Linux
    # usually). Passing it as GH_TOKEN env var in the container bypasses config
    # migration issues + secret-service lookups that need dbus.
    set -l docker_env
    if command -v gh >/dev/null 2>&1
        set -l token (gh auth token 2>/dev/null)
        if test -n "$token"
            set docker_env -e "GH_TOKEN=$token"
        end
    end

    docker run -it --rm $docker_env "$image" bash -c '
        # Install apt/dnf/apk deps
        if command -v apt-get >/dev/null 2>&1; then
            apt-get update -qq && apt-get install -y -qq curl ca-certificates
        elif command -v apk >/dev/null 2>&1; then
            apk add --no-cache curl ca-certificates
        elif command -v dnf >/dev/null 2>&1; then
            dnf install -y curl ca-certificates
        fi

        # Run the bootstrap (installs Nix, home-manager, deploys portable env)
        curl -sL https://raw.githubusercontent.com/daphen/nixos-portable-config/main/bootstrap.sh | bash || exit 1

        # GH_TOKEN from the env is read automatically by gh — no config migration,
        # no keyring, no dbus. Confirm for visibility:
        if [ -n "${GH_TOKEN:-}" ]; then
            echo "==> GH_TOKEN present — gh commands will use host token"
        fi

        # Ensure home-manager profile bins are on PATH before exec fish
        export PATH="$HOME/.local/state/nix/profile/bin:$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH"

        if command -v fish >/dev/null 2>&1; then
            exec fish
        else
            echo "!! fish not found on PATH after bootstrap. PATH=$PATH"
            find "$HOME" /nix -maxdepth 6 -name fish -type f 2>/dev/null | head -5
            exec bash
        fi
    '
end
