import QtQuick
import Quickshell
import Quickshell.Io
import "."

Item {
    id: root

    property int percentage: 0

    implicitWidth: row.implicitWidth + Theme.modulePadH * 2
    implicitHeight: parent ? parent.height : Theme.barHeight

    Process {
        id: proc
        running: true
        command: ["sh", "-c", "awk '/^MemTotal:/ {t=$2} /^MemAvailable:/ {a=$2} END {printf \"%d\", (t-a)*100/t}' /proc/meminfo"]
        stdout: StdioCollector {
            onStreamFinished: root.percentage = parseInt(this.text.trim()) || 0
        }
    }

    Timer {
        interval: 5000
        repeat: true
        running: true
        onTriggered: proc.running = true
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Text {
            text: "󰘚"
            color: Theme.fg
            font.family: Theme.iconFontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Theme.fontWeight
            font.hintingPreference: Font.PreferFullHinting
            renderType: Text.NativeRendering
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: root.percentage + "%"
            color: root.percentage >= 90 ? Theme.red
                 : root.percentage >= 75 ? Theme.yellow
                 : Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Theme.fontWeight
            font.hintingPreference: Font.PreferFullHinting
            renderType: Text.NativeRendering
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
