---
name: slack-format
description: Reformat a draft for pasting into Slack and copy it straight to the clipboard via wl-copy. Unwraps soft line breaks, converts markdown to Slack mrkdwn (**bold** -> *bold*, # heading -> *heading*, [text](url) -> <url|text>), preserves lists and inline code. Triggers on "format for slack", "copy for slack", "slackify", "send to slack", "paste in slack", "to clipboard for slack".
---

# slack-format

User's Slack composer does NOT interpret markdown — `**bold**` shows up literally. This skill converts markdown to Slack's mrkdwn syntax and writes the result to the clipboard via `wl-copy`.

## When to invoke

- User says "format for slack", "copy for slack", "slackify", "to clipboard for slack", or similar.
- User has just produced a draft (often by asking the assistant to write a Slack message) and wants it on the clipboard.
- Default target: the most recent message-style block the assistant produced. If unclear, ask which text to format.

## Transformation rules

1. **Bold:** `**text**` → `*text*`, `__text__` → `*text*`.

2. **Headings:** any line starting with `#`, `##`, `###`, etc. → `*<heading text>*` on its own line. Drop the `#` prefix entirely. Slack has no heading syntax, but bold-on-its-own-line is the convention.

3. **Italic:** leave `*text*` alone if it was italic in markdown — but the ambiguity with bold makes auto-conversion risky. If the markdown uses `_text_` for italic (alternate syntax), keep it as `_text_` (Slack interprets `_text_` as italic).

4. **Links:** `[text](url)` → `<url|text>`. Bare URLs stay bare.

5. **Lists:** `- item` and `* item` → `• item` (bullet character, cleaner Slack render). Numbered lists `1. item`, `2. item` stay as-is.

6. **Inline code:** `` `code` `` stays as-is. Slack renders backtick inline code natively.

7. **Fenced code blocks:** ` ```...``` ` stays as-is. Slack renders fenced blocks natively.

8. **Soft line breaks:** a single `\n` between two prose lines (no list marker, no heading, no blank line either side) becomes a single space. Paragraph breaks (`\n\n`) stay.

9. **Strip trailing whitespace** and collapse runs of 3+ newlines down to 2.

10. **Do not** alter content semantically.

## Don't convert

- Inside fenced code blocks: nothing transforms.
- Markdown tables: Slack doesn't render them. If input has a `|`-style table, ask whether to convert to a bullet list or leave as monospace (wrap in a fenced block).
- @ mentions: `@alice` stays as `@alice` (user types the actual mention in Slack composer when pasting). Slack-style `<@U12345>` mentions stay too.

## Writing to clipboard

Use `wl-copy` (Wayland session). Pipe via stdin to avoid argv/quoting issues. Use heredoc with quoted delimiter so the shell doesn't expand `$`, backticks, etc:

```bash
cat <<'SLACK_EOF' | wl-copy
<transformed text here>
SLACK_EOF
```

Fall back to `xclip -selection clipboard` if `wl-copy` isn't available.

## Output to the user

One short confirmation line after the clipboard write. Examples:

> Copied. Paste into Slack — markdown converted to mrkdwn, lists use `•`.

> Slack draft on clipboard. ~480 words, headings flattened to bold lines.

Do NOT dump the transformed text into the chat output. Clipboard is the artifact; the user already knows what they asked for.

If the input had something that needed special handling (a markdown table, a code block with `$` interpolations, a link the user might want to verify), call that out in the confirmation line.

## Edge cases

- If the input is already in Slack mrkdwn (single-asterisk bold), don't double-process. Detect by looking for `**` — if present, it's markdown; if absent and `*text*` is around, it's likely already mrkdwn.
- Multiple drafts in the conversation: default to the MOST RECENT one and name it in the confirmation: "Copied the revised version (without 'My read' section)."
- If the most recent assistant message is NOT a draft (it was a question, a tool result narration, etc.), ASK which text to format.

## Anti-patterns

- Don't add a preamble or signature to the clipboard content. Pure paste.
- Don't dump the transformed text into chat output. Clipboard only.
- Don't try to convert markdown tables silently. Ask first.
