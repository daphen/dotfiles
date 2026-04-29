"""
half_page_scroll.py — kitty kitten for context-aware Ctrl+U / Ctrl+D.

When the focused kitty window is on its primary screen (e.g., the shell
prompt), scrolls the viewport by approximately half the visible rows.

When the window is using its alternate linebuf (nvim, less, htop, claude
TUI, etc), the literal Ctrl-U (0x15) or Ctrl-D (0x04) byte is forwarded
to the child process so the running app gets the keypress natively.

Usage in kitty.conf:
    map ctrl+u kitten half_page_scroll.py up
    map ctrl+d kitten half_page_scroll.py down
"""

from kittens.tui.handler import result_handler
from kitty.boss import Boss


def main(args):
    # Required for kitten loading but unused — handle_result runs directly
    # in kitty's main process via the no_ui decorator below.
    return ""


@result_handler(no_ui=True)
def handle_result(args, answer, target_window_id: int, boss: Boss) -> None:
    direction = args[1] if len(args) > 1 else "down"
    w = boss.window_id_map.get(target_window_id)
    if w is None:
        return

    if w.screen.is_using_alternate_linebuf():
        # Inside nvim/less/etc. — pass the keystroke through unchanged.
        w.write_to_child(b"\x15" if direction == "up" else b"\x04")
        return

    # On the shell prompt — scroll the viewport by half a screen in a
    # single call so there's no per-line redraw flash.
    half = max(1.0, w.screen.lines / 2.0)
    w.scroll_fractional_lines(-half if direction == "up" else half)
