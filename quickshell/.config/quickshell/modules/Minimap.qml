import QtQuick
import "."

Item {
    id: root

    property string output: ""

    implicitWidth: Math.max(row.implicitWidth, 100)
    implicitHeight: parent ? parent.height : Theme.barHeight

    readonly property var entries: {
        const _ = NiriState.version
        return NiriState.minimapEntries(root.output)
    }

    Row {
        id: row
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 1
        spacing: 6

        Repeater {
            model: root.entries

            Item {
                id: cell
                required property var modelData

                readonly property string kind: cell.modelData ? cell.modelData.kind : "gap"
                readonly property bool isBar: kind === "bar"
                readonly property bool isFocused: isBar && cell.modelData.focused === true
                readonly property bool isWsActive: isBar && cell.modelData.wsActive === true

                width: kind === "gap" ? 12 : 3
                height: Theme.barHeight - 4

                Rectangle {
                    visible: cell.isBar
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: {
                        if (cell.isFocused) return Theme.cursor
                        if (cell.isWsActive) return Theme.fg
                        return Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.55)
                    }
                    width: {
                        if (cell.isFocused) return 3
                        if (cell.isWsActive) return 2
                        return 2
                    }
                    height: {
                        if (cell.isFocused) return 28
                        if (cell.isWsActive) return 21
                        return 17
                    }
                    y: {
                        const baseline = 22
                        if (cell.isFocused) return baseline - 18
                        if (cell.isWsActive) return baseline - 17
                        return baseline - 15
                    }
                    radius: 1
                    Behavior on width  { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    Behavior on height { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    Behavior on y      { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    Behavior on color  { ColorAnimation { duration: 120 } }
                }

                Rectangle {
                    visible: cell.kind === "dot"
                    anchors.centerIn: parent
                    width: 3
                    height: 3
                    radius: 1.5
                    color: Theme.fg
                }
            }
        }
    }
}
