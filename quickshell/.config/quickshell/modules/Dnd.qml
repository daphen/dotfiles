import QtQuick
import Quickshell
import "."

Item {
    id: root

    implicitWidth: visible ? text.implicitWidth + Theme.modulePadH * 2 : 0
    implicitHeight: parent ? parent.height : Theme.barHeight
    visible: DndState.active

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: DndState.toggle()
    }

    Text {
        id: text
        anchors.centerIn: parent
        text: "󰂛"
        color: Theme.fg
        font.family: Theme.iconFontFamily
        font.pixelSize: Theme.fontSize
        font.weight: Theme.fontWeight
        font.hintingPreference: Font.PreferFullHinting
        renderType: Text.NativeRendering
    }
}
