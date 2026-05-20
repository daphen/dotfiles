---
name: notes
description: Read, search, and write the user's personal notes (markdown files in ~/notes, synced to notes-sigma-tawny.vercel.app via the notes-cli). Triggers on "my notes", "add a note", "find/search notes about X", "what did I write about Y", "save this as a note", "create a note", "read my notes on Z".
metadata:
  type: workflow
---

# notes

User keeps personal notes as markdown in `~/notes/`. A sync server backs it; `notes-cli` reconciles the local dir with the server. When the user asks anything notes-related, do not try to be clever about where notes live — they're in `~/notes/`.

## Layout

- Each note is `~/notes/YYYY-MM-DD-HHMM-slug.md` (slug is optional; without one it's just `YYYY-MM-DD-HHMM.md`).
- The first non-blockquote line is `# Title` (markdown H1). Body follows.
- Files are plain markdown, no front-matter.

## Reading / searching

Sync first so you don't read stale state:

```
notes-cli -pull
```

Then use `rg` (or `grep -r`) over `~/notes/`. The user has ~60 notes; full-text scan is instant. Examples:

```
rg -i "design system" ~/notes/ -l        # filenames containing the phrase
rg -i "design system" ~/notes/           # matches with context
ls -t ~/notes/ | head -20                # 20 most recently touched
```

To read a note, just `cat` or Read it.

## Writing a new note

1. Pick a filename: today's date + a short kebab-case slug describing the topic. Get the date with `date +%Y-%m-%d-%H%M`.
2. Write the file under `~/notes/` with `# Title` on the first line, then content.
3. Push to the server:

```
notes-cli -push
```

Example shell:

```
slug="lovable-deploy-flow"
ts=$(date +%Y-%m-%d-%H%M)
path="$HOME/notes/$ts-$slug.md"
cat > "$path" <<'EOF'
# Lovable deploy flow

body here
EOF
notes-cli -push
```

## Appending to / editing an existing note

`grep`/`rg` to find the file, Edit it (preserve the `# Title` line), then `notes-cli -push`.

## Don'ts

- Don't open the TUI (`notes-cli` with no flags) — it blocks.
- Don't invent a different notes directory. It's `~/notes/`. The webapp at `https://notes-sigma-tawny.vercel.app` is the synced mirror; don't hit its API directly, use the CLI.
- Don't run `notes-cli -init` — config already exists at `~/.config/notes-cli/config.toml`.
