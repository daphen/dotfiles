pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Reads the current WPM written by wpm-daemon to ~/.local/state/wpm.
// The daemon rewrites the file atomically every 500ms; FileView re-reads
// on every change.
Singleton {
    id: state

    property int value: 0

    FileView {
        path: Quickshell.env("HOME") + "/.local/state/wpm"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: state.value = parseInt((text() || "0").trim()) || 0
    }
}
