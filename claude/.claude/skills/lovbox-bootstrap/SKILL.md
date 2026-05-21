---
name: lovbox-bootstrap
description: SSH into a lovable-on-lovable sandbox and launch the user's ephemeral dev env (nvim + fish + git toolkit) via nix run. Triggers on "ssh into my lovbox", "connect to lovbox <project>", "open lovbox <url>", "get my dev env onto this sandbox".
metadata:
  type: workflow
---

# lovbox-bootstrap

End-to-end flow for daphen connecting from proart (tailnet-connected) into a lovbox sandbox and getting his portable dev env. The user has a fish function `lovssh` that wraps the whole thing — most of the time you just hand them a `lovssh <url>` command. This skill documents the underlying steps so you can troubleshoot or replicate manually.

## 1. Provision the lovbox

Lovable-on-lovable sandboxes are **not** auto-spawned on project open. To provision:

1. Open the project on lovable.dev.
2. Click the **"Build with Lovable on Lovable runtime"** toggle in the bottom toolbar (next to the Build dropdown).
3. Lovable's backend spawns a sandbox tied to that project's UUID. The claim name is deterministic: `sha256(project_id + "\x00" + purpose + "\x00" + "lovable-on-lovable")[:16]` with prefix `lovable-` (or `lovable-powerplay-` for branch sandboxes). The `find-lovbox-sandbox-name` knowledge-skill ships a script that computes it.
4. After ~30s the sandbox is `Ready`. Verify with `lovlist -a | grep <project-uuid-prefix>` or `curl -s https://sandcastle.lovable.net/api/v1/sandboxes?access=shared | jq`.

Without the Lovable-runtime toggle clicked, the project has no lovbox and SSH will time out.

## 2. Connect from proart

Single fish command:

```fish
lovssh https://lovable.dev/projects/<uuid>
# or with the claim name directly:
lovssh lovable-<16hex>
```

What `lovssh` does internally:

1. Extract the project UUID from the URL.
2. Compute the deterministic claim name (SHA256, first 16 hex).
3. Look up the sandbox via `GET https://sandcastle.lovable.net/api/v1/sandboxes` and `?access=shared` to get `sandbox_name` + `namespace` (lovable-on-lovable sandboxes are in the shared list).
4. POST `~/.ssh/id_ed25519.pub` to `/api/v1/sandboxes/<claim>/ssh-keys` (idempotent re-add).
5. Build the direct service hostname: `<sandbox_name>.<namespace>.svc.devex-eun2-toad.cluster.d.l5e.io` (the sandcastle gateway on `:2222` isn't publicly reachable; the direct hostname is, via tailnet subnet routes).
6. `ssh -A -p 2222 -t lovable@<direct-host> 'exec nix run --refresh github:daphen/nixos-portable-config#daphen-env'`.

Note the SSH user is **`lovable`** (the in-pod user), not the claim name. That's a quirk of the direct-host path vs the gateway path.

If `lovssh` isn't available on the current machine, the manual equivalent is the SSH command from step 6 with the claim/direct-host plugged in.

## 3. What the dev env contains

`github:daphen/nixos-portable-config#daphen-env` is a `writeShellApplication` that bundles all tools into one closure and execs fish with the right env vars:

- **Editor / shell**: bundled nvim (lz.n loader, plugins + LSPs baked into the store), fish, starship.
- **CLI toolkit**: ripgrep, fd, bat, jq, gh, delta, fastfetch, openssh, fzf, zoxide, git.
- **Dotfile configs**: fish config.fish + conf.d + functions (theme system included), starship (light + dark variants picked by `~/.config/theme_mode`), a minimal gitconfig (delta as pager, daphen's identity).
- **No persistent install**: nothing is added to the nix profile; the env is a transient closure that disappears when fish exits. The Nix store keeps the closure cached on the sandbox PVC, so subsequent connects are ~instant.

**Deliberately omitted**:
- `claude-code` / `codex` / `opencode` — lovbox image ships these.
- `_1password-cli` — daphen doesn't read secrets on remotes.
- Anything else not in `packages/daphen-env/default.nix`. Add there + push to extend.

## 4. Verify you're in the right place

```fish
echo $LOVABLE_PROJECT_ID    # should match the URL's UUID
hostname                     # pool-replica hostname (matches sandbox_name from the list)
which nvim                   # /nix/store/...-daphen-env-*/bin/nvim
```

## 5. Iterating on the env

Source of truth: `github:daphen/nixos-portable-config`. Push changes there, then re-run `lovssh` — the `--refresh` flag bypasses the 1h flake cache so changes land within seconds.

The fish function `lovssh` lives at `~/dotfiles/fish/.config/fish/functions/lovssh.fish`. After editing, `source ~/.config/fish/functions/lovssh.fish` (or `exec fish`) to reload.

A complementary `lovlist` function shows lovable-on-lovable sandboxes:

```fish
lovlist            # default filter: lovable-<16hex> only, 30 most recent
lovlist -a         # all, including br-* powerplay branches and scratch
lovlist -p         # powerplay branches only
```

## Don'ts

- Don't try to use `home-manager switch` on the sandbox — the old bootstrap did that and it kept conflicting with the lovbox image's pre-populated nix profile (man-db, openssh, etc.). The current nix-run approach sidesteps all of that.
- Don't SSH via `sandcastle.lovable.net:2222`. It resolves but the public IP doesn't route SSH; only the direct K8s service hostname works (via tailnet subnet routes).
- Don't try to SSH into a non-LoL sandbox. If the project doesn't have the Lovable-runtime toggle on, there's no sandbox to connect to.
- Don't expect ai-tracker's preview-gate / send-to-Claude features to work in the sandbox — they assume a local kitty terminal and niri workspace registry. Display-only ai-tracker (pickers, jump-to-change) works fine.
