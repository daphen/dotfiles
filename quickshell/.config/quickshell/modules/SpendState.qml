pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Hypothetical API cost of Claude Code usage, computed by
// scripts/claude-spend. Click the bar pill to cycle day → month → all;
// the current mode refreshes every minute.
Singleton {
    id: state

    property string mode: "day"
    property var values: ({ day: -1, month: -1, all: -1 })
    readonly property real current: values[mode]

    function cycle() {
        mode = mode === "day" ? "month" : mode === "month" ? "all" : "day"
        refresh()
    }

    function refresh() {
        if (proc.running) return
        proc.mode = mode
        proc.running = true
    }

    Process {
        id: proc
        property string mode: "day"
        command: [
            Quickshell.env("HOME") + "/.config/quickshell/scripts/claude-spend",
            mode,
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseFloat(text.trim())
                if (isNaN(v)) return
                const next = Object.assign({}, state.values)
                next[proc.mode] = v
                state.values = next
            }
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: state.refresh()
    }
}
