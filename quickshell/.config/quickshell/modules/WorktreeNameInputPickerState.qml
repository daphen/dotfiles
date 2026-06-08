pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool open: false
    property string kind: "" // "local" | "lol"

    function show(k) { kind = k; open = true }
    function hide() { open = false }

    IpcHandler {
        target: "worktree-name-input"
        function hide() { root.hide() }
    }
}
