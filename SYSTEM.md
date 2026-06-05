# proart system architecture

A map of the major subsystems on this NixOS machine, where their code
lives, and how they talk to each other. Aimed at an agent landing fresh
and trying to figure out what to touch for a given task.

## At a glance

```
┌─────────────────────────────────────────────────────────────────────┐
│  niri (wayland compositor)                                          │
│   ├─ keybinds + ws-* scripts ── ~/.config/niri/scripts/             │
│   ├─ kanata + XKB ──── physical keyboard → keys/Swedish chars       │
│   └─ environment {} block ── exports FZF_DEFAULT_OPTS_FILE etc      │
├─────────────────────────────────────────────────────────────────────┤
│  Quickshell (qs)                                                    │
│   ├─ Bar.qml ────────── top bar with pills (wpm, worktree)          │
│   ├─ pickers ────────── emoji, network, bluetooth, color-format,    │
│   │                     claude-rename, worktree, lovbox, asus       │
│   ├─ NotificationOverlay ─ toast strip (focused-monitor only)       │
│   └─ singletons ─────── NiriState, Theme, *PickerState, WpmState    │
├─────────────────────────────────────────────────────────────────────┤
│  Daemons                                                            │
│   ├─ palette-daemon ── chromium-palette WebKit overlay (~/personal) │
│   ├─ wpm-daemon ────── evdev → ~/.local/state/wpm → QS pill         │
│   ├─ kanata ────────── system-level key remap (NixOS service)       │
│   └─ ws-tracker ────── tracks active lovable-* workspace            │
├─────────────────────────────────────────────────────────────────────┤
│  Theme system                                                       │
│   colors.json + templates/*.template → generated/<tool>/<mode>      │
│   theme-manager.sh apply <mode> ── syncs every tool to current mode │
└─────────────────────────────────────────────────────────────────────┘
```

## Repositories

| Repo | Where | What |
|---|---|---|
| `nixos-config` | `~/nixos` | System + home-manager config |
| `dotfiles` | `~/dotfiles` | App configs, scripts, themes |
| `nixos-portable-config` | `~/nixos-portable-config` | `dev-env` for remote/sandbox hosts |
| `palette-daemon` | `~/personal/palette-daemon` | Rust + webkit6 |
| `chromium-palette` | `~/personal/chromium-palette` | Solid app served by palette-daemon |
| `wpm-daemon` | `~/personal/wpm-daemon` | Rust evdev daemon |
| `endcord-fork` | `~/personal/endcord-fork` | Discord TUI fork |
| `bastardkb-qmk` | `~/work/bastardkb-qmk` | Charybdis firmware fork |

## Quickshell architecture

`~/dotfiles/quickshell/.config/quickshell/`

- `shell.qml` — root. Uses `Variants { model: Quickshell.screens }` so
  bar + NotificationOverlay reconcile across monitor docks/undocks
  (don't use imperative `Component.onCompleted` for per-screen surfaces).
- `modules/qmldir` — registers every component.
- `modules/Bar.qml` — top-of-screen bar. Leftmost = `wpmPill`,
  middle = `Minimap`, rightmost = `worktreePill`. Mid bar = leftGroup
  (DateText, Weather, Cpu, Memory) + rightGroup (Inbox, Dnd, Network,
  Audio, Battery, Clock).
- `modules/*State.qml` — singletons holding state. Most consumed by
  pickers; `NiriState.qml` is the most important (subscribes to niri's
  event-stream and exposes `version`, `focusedAppId()`,
  `focusedOutput()`, `minimapEntries(output)`).
- `modules/*Picker.qml` + matching `*PickerState.qml` — IPC-toggleable
  fzf-style pickers (emoji, network, bluetooth, color-format, lovbox,
  worktree, claude-rename, asus-profile). Each registers an
  `IpcHandler { target: "<name>" }` so niri keybinds open them with
  `qs ipc call <name> toggle`.
- `modules/Notifications.qml` — singleton wrapping
  `NotificationServer`. Handles DND, focus-dismiss, kitty OSC dedupe
  by body+summary.
- `modules/NotificationOverlay.qml` — toast strip; visibility gated on
  `screen.name === NiriState.focusedOutput()` so toasts only appear
  on the active monitor.

## Theme system

`~/dotfiles/themes/.config/themes/`

- `colors.json` — single source of truth, two palettes (dark + light).
- `templates/<tool>.template` — Mustache-ish placeholders like
  `{{background.primary}}`.
- `theme-processor.py` — substitutes placeholders → `generated/<tool>/<mode>.theme`.
- `theme-manager.sh apply <mode>` — copies generated theme into each
  tool's expected path. For tools that need restart/reload, also pokes
  the running process (e.g. kitty `load-config`, QS file-watch).

### FZF special-case

We use `FZF_DEFAULT_OPTS_FILE` (not `FZF_DEFAULT_OPTS` env var) so theme
toggles take effect live in already-running processes (yazi, claude
TUI, etc). Flow:

1. Template produces a plain `--color=...` lines file (one flag per
   line, no shell wrapper).
2. `theme-manager.sh apply <mode>` symlinks `~/.config/fzf/opts.conf` →
   `~/.config/themes/generated/fzf/<mode>.theme`.
3. `FZF_DEFAULT_OPTS_FILE=~/.config/fzf/opts.conf` is exported via
   home-manager `home.sessionVariables` (and `niri.environment{}` for
   compositor-spawned commands).
4. fzf reads the file on every invocation → instant toggle.

`fish/.config/fish/conf.d/zz_strip_fzf_default_opts.fish` defensively
unsets any inherited `FZF_DEFAULT_OPTS` (which would override the file).

## Niri workspace stacks

`~/dotfiles/niri/.config/niri/scripts/`

The `ws-*` family orchestrates niri workspace + window spawns to match
the chosen development flow. See `ai/instructions.md` for the
user-facing names + when to use each.

Internals:
- `ws-tracker` (systemd-user) — listens to niri events and writes the
  currently-focused `lovable-*` workspace name to
  `~/.local/state/wt-stacks/ws/active`.
- `NiriState.activeStack` (QS) — FileView on that path. Drives the
  worktreePill in Bar.qml.

## Notifications

- `Notifications.qml` registers `NotificationServer` (org.freedesktop.Notifications).
- On arrival: DND check, then kitty dedupe (same body + workspace-tagged
  summary preferred over generic).
- On focus change: matching app's notifs auto-dismiss (via
  `appIdToNotifAppName` mapping). Kitty notifs use a workspace check so
  only the focused-workspace's kitty notifs dismiss.
- Endcord's `notification_in_active = False` + CSI 1004 focus reporting
  handle the "active chat + window unfocused" case at the source.
  Note: our fork patches `tui.py` to handle ncurses' translated focus
  keycodes 590/591 (the raw `ESC[I/O` byte form never arrives in keypad
  mode).

## Charybdis firmware

`~/work/bastardkb-qmk/keyboards/bastardkb/charybdis/3x6/keymaps/daphen/`

Custom keymap.c is minimal (BASE/LOWER/RAISE — VIA holds the real
keymap in dynamic EEPROM). Key tunings in `config.h`:
- `HOLD_ON_OTHER_KEY_PRESS` + `HOLD_ON_OTHER_KEY_PRESS_PER_KEY`
  (per-key escape hatch for `LT(3, KC_DOT)` — slow pinky).
- `PERMISSIVE_HOLD` + `TAPPING_TERM 175`.
- `MOUSE_DISABLE_AFTER_KEYPRESS_MS 100` — trackball pauses briefly
  after each keypress.

Firmware-level patches in `charybdis.c` (our fork at
`~/work/bastardkb-qmk` is on `bkb-master`):
- `pointing_device_init_kb()` — re-applies saved DPI on every
  pointing-device reinit (USB resume etc), fixes the "trackball
  resets to 1600 CPI after suspend" symptom.

VIA layout backup: `~/dotfiles/via/charybdis-mini-via.json`.

## Daemons running on this machine

| Daemon | Purpose | Started by |
|---|---|---|
| `niri` | Compositor | systemd graphical-session |
| `quickshell` | Bar / notifications / pickers | niri spawn-at-startup |
| `palette-daemon` | Cmd-palette overlay | systemd-user (graphical-session.target) |
| `wpm-daemon` | Bar WPM counter | systemd-user (graphical-session.target) |
| `kanata` | Key remap | NixOS system service |
| `mako` | (removed; replaced by Quickshell's NotificationServer) | — |
| `blueman-applet` | (removed; deduped bluetooth notifs) | — |
| `ws-tracker` | Active workspace pointer | systemd-user |

## Where to look for a given task

- **Bar widget change** → `~/dotfiles/quickshell/.config/quickshell/modules/Bar.qml` + new `Foo.qml` and `FooState.qml`, register in `qmldir`.
- **Theme tweak** → `~/dotfiles/themes/.config/themes/colors.json` or `templates/<tool>.template`. Then `theme-manager.sh apply <mode>`.
- **Niri keybind** → `~/.config/niri/config.kdl` (auto-reloads).
- **Niri spawn script** → `~/.config/niri/scripts/<name>`.
- **Notification routing** → `Notifications.qml` `onNotification` handler + the `appIdToNotifAppName` map.
- **Endcord behaviour change** → `~/personal/endcord-fork/`, commit + push, bump `rev`/`hash` in `~/nixos/pkgs/endcord/default.nix`, rebuild.
- **Charybdis firmware** → `~/work/bastardkb-qmk/...`, build with `nix-shell -p qmk --run 'qmk compile -kb bastardkb/charybdis/3x6 -km daphen'`, flash both halves separately.
- **WPM tuning** → `~/personal/wpm-daemon/src/main.rs` — knobs at the top (`PAUSE_THRESHOLD`, `MIN_BURST_CHARS`, `DISPLAY_HOLD`). Rebuild + restart service.
