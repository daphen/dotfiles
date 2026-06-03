import QtQuick
import Quickshell
import Quickshell.Io
import "."

Item {
    id: root

    property string kind: "disconnected"
    property string label: "Disconnected"

    implicitWidth: row.implicitWidth + Theme.modulePadH * 2
    implicitHeight: parent ? parent.height : Theme.barHeight

    Process {
        id: proc
        running: true
        command: ["sh", "-c",
            "ssid=$(nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | awk -F: '/^yes:/ {sub(/^yes:/, \"\"); print; exit}'); " +
            "if [ -n \"$ssid\" ]; then echo \"wifi $ssid\"; else " +
            "  eth=$(nmcli -t -f TYPE,DEVICE connection show --active 2>/dev/null | awk -F: '/^802-3-ethernet:/ {print $2; exit}'); " +
            "  if [ -n \"$eth\" ]; then echo \"eth $eth\"; else echo \"none\"; fi; " +
            "fi"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = this.text.trim()
                if (t.startsWith("wifi ")) {
                    root.kind = "wifi"
                    root.label = t.substring(5)
                } else if (t.startsWith("eth ")) {
                    root.kind = "eth"
                    root.label = t.substring(4)
                } else {
                    root.kind = "disconnected"
                    root.label = "Disconnected"
                }
            }
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
            text: "󰖩"
            color: Theme.fg
            font.family: Theme.iconFontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Theme.fontWeight
            font.hintingPreference: Font.PreferFullHinting
            renderType: Text.NativeRendering
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: root.label
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
