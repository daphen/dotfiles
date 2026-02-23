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
c.colors.webpage.preferred_color_scheme = 'auto'

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

# Uncap frame rate (workaround for QTBUG-76006 - WebEngine assumes 60Hz)
# c.qt.args = ['disable-frame-rate-limit']

# Smooth scrolling for keyboard navigation
c.scrolling.smooth = True

# Rebind Ctrl+D/U to use smooth scroll instead of scroll-page
config.bind('<Ctrl-d>', 'cmd-repeat 20 scroll down')
config.bind('<Ctrl-u>', 'cmd-repeat 20 scroll up')

# Native Wayland rendering to fix pixelated/blurry text with fractional scaling.
# Without this, qutebrowser runs via XWayland which upscales the surface causing
# pixelation on 1.5x scaled displays. This forces Qt and the Chromium engine to
# use the native Wayland backend and handle HiDPI scaling correctly.
c.qt.environ = {
    'QT_QPA_PLATFORM': 'wayland',
    'QT_QPA_PLATFORMTHEME': 'gnome',  # Help Qt detect GNOME dark mode preference
}

# Your custom settings below:

# Prevent videos from auto-playing in background tabs
c.content.autoplay = False
