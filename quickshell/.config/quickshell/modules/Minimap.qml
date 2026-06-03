import QtQuick
import "."

Item {
    id: root

    property string output: ""
    readonly property int maxSlots: 64

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
            model: root.maxSlots

            Item {
                id: cell
                required property int index
                readonly property var entry: index < root.entries.length ? root.entries[index] : null
                visible: entry !== null

                readonly property string kind: entry ? entry.kind : "gap"
                readonly property bool isBar: kind === "bar"
                readonly property bool isFocused: isBar && entry.focused === true
                readonly property bool isWsActive: isBar && entry.wsActive === true

                width: kind === "gap" ? 12 : 3
                height: Theme.barHeight - 4

                Rectangle {
                    visible: cell.isBar
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: cell.isFocused ? Theme.cursor
                         : cell.isWsActive ? Theme.fg
                         : Theme.dimmedFg
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
                    Behavior on width {
                        NumberAnimation {
                            duration: 110
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: [0.34, 1.56, 0.64, 1.0, 1.0, 1.0]
                        }
                    }
                    Behavior on height {
                        NumberAnimation {
                            duration: 110
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: [0.34, 1.56, 0.64, 1.0, 1.0, 1.0]
                        }
                    }
                    Behavior on y {
                        NumberAnimation {
                            duration: 110
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: [0.34, 1.56, 0.64, 1.0, 1.0, 1.0]
                        }
                    }
                    Behavior on color { ColorAnimation { duration: 110 } }
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
