# Dotfiles (proart)

Configuration for my NixOS machine. Most dirs follow GNU-Stow conventions
(`app/.config/app/…`) and are deployed via home-manager symlinks from
`~/nixos/`. A few (e.g. `vial/`, `via/`) hold reference files with no live
target.

For an architecture overview — what subsystems exist, where they live,
how they talk to each other — see `SYSTEM.md`.

## Contents

| Dir | What |
|---|---|
| `ai/` | The CLAUDE.md auto-loaded into every Claude Code session (symlinked to `~/.claude/CLAUDE.md`). |
| `claude/` | Claude Code hooks, slash commands, plugins config. |
| `fish/` | Fish shell config, conf.d, functions, theme glue. |
| `git/` | Git config (work + personal). |
| `kanata/` | Keyboard remapper config — Swedish characters on ANSI via XKB. See `KEYBOARD_LAYOUT.md`. |
| `kitty/` | Terminal emulator. Tab-bar hidden, cursor-trail enabled, theme-managed. |
| `niri/` | Niri (scrollable Wayland WM) config + 65+ scripts in `scripts/`, including the `ws-*` workspace-stack orchestration. |
| `nvim/` | Neovim — lazy.nvim, snacks.nvim, custom AI tracker, rose-pine theme. |
| `opencode/` | OpenCode CLI agent config. |
| `quickshell/` | The bar, notification center, pickers, command palette. Replaces waybar + rofi. |
| `qutebrowser/` | Custom dark theme + userscripts. |
| `quickmarks/` | Bookmarks file consumed by the palette daemon. |
| `spotify-player/` | TUI Spotify client. |
| `starship/` | Shell prompt (template-driven via the theme system). |
| `swaylock/` | Lock screen. |
| `systemd/` | User systemd units. |
| `themes/` | Centralized theme manager — `colors.json` + templates produce per-tool configs. |
| `via/` | VIA keyboard layout JSON backup (Charybdis Mini). |
| `vial/` | Vial keymap reference (Piantor Pro). |
| `wallpapers/` | Wallpaper files. |
| `waypaper/` | Wallpaper picker state. |
| `eww` `clipse` `fastfetch` `bin` | Smaller bits. |

## Top-level docs

- `SYSTEM.md` — architecture overview, daemon map, who-talks-to-what.
- `ai/instructions.md` — agent guidance (auto-loaded as `~/.claude/CLAUDE.md`).
- `KEYBOARD_LAYOUT.md` — the two-layer (kanata + XKB) Swedish-on-ANSI scheme.
- `MANAGING-APPS.md` — local-vs-managed app conventions, theme integration.
- `QUICK-REFERENCE.md` — common commands cheatsheet.

## Deployment

This repo is consumed by `~/nixos/`'s home-manager configuration which
symlinks the relevant paths into `~/.config/`. To bring a new machine up:

```bash
# 1. Clone both repos
git clone https://github.com/daphen/nixos-config.git ~/nixos
git clone https://github.com/daphen/dotfiles.git    ~/dotfiles

# 2. Build the system
sudo nixos-rebuild switch --flake ~/nixos

# 3. Generate the initial themes (once; subsequent toggles use the manager)
~/dotfiles/themes/.config/themes/generate-themes.sh
```

On a remote/sandbox host that can't run NixOS, use
`nixos-portable-config` (the `dev-env` flake) — see that repo for the
bootstrap one-liner.

## Editing managed configs

Files under `~/.config/` that are symlinks point at this repo. Edit
either side and the change is live. Commit + push from `~/dotfiles` to
sync.

```bash
nvim ~/.config/kitty/kitty.conf   # follow the symlink
cd ~/dotfiles && git add kitty && git commit -m "..." && git push
```

## Promoting a new app to managed

```bash
~/dotfiles/promote-app-to-managed.sh <app>
```

Then wire it into `~/nixos/common/home/symlinks.nix`. See
`MANAGING-APPS.md` for the full decision flow.
