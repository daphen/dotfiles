pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool active: false

    readonly property string path: Quickshell.env("HOME") + "/.config/quickshell/dnd"

    function toggle() {
        active = !active
        writeProc.command = ["sh", "-c", root.active
            ? "mkdir -p \"$(dirname '" + path + "')\" && touch '" + path + "'"
            : "rm -f '" + path + "'"]
        writeProc.running = true
    }

    Process {
        id: writeProc
    }

    FileView {
        id: file
        path: root.path
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.active = true
        onLoadFailed: root.active = false
    }
}
