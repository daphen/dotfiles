import QtQuick
import Quickshell
import Quickshell.Io
import "."

Item {
    id: root

    property int usage: 0
    property int prevTotal: 0
    property int prevIdle: 0

    implicitWidth: row.implicitWidth + Theme.modulePadH * 2
    implicitHeight: parent ? parent.height : Theme.barHeight

    Process {
        id: proc
        running: true
        command: ["sh", "-c", "head -n1 /proc/stat | awk '{idle=$5+$6; total=$2+$3+$4+$5+$6+$7+$8; print idle, total}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = this.text.trim().split(/\s+/)
                if (parts.length !== 2) return
                const idle = parseInt(parts[0])
                const total = parseInt(parts[1])
                if (root.prevTotal > 0) {
                    const dt = total - root.prevTotal
                    const di = idle - root.prevIdle
                    if (dt > 0) root.usage = Math.round(100 * (dt - di) / dt)
                }
                root.prevIdle = idle
                root.prevTotal = total
            }
        }
    }

    Timer {
        interval: 2000
        repeat: true
        running: true
        onTriggered: proc.running = true
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Text {
            text: "󰍛"
            color: Theme.fg
            font.family: Theme.iconFontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Theme.fontWeight
            font.hintingPreference: Font.PreferFullHinting
            renderType: Text.NativeRendering
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: root.usage + "%"
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Theme.fontWeight
            font.hintingPreference: Font.PreferFullHinting
            renderType: Text.NativeRendering
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
