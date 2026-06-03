import QtQuick
import Quickshell
import Quickshell.Io
import "."

Item {
    id: root

    property string output: ""

    implicitWidth: visible ? text.implicitWidth + Theme.modulePadH * 2 : 0
    implicitHeight: parent ? parent.height : Theme.barHeight
    visible: output.length > 0

    Process {
        id: proc
        running: true
        command: ["bash", Quickshell.env("HOME") + "/.config/quickshell/scripts/weather.sh"]
        stdout: StdioCollector {
            onStreamFinished: root.output = this.text.trim()
        }
    }

    Timer {
        interval: 15 * 60 * 1000
        repeat: true
        running: true
        onTriggered: proc.running = true
    }

    Text {
        id: text
        anchors.centerIn: parent
        text: root.output
        color: Theme.fg
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.weight: Theme.fontWeight
        font.hintingPreference: Font.PreferFullHinting
        renderType: Text.NativeRendering
    }
}
