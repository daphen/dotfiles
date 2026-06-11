# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Neovim configuration built around **lazy.nvim** plugin management. Modular: one plugin per file under `lua/plugins/`. Optimized for web development (TypeScript/JavaScript, React), Go, and AI-assisted coding in the Lovable monorepo.

**Portable mirror**: `~/nixos-portable-config/packages/neovim/` carries a parallel copy of this config (lz.n + nix-packaged plugins, nvim 0.12) for remote sandboxes. Changes to plugin behavior here usually need mirroring there — check before considering a change done. Full convergence of the two setups is a pending project.

## Architecture

- **Entry Point**: `init.lua` — sets up lazy.nvim and loads core modules
- **Core Modules**: `lua/options.lua`, `lua/keymaps.lua`, `lua/utils.lua` (project-root detection helpers)
- **Plugin Directory**: `lua/plugins/` — each file returns a lazy.nvim spec
- **Local modules**: `lua/hunk-nvim/` (custom hunk signs vs branch base), `lua/notes-sync.lua`
- **External**: `~/.config/colorscheme/` — custom Rose Pine theme

Local nvim is 0.11.x from nixpkgs; the portable mirror builds 0.12.x. Avoid APIs deprecated in 0.12 (`vim.lsp.with` is already flagged).

## AI / Agent Change Tracking (file-watcher)

`lua/file-watcher/init.lua` — self-contained local module, zero plugin dependencies, identical copy in the portable mirror. The result of significant debugging — read it before changing it:

- libuv's `recursive` fs_event flag is a no-op on Linux, so it registers one inotify watch per directory. The dir list comes from `git ls-files` (never walks node_modules), registered in one shot (~90ms for 5.8k monorepo dirs). Newly created dirs get watched + scanned on their first event.
- Never scans file contents upfront (an earlier fs-monitor.nvim-based version did and froze the main loop on the 32k-file monorepo). Changed-line lookup is `git diff -U0 HEAD`, run only after all navigation guards pass.
- Auto-starts 1.5s after launch **only when**: `FS_MONITOR_DISABLED` unset (quickshell notes-capture sets it), not in kitty-scrollback, and cwd is inside a git repo (watching `$HOME` froze nvim once).
- Any external edit (Claude, agents, sed, formatters) navigates the editor to the changed file and line, with guards: ignored patterns, insert mode, recent user input (800ms), repo mismatch. Bursts coalesce to one navigation per 150ms, newest change wins.
- `:FileWatcherStatus` shows watch state, follow state, dir count, and the last navigation-skip reason. A lag sentinel logs main-loop stalls >500ms to `/tmp/nvim-lag-<pid>.log`.

## Important Keymaps

- `<leader>` = Space

### Change review (three scopes)
- `<C-f>` — picker of files changed vs branch base (repo-scoped; paths are absolute so it works from any cwd)
- `<C-g>d` — toggle diffview.nvim against the branch base (rich diff UI for everything on the branch)
- `<C-g>p` — gitsigns inline hunk preview
- `<leader>gv` / `<leader>gV` — diffview vs HEAD / close
- `<C-g>j/k` — next/prev hunk (hunk-nvim)

### file-watcher
- `<C-g>t` — toggle follow (auto-navigation)
- `<leader>fs` — manually start watching cwd (for sessions where auto-start was skipped)

### Core
- `<C-h/j/k/l>` — window navigation (TMux-aware)
- `<leader>sv/sh` — split vertically/horizontally; `<C-x>` close split
- `<leader>ff` — find files; `<leader>fg` — grep (snacks picker)
- `<leader>e` — Neo-tree
- `<leader>gg` — LazyGit; `<leader>gb` — blame line

## LSP Setup (`lua/plugins/lsp-config.lua`)

- **`didChangeWatchedFiles.dynamicRegistration` is forced off.** nvim implements LSP file-watching with a synchronous tree walk (`vim._watch.watchdirs`, no `inotifywait` installed) that froze nvim ~15s on every monorepo start — confirmed by LuaJIT profile (`jit.p`): all samples in `fs.lua`/`joinpath`/`_watchfunc`. Servers watch their own files fine. Don't re-enable without installing inotify-tools and re-profiling.

- **Mason** installs servers (ts_ls, eslint, oxlint, tailwindcss, gopls, lua_ls, …). Note: on NixOS mason's prebuilt binaries are fragile; migrating servers to nix packages (like the portable mirror already does) is part of the convergence plan.
- **oxlint** has no `oxc_language_server` binary anywhere — the CLI serves LSP via `oxlint --lsp`; the `vim.lsp.config("oxlint", …)` override handles this. The Lovable monorepo lints with oxlint, so duplicate eslint+oxlint diagnostics are possible in workspaces that carry both configs.
- **tailwindcss** excludes `**/templates/**` — the monorepo's dozens of starter apps each have a tailwind config and scanning them stalls startup.
- **eslint** only attaches in projects with an actual eslint config (root gated).
- **ts_ls** filters eslint-source and Next.js (71XXX) diagnostics.

## Development Workflow

- **Conform.nvim**: prettier (auto-detected config), stylua. Format on save.
- **nvim-lint**: eslint via eslint_d.
- **Auto-session**: per-directory session restore.
- **Theme**: Rose Pine with light/dark switching via the dotfiles theme system; transparent background.
- **Noice + snacks**: messages, pickers, dashboard, input. Prefer `vim.notify` over `print` — print output doesn't persist in `:messages` with noice.

## File Patterns

- One plugin per file in `lua/plugins/`; each returns a lazy.nvim spec
- Keymaps centralized in `lua/keymaps.lua` unless plugin-specific
- Use `lua/utils.lua` helpers for path/root operations
- Comments: only for non-obvious WHYs, one line (two max) — no narration, no section dividers
