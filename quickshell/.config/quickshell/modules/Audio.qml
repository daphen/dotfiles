import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "."

Item {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false
    readonly property bool bluetooth: {
        if (!sink) return false
        const n = (sink.name || "").toLowerCase()
        const d = (sink.description || "").toLowerCase()
        return n.indexOf("bluez") >= 0 || n.indexOf("bluetooth") >= 0
            || d.indexOf("bluetooth") >= 0 || d.indexOf("airpods") >= 0
    }

    implicitWidth: visible ? row.implicitWidth + Theme.modulePadH * 2 : 0
    implicitHeight: parent ? parent.height : Theme.barHeight
    visible: sink !== null

    // Required for Quickshell to subscribe to sink property changes.
    PwObjectTracker {
        objects: [sink]
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Text {
            text: {
                if (muted) return bluetooth ? "󰟎" : "󰝟"
                if (bluetooth) return "󰋋"
                if (volume > 0.66) return "󰕾"
                if (volume > 0.33) return "󰖀"
                return "󰕿"
            }
            color: muted ? Theme.red : Theme.fg
            font.family: Theme.iconFontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Theme.fontWeight
            font.hintingPreference: Font.PreferFullHinting
            renderType: Text.NativeRendering
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: Math.round(volume * 100) + "%"
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
