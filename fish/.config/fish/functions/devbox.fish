function devbox --description "Spawn a fresh Docker container with my portable dev env + drop into fish"
    set -l image $argv[1]
    if test -z "$image"
        set image "ubuntu:24.04"
    end

    # One-shot: install apt deps → curl bootstrap → exec fish
    # bootstrap.sh auto-detects no-systemd, installs Nix + home-manager,
    # deploys the portable config. `exec fish` replaces bash at the end.
    docker run -it --rm "$image" bash -c '
        if command -v apt-get >/dev/null 2>&1; then
            apt-get update -qq && apt-get install -y -qq curl ca-certificates
        elif command -v apk >/dev/null 2>&1; then
            apk add --no-cache curl ca-certificates
        elif command -v dnf >/dev/null 2>&1; then
            dnf install -y curl ca-certificates
        fi &&
        curl -sL https://raw.githubusercontent.com/daphen/nixos-portable-config/main/bootstrap.sh | bash &&
        exec fish
    '
end
