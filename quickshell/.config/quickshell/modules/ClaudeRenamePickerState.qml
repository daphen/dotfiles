pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool open: false
    property string sid: ""

    IpcHandler {
        target: "claude-rename"
        function show(sessionId: string) {
            root.sid = sessionId || ""
            root.open = true
        }
        function hide() { root.open = false }
    }
}
