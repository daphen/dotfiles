# Managing Apps: Local vs Managed

Quick model:

```
Is ~/.config/<app> a symlink?
  YES → managed (deployed via home-manager / nixos-config symlinks.nix)
  NO  → local (machine-specific, possibly not even in this repo)
```

This machine is NixOS — everything installs via `nixos-rebuild`, and most
configs get symlinked from `~/dotfiles/<app>/.config/<app>/` into
`~/.config/<app>/` by home-manager.

## When a new app shows up

1. **Install via nix**. Either system-wide in `~/nixos/common/default.nix`
   (`environment.systemPackages`) or per-user in
   `~/nixos/common/home/programs.nix`. Rebuild.
2. **Configure normally** — let it write to `~/.config/<app>/…`.
3. **Decide**: keep local or promote.

   - **Keep local**: do nothing. Config stays only on this machine,
     not in git.
   - **Promote to managed**: move the config into
     `~/dotfiles/<app>/.config/<app>/`, add a symlink target in
     `~/nixos/common/home/symlinks.nix`, rebuild.

The helper script `~/dotfiles/promote-app-to-managed.sh <app>` does the
move + sets you up to wire the symlink.

## Adding theme support

Optional but cheap if the app reads color values from a config file.

1. Drop a template at `~/dotfiles/themes/.config/themes/templates/<app>.template`
   using placeholders like `{{background.primary}}`, `{{accent.cyan}}`.
2. Hook it into `theme-manager.sh apply` — there's a `case "$tool" in …`
   block; add a branch that copies/symlinks the generated file to wherever
   `<app>` reads it from.
3. Regenerate: `theme-manager.sh generate dark` (and `light`).

For tools that need a runtime poke after the file changes (kitty's
`load-config`, fish reload, etc.) the apply branch can shell out to do it.

## Currently managed (representative)

- `kitty`, `nvim`, `fish`, `niri`, `quickshell`, `starship`, `git`,
  `kanata`, `yazi`, `qutebrowser`, `spotify-player`, `claude`, `themes`,
  `systemd`.

## Local (not in this repo)

Stuff that's machine-specific, contains secrets, or syncs via account:
- 1Password, Chrome / Helium user data, Slack, Discord-sync stuff.

## Pro tips

- **Start local, promote when stable** — install, tweak, *then* move.
- **Managed apps get free theme switching** — if a template exists,
  `theme-manager.sh toggle` covers them automatically.
- **.gitignore secrets** — if you must keep a config with credentials in
  this repo, ignore the sensitive file. Better: use sops-nix / agenix.

See `QUICK-REFERENCE.md` for the common one-liners.
