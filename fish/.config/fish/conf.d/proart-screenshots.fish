# One-shot rsync of proart's Screenshots dir into the sandbox at
# shell startup. sandbox-side claude reads images by path; rsync gives
# us "files appear locally" without FUSE (which the lovbox container
# doesn't permit).
#
# In-session updates: call `pull-screenshots` to refresh on demand
# after taking a new screenshot on proart.
#
# Requires:
#   - rsync in PATH (daphen-env ships it)
#   - `proart` resolvable (tailnet MagicDNS)
#   - SSH agent forwarded by lovssh -A so proart accepts the
#     connection without a password

if status is-interactive
    if command -q rsync
        mkdir -p $HOME/proart-screenshots
        # Background + silent so the first prompt doesn't wait on the
        # network and a flaky link doesn't spam errors. Fish runs each
        # conf.d file once per shell so this fires on every new kitty.
        rsync -az --partial \
            proart:Pictures/Screenshots/ $HOME/proart-screenshots/ \
            >/dev/null 2>&1 &
        disown
    end
end
