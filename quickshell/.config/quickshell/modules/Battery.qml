import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "."

Item {
    id: root

    readonly property var battery: UPower.displayDevice
    readonly property real percentage: battery ? battery.percentage * 100 : 0
    readonly property int state: battery ? battery.state : 0

    implicitWidth: visible ? row.implicitWidth + Theme.modulePadH * 2 : 0
    implicitHeight: parent ? parent.height : Theme.barHeight
    visible: battery && battery.isPresent

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Text {
            text: {
                if (state === UPowerDeviceState.Charging) return "󰂄"
                if (state === UPowerDeviceState.FullyCharged) return "󰚥"
                const buckets = ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
                const idx = Math.min(9, Math.max(0, Math.floor(percentage / 10)))
                return buckets[idx]
            }
            color: {
                if (percentage < 15) return Theme.red
                if (percentage < 30) return Theme.yellow
                return Theme.fg
            }
            font.family: Theme.iconFontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Theme.fontWeight
            font.hintingPreference: Font.PreferFullHinting
            renderType: Text.NativeRendering
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: Math.round(percentage) + "%"
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
