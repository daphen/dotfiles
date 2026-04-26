# Worktree Management

Use `wt` (worktrunk) for all worktree operations instead of raw `git worktree` commands:

- `wt switch --create <branch>` to create a new worktree/branch
- `wt switch <branch>` to switch to an existing worktree
- `wt list` to show worktrees and their status
- `wt merge` to squash, rebase, fast-forward merge, and clean up
- `wt remove` to remove a worktree
- `wt step commit` to commit with LLM-generated message
- `wt step copy-ignored` to copy gitignored files between worktrees

# Commits

Never mention Claude, Claude Code, or Anthropic in commit messages. Do not add Co-Authored-By lines referencing Claude.
