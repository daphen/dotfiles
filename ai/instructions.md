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

Keep code comments short — ideally one line, no more than three. Don't write multi-paragraph explanations; if a thought needs more than three lines it belongs in a PR description or a doc, not the source.
