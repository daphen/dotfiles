import QtQuick
import Quickshell
import "."

Item {
    id: root

    readonly property string stack: {
        const _ = NiriState.version
        const name = NiriState.focusedWorkspaceName()
        if (!name.startsWith("lovable-")) return ""
        if (name === "lovable" || name === "lovable-deps") return ""
        return name.substring("lovable-".length)
    }

    implicitWidth: visible ? row.implicitWidth + Theme.modulePadH * 2 : 0
    implicitHeight: parent ? parent.height : Theme.barHeight
    visible: stack.length > 0

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Text {
            text: ""
            color: Theme.fg
            font.family: Theme.iconFontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Theme.fontWeight
            font.hintingPreference: Font.PreferFullHinting
            renderType: Text.NativeRendering
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: root.stack
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
