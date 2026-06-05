import QtQuick
import "."

Item {
    id: root

    implicitWidth: visible ? text.implicitWidth + Theme.modulePadH * 2 : 0
    implicitHeight: parent ? parent.height : Theme.barHeight
    visible: WpmState.value > 0

    Text {
        id: text
        anchors.centerIn: parent
        text: WpmState.value + " wpm"
        color: Theme.fg
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.weight: Theme.fontWeight
        font.hintingPreference: Font.PreferFullHinting
        renderType: Text.NativeRendering
    }
}
