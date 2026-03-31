# qutebrowser config

# Don't load autoconfig (we manage everything in config.py)
config.load_autoconfig(False)

# Load theme from theme-generator
config.source('theme.py')

# Font configuration - GeistMono Nerd Font (matching kitty)
c.fonts.default_family = 'GeistMono Nerd Font'
c.fonts.default_size = '13pt'

# Tab padding
c.tabs.padding = {'top': 6, 'bottom': 6, 'left': 16, 'right': 10}
c.tabs.indicator.width = 3
c.tabs.indicator.padding = {'top': 4, 'bottom': 4, 'left': 2, 'right': 6}

# Tell sites we prefer dark mode (let them handle it natively)
c.colors.webpage.darkmode.enabled = False

# Ctrl+j/k to navigate completion lists
config.bind('<Ctrl-j>', 'completion-item-focus next', mode='command')
config.bind('<Ctrl-k>', 'completion-item-focus prev', mode='command')

# Completion settings
c.completion.shrink = True  # Shrink to fit content
c.completion.timestamp_format = '%Y-%m-%d'  # Shorter date format
c.completion.use_best_match = True

# 1Password integration
config.bind('<Alt-p>', 'spawn --userscript 1password', mode='insert')
config.bind('<Alt-p>', 'spawn --userscript 1password', mode='normal')
config.bind('<Alt-u>', 'spawn --userscript 1password-user', mode='insert')
config.bind('<Alt-u>', 'spawn --userscript 1password-user', mode='normal')
config.bind('<Alt-Shift-p>', 'spawn --userscript 1password-pass', mode='insert')
config.bind('<Alt-Shift-p>', 'spawn --userscript 1password-pass', mode='normal')

# Sync quickmarks from phone (synced app) then open quickmarks
config.bind('<Ctrl-b>', 'spawn --userscript sync-quickmarks')

# Tab navigation with Ctrl+h/l
config.bind('<Ctrl-h>', 'tab-prev')
config.bind('<Ctrl-l>', 'tab-next')

# Move tabs left/right with Ctrl+Shift+h/l
config.bind('<Ctrl-Shift-h>', 'tab-move -')
config.bind('<Ctrl-Shift-l>', 'tab-move +')

# Break out tab to new window / join tab to another window
config.bind('<Ctrl-Shift-k>', 'tab-give')
config.bind('<Ctrl-Shift-j>', 'tab-give 0')

# Restore tabs from last session on startup
c.auto_save.session = True

# Related tabs (links) open next to current, new tabs open at the end
c.tabs.new_position.related = 'next'
c.tabs.new_position.unrelated = 'last'

# Uncap frame rate on AC power (workaround for QTBUG-76006 - WebEngine assumes 60Hz)
import subprocess
def _on_ac_power():
    try:
        result = subprocess.run(
            ['cat', '/sys/class/power_supply/AC0/online'],
            capture_output=True, text=True, timeout=1
        )
        return result.stdout.strip() == '1'
    except Exception:
        return True

if _on_ac_power():
    c.qt.args = ['disable-frame-rate-limit']

# Smooth scrolling for keyboard navigation
c.scrolling.smooth = True

# Rebind Ctrl+D/U to use smooth scroll instead of scroll-page
config.bind('<Ctrl-d>', 'cmd-repeat 20 scroll down')
config.bind('<Ctrl-u>', 'cmd-repeat 20 scroll up')

# Open devtools in a separate window
config.bind('<Ctrl-Shift-i>', 'devtools window')

# Toggle React DevTools standalone (start/stop)
config.bind('<Ctrl-Shift-r>', 'spawn --userscript react-devtools-toggle')

# Quick tab switching with number keys
config.bind('1', 'tab-focus 1')
config.bind('2', 'tab-focus 2')
config.bind('3', 'tab-focus 3')
config.bind('4', 'tab-focus 4')
config.bind('5', 'tab-focus 5')
config.bind('6', 'tab-focus 6')
config.bind('7', 'tab-focus 7')
config.bind('8', 'tab-focus 8')
config.bind('9', 'tab-focus 9')
config.bind('0', 'tab-focus -1')  # Jump to last tab

# Native Wayland rendering to fix pixelated/blurry text with fractional scaling.
# Without this, qutebrowser runs via XWayland which upscales the surface causing
# pixelation on 1.5x scaled displays. This forces Qt and the Chromium engine to
# use the native Wayland backend and handle HiDPI scaling correctly.
c.qt.environ = {
    'QT_QPA_PLATFORM': 'wayland',
    'QT_QPA_PLATFORMTHEME': 'gnome',  # Help Qt detect GNOME dark mode preference
    'DRI_PRIME': '0',  # Force AMD iGPU, prevent waking NVIDIA dGPU
}

# Spoof Chrome user agent for Google sign-in (Google blocks QtWebEngine)
config.set('content.headers.user_agent',
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
    'accounts.google.com')

# Your custom settings below:

# Prevent videos from auto-playing in background tabs
c.content.autoplay = False

# Always allow Gmail to handle mailto links (prevents repeated prompts)
config.set('content.register_protocol_handler', True, '*://mail.google.com/*')

# Always allow Google Calendar to handle webcal links
config.set('content.register_protocol_handler', True, '*://calendar.google.com/*')
