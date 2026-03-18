# Work profile config - redirect YouTube to personal profile

from qutebrowser.api import interceptor
import subprocess

_YOUTUBE_HOSTS = {
    'www.youtube.com',
    'youtube.com',
    'youtu.be',
    'm.youtube.com',
    'music.youtube.com',
}

def _redirect_youtube_to_personal(info: interceptor.Request):
    """Intercept YouTube URLs and open them in the personal qutebrowser instance."""
    url = info.request_url
    if url.host() in _YOUTUBE_HOSTS:
        subprocess.Popen(['qutebrowser', url.toString()])
        info.block()

interceptor.register(_redirect_youtube_to_personal)

config.bind('<Ctrl-Shift-r>', 'spawn --userscript react-devtools-toggle')
