pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool open: false

    function toggle() { open = !open }
    function show()   { open = true }
    function hide()   { open = false }

    IpcHandler {
        target: "color-format"
        function toggle() { root.toggle() }
        function show()   { root.show() }
        function hide()   { root.hide() }
    }
}
