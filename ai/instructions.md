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

Naming: `<linear-issue-num>-<short-slug>`. Drop the team prefix
(`every-`, `lov-`, etc.), lowercase, dashes only. For EVERY-1234 about
"fix button overflow" → `1234-fix-button-overflow`. Linear matches the
ticket ID anywhere in the branch.

For closing: `~/.config/niri/scripts/ws-close-worktree <name>` tears
down the session (closes windows, devenv kill, unnames the workspace)
but KEEPS the on-disk worktree dir. To fully remove: `wt remove
daphen/<name>`.

Confirm with the user before invoking ws-createwt — it spawns 4 windows
and claims a niri workspace.

## Lovable-on-Lovable sandboxes (proart-only)

For tasks that should run in a REMOTE Lovable sandbox instead of locally,
use `~/.config/niri/scripts/ws-createlovbox <name> <project-url-or-claim>`.

ws-createlovbox:

1. Looks up or creates the sandbox via sandcastle.lovable.net.
2. Spawns a 3-window stack on a `lovable-<name>` workspace (same
   naming as ws-createwt, so the picker shows them together):
   lovssh→claude in ~/lovable, lovssh→nvim in ~/lovable, work-profile
   browser at the Lovable project page.

No local worktree, no local devenv: the sandbox owns both. All edits
happen remotely via SSH.

For reviewing a GitHub PR locally (different again — fetches the PR,
checks out on a `review/pr-<num>` branch, spawns the standard
4-window devenv stack), use `ws-createreview <pr-url-or-number>`.

Pick which script based on cues:

- LoL / "lovbox" / sandbox / project URL given → ws-createlovbox
- New worktree / Linear ticket / local feature work → ws-createwt
- Reviewing someone else's PR → ws-createreview

Confirm before invoking either: ws-createlovbox claims a paid sandbox,
ws-createreview fetches+branches off main.

# Cross-environment prompts

When composing a prompt that will be sent to a remote agent (LoL sandbox via
`ws-createlovbox --prompt`, a separate Claude session, etc.), the receiving
agent has no access to my filesystem, env vars, or shell state. References
to local paths like `~/notes/foo.md` or `~/work/lovable/...` will dead-end
on their side.

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
