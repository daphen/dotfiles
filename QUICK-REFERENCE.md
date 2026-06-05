# Quick Reference: Dotfiles Management

## Check what's managed

```bash
ls -la ~/.config/ | grep '^l'   # symlinks = managed
ls -la ~/.config/ | grep '^d'   # plain dirs = local
```

## Promote a new app

```bash
~/dotfiles/promote-app-to-managed.sh <app>
# then add the symlink target in ~/nixos/common/home/symlinks.nix
sudo nixos-rebuild switch --flake ~/nixos
```

## Theme management

```bash
cd ~/dotfiles/themes/.config/themes

./theme-manager.sh apply dark    # apply dark mode now
./theme-manager.sh apply light   # apply light mode now
./theme-manager.sh toggle        # flip current mode
./theme-manager.sh generate dark # regenerate (no apply) — after editing colors.json / templates
./theme-manager.sh status        # report what's managed
```

## Git workflow

Configs under `~/.config/` that are symlinks point at this repo. Edit
either side; the change is immediately live.

```bash
nvim ~/.config/kitty/kitty.conf
cd ~/dotfiles && git add kitty && git commit -m "kitty: ..." && git push
```

## More

- `README.md` — directory layout overview
- `SYSTEM.md` — full architecture map (daemons, QS, theme system, niri)
- `MANAGING-APPS.md` — local-vs-managed decision flow
- `KEYBOARD_LAYOUT.md` — kanata + XKB Swedish-on-ANSI scheme
- `ai/instructions.md` — what an agent landing fresh should know
