# Auto-mount proart's screenshots dir into the sandbox so claude
# running inside the sandbox can read images saved on the laptop.
#
# Requires:
#   - sshfs in PATH (daphen-env ships it)
#   - `proart` resolvable (tailnet MagicDNS) — handled by the lovbox's
#     tailscale identity
#   - SSH agent forwarded by lovssh (-A flag) so proart accepts the
#     connection without a password
#
# Safe to source on every fish startup: silently no-ops when sshfs
# isn't available, the mount already exists, or proart is unreachable.

if status is-interactive
    if command -q sshfs
        set -l mnt $HOME/proart-screenshots
        mkdir -p $mnt
        if not findmnt -t fuse.sshfs $mnt >/dev/null 2>&1
            sshfs proart:Pictures/Screenshots $mnt \
                -o reconnect,ServerAliveInterval=15 2>/dev/null
        end
    end
end
