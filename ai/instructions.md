# Worktree Management

Use `wt` (worktrunk) for all worktree operations instead of raw `git worktree` commands:

- `wt switch --create <branch>` to create a new worktree/branch
- `wt switch <branch>` to switch to an existing worktree
- `wt list` to show worktrees and their status
- `wt merge` to squash, rebase, fast-forward merge, and clean up
- `wt remove` to remove a worktree
- `wt step commit` to commit with LLM-generated message
- `wt step copy-ignored` to copy gitignored files between worktrees

## Niri workspace stacks (proart-only)

When the user asks for a new worktree on a niri-using machine, prefer
`~/.config/niri/scripts/ws-createwt <name>` over raw `wt switch --create`.
ws-createwt:

1. Creates the branch + worktree (`daphen/<name>` at
   `~/work/lovable.daphen-<name>`).
2. Spawns the standard 4-window stack on a `lovable-<name>` workspace:
   devenv-wt terminal, work-profile browser at the preview URL, claude
   session in the worktree, and an nvim/kitty.

Naming has two distinct shapes — don't conflate them:

- **Local short-name** (niri workspace, ws-* script arg, fish history,
  rofi pickers) drops the team prefix: `1234-fix-button-overflow`. The
  prefix adds noise in pickers and we already know it's a Lovable
  ticket. ws-createwt creates a niri workspace `lovable-1234-fix-button-overflow`.
- **Git branch name** (committed, pushed, referenced in PRs) KEEPS the
  team prefix because Linear's auto-link requires the full ticket ID
  (e.g. `every-1234`, not just `1234`) somewhere in the branch name.
  The branch becomes `daphen/every-1234-fix-button-overflow`.

So for EVERY-1234 about "fix button overflow":
- niri workspace / script name: `1234-fix-button-overflow`
- git branch: `daphen/every-1234-fix-button-overflow`

For closing: `~/.config/niri/scripts/ws-close-worktree <name>` tears
down the session (closes windows, devenv kill, unnames the workspace)
but KEEPS the on-disk worktree dir. To fully remove: `wt remove
daphen/<name>`.

Confirm with the user before invoking ws-createwt — it spawns 4 windows
and claims a niri workspace.

## Lovable-on-Lovable sandboxes (proart-only)

For tasks that should run in a REMOTE Lovable sandbox instead of locally,
the flow is two steps because **project creation is now Castle-gated**
(requires a browser-minted `X-Castle-Request-Token` that CLI scripts
can't produce):

```
ws-newlol                              # opens lovable.dev in work browser
# in the browser: workspace → New Project → toggle LoL → submit
# copy the resulting URL
ws-createlovbox <name> <project-url>   # claims the sandbox + spawns the stack
```

`ws-createlovbox` itself has three modes for the second arg:

```
ws-createlovbox <name>                      # scratch sandbox, no project (mode 1)
ws-createlovbox <name> <project-url>        # existing Lovable project (mode 2)
ws-createlovbox <name> <claim-name>         # existing sandbox by claim (mode 3)
```

The previous `--prompt` mode is removed — it talked directly to
`api.lovable.dev`'s project-create, which is now blocked by Castle for
any non-browser caller. Trying it prints an error pointing at ws-newlol.

`<name>` is the workspace short name — NO `daphen-` prefix. That prefix
belongs to local branches/worktrees only; ws-createlovbox prepends
`lovable-` itself. For Linear ticket EVERY-1186 about "Support private
npm registries", the name is `1186-private-npm-registries`, the
workspace becomes `lovable-1186-private-npm-registries`. Passing
`daphen-1186-...` as the second arg makes lovssh try to resolve it as
a claim/UUID and fail.

For an internal monorepo task (just need a sandbox to ship feature
work, no Lovable demo project), use mode 1 — scratch sandbox, skip
ws-newlol entirely.

Spawns a stack on a `lovable-<name>` workspace (same naming pattern as
ws-createwt so pickers show them together): lovssh→claude in
~/lovable, lovssh→nvim in ~/lovable, plus a work-profile browser if a
project URL is associated. No local worktree, no local devenv — the
sandbox owns both; edits happen remotely via SSH.

For reviewing a GitHub PR locally (different again — fetches the PR,
checks out on a `review/pr-<num>` branch, spawns the standard
4-window devenv stack), use `ws-createreview <pr-url-or-number>`.

Pick which script based on cues:

- Want a NEW LoL project, no URL yet → ws-newlol (browser only)
- LoL / "lovbox" / sandbox / project URL or claim given → ws-createlovbox
- New worktree / Linear ticket / local feature work → ws-createwt
- Reviewing someone else's PR → ws-createreview

Confirm before invoking either: ws-createlovbox claims a paid sandbox,
ws-createreview fetches+branches off main. ws-newlol just opens a
browser — no confirmation needed.

**Never preemptively run `ws-close-stack` to "clean up" before creating
a new workspace.** It closes every window on the focused workspace; if
that workspace happens to be `lovable-main` (the user's persistent
primary), it wipes their browser, Slack, music etc. ws-close-stack
itself now refuses to operate on `lovable-main`, but other reserved
workspaces could exist. Only invoke when the user explicitly asks for
teardown of a specific worktree's stack.

# Cross-environment prompts

When composing a prompt that will be sent to a remote agent (LoL project
chat in the lovable.dev web UI, a separate Claude session, an agent
inside a lovbox SSH session, etc.), the receiving agent has no access to
my filesystem, env vars, or shell state. References to local paths like
`~/notes/foo.md` or `~/work/lovable/...` will dead-end on their side.

Inline the relevant content directly in the prompt instead of pointing to
local paths. Same goes for env vars, niri workspace state, browser context.
If a referenced file is too large to inline, mention that explicitly and ask
the user whether to scp it across or summarize.

# Commits

Never mention Claude, Claude Code, or Anthropic in commit messages. Do not add Co-Authored-By lines referencing Claude.

# Comments

Default to writing **no comments**. Only add one when the WHY is non-obvious:
a hidden constraint, a subtle invariant, a workaround for a specific bug, or
behavior that would surprise a reader. If removing the comment wouldn't
confuse a future reader, don't write it.

Specifically don't write:
- Comments that restate what well-named code does ("// Set the timeout to 30s")
- Section dividers ("// --- Helpers ---")
- Doc comments that just restate the function signature
- Narration openers ("// This function handles authentication.")
- References to the current task ("// Added for issue #123" — rots)
- Chain-of-thought ("// We chose Map because…")
- Multi-paragraph explanations — if needed, they belong in the PR or a doc

When you DO write one, one line. Two lines max.
