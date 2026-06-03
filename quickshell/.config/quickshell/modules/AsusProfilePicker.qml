import QtQuick
import Quickshell
import Quickshell.Io
import "."

Picker {
    id: root

    open: AsusProfilePickerState.open
    onCloseRequested: AsusProfilePickerState.open = false

    placeholder: "performance profile"
    highlightField: "active"

    property var profiles: []
    property string activeProfile: ""

    onActiveChanged: if (active) refresh()
    function refresh() {
        listProc.running = true
        activeProc.running = true
    }

    onEnter: item => {
        if (!item || !item.name) return
        Quickshell.execDetached(["asusctl", "profile", "set", item.name])
    }

    Process {
        id: listProc
        command: ["asusctl", "profile", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = (this.text || "").split("\n").map(l => l.trim()).filter(l => l.length > 0)
                root.profiles = lines
            }
        }
    }

    Process {
        id: activeProc
        command: ["asusctl", "profile", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = (this.text || "").match(/^Active profile:\s*(\S+)/m)
                root.activeProfile = m ? m[1] : ""
            }
        }
    }

    items: {
        return root.profiles.map(p => ({
            name: p,
            label: p,
            active: p === root.activeProfile
        }))
    }
}
