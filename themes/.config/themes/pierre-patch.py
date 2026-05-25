#!/usr/bin/env python3
"""Patch Pierre's bundled themes (Pierre Light / Pierre Dark) with palette
colors from colors.json. Pierre is the syntax highlighter hunkdiff uses;
its .mjs theme files contain a JSON-stringified VS Code-style theme with
a `semanticTokenColors` block of 17 token types. Hunk only exposes 2 of
them through its [custom_theme.syntax] reserved-map, so patching Pierre
directly is the only way to control coloring for the other 15.

Usage:
  pierre-patch.py <theme_mode> <pierre_mjs_path> [colors.json]

Idempotent: rewrites the JSON cleanly each time, so re-running after a
fresh `npm i -g hunkdiff` undoes the npm overwrite.
"""
import json
import os
import re
import sys
from pathlib import Path


def resolve(theme, path, depth=5):
    """Walk a dotted path through colors.json, following any number of
    reference indirections (semantic.* → accent.* → "#hex")."""
    cur = theme
    for p in path.split("."):
        if isinstance(cur, dict) and p in cur:
            cur = cur[p]
        else:
            return None
    if isinstance(cur, str) and "." in cur and not cur.startswith("#") and depth > 0:
        return resolve(theme, cur, depth - 1)
    return cur


# Mapping: Pierre semantic token → colors.json path.
# Picked to mirror what nvim's treesitter does for these tokens.
SEMANTIC_MAP = {
    "comment":                 "semantic.comment",
    "string":                  "semantic.string",
    "number":                  "semantic.number",
    "regexp":                  "accent.cyan",
    "keyword":                 "semantic.keyword",
    "variable":                "foreground.primary",
    "parameter":               "foreground.primary",
    "property":                "semantic.property",
    "function":                "semantic.function",
    "method":                  "semantic.method",
    "type":                    "semantic.type",
    "class":                   "semantic.type",
    "namespace":               "semantic.type",
    "enumMember":              "semantic.boolean",
    "variable.constant":       "semantic.boolean",
    "variable.defaultLibrary": "semantic.command",
    "decorator":               "accent.orange",
}

# TextMate scope → colors.json path. Pierre falls back to tokenColors for
# tokens the LSP semantic-token pass doesn't classify, so patching this
# layer too catches the rest.
TM_MAP = [
    (["comment", "punctuation.definition.comment"],            "semantic.comment"),
    (["string", "string.quoted"],                              "semantic.string"),
    (["constant.numeric", "constant.language.boolean"],        "semantic.number"),
    (["keyword", "storage.type", "storage.modifier"],          "semantic.keyword"),
    (["entity.name.function", "support.function"],             "semantic.function"),
    (["entity.name.type", "entity.name.class",
      "support.type", "support.class"],                        "semantic.type"),
    (["variable"],                                             "foreground.primary"),
    (["variable.parameter"],                                   "foreground.primary"),
    (["variable.other.property", "meta.object-literal.key"],   "semantic.property"),
]


def patch(theme_mode: str, mjs_path: Path, colors_path: Path) -> None:
    palette = json.load(colors_path.open())["themes"][theme_mode]

    src = mjs_path.read_text()
    # Match: export default Object.freeze(JSON.parse('<json>'));
    m = re.match(
        r"(export default Object\.freeze\(JSON\.parse\(')(.*)('\)\);?\s*)$",
        src, re.DOTALL,
    )
    if not m:
        print(f"pierre-patch: {mjs_path.name} doesn't match expected shape", file=sys.stderr)
        sys.exit(1)
    prefix, body, suffix = m.groups()

    # The JSON is embedded inside a JS single-quoted string. The producer
    # escaped only single-quote chars; everything else is literal JSON. So
    # we un-escape \' before parsing and re-escape on the way out.
    theme = json.loads(body.replace("\\'", "'"))

    # Patch semanticTokenColors. The values may be plain hex strings OR
    # objects like { foreground: "#...", bold: true }. Preserve the
    # latter shape; only swap the color.
    sem = theme.setdefault("semanticTokenColors", {})
    for tok, palette_path in SEMANTIC_MAP.items():
        new = resolve(palette, palette_path)
        if not new:
            continue
        cur = sem.get(tok)
        if isinstance(cur, dict):
            cur["foreground"] = new
        else:
            sem[tok] = new

    # Patch matching scopes in tokenColors. Each entry is
    # { scope: string | string[], settings: { foreground: "#..." } }.
    # We rewrite the foreground for any entry whose scopes overlap with
    # a key in TM_MAP. Order matters in VS Code grammars (later wins),
    # so we patch in place rather than appending.
    for tc in theme.get("tokenColors", []) or []:
        scopes = tc.get("scope")
        if scopes is None:
            continue
        if isinstance(scopes, str):
            scope_set = {scopes}
        else:
            scope_set = set(scopes)
        for match_scopes, palette_path in TM_MAP:
            if scope_set & set(match_scopes):
                new = resolve(palette, palette_path)
                if new and "settings" in tc:
                    tc["settings"]["foreground"] = new
                break

    new_body = json.dumps(theme, separators=(",", ":")).replace("'", "\\'")
    mjs_path.write_text(prefix + new_body + suffix)
    print(f"pierre-patch: rewrote {mjs_path.name} ({theme_mode})")


def main() -> int:
    if len(sys.argv) < 3:
        print(__doc__.split("Usage:")[1].strip(), file=sys.stderr)
        return 2
    theme_mode = sys.argv[1]
    mjs_path = Path(sys.argv[2]).expanduser()
    colors_path = (
        Path(sys.argv[3]).expanduser() if len(sys.argv) > 3
        else Path("~/dotfiles/themes/.config/themes/colors.json").expanduser()
    )
    if not mjs_path.exists():
        print(f"pierre-patch: {mjs_path} not found", file=sys.stderr)
        return 1
    if not colors_path.exists():
        print(f"pierre-patch: {colors_path} not found", file=sys.stderr)
        return 1
    if theme_mode not in ("light", "dark"):
        print(f"pierre-patch: theme_mode must be light|dark", file=sys.stderr)
        return 2
    patch(theme_mode, mjs_path, colors_path)
    return 0


if __name__ == "__main__":
    sys.exit(main())
