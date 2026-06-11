import QtQuick
import Quickshell
import Quickshell.Wayland
import "."

PanelWindow {
    id: root

    anchors {
        top: true
        right: true
    }

    margins.top: Theme.barHeight / 2
    margins.right: 16

    // Only render on the focused output — duplicate toasts across monitors
    // are distracting when working on one screen.
    readonly property bool onFocusedScreen: {
        const _ = NiriState.version
        return screen && screen.name === NiriState.focusedOutput()
    }
    visible: onFocusedScreen && Notifications.tracked.values.length > 0

    implicitWidth: 380
    implicitHeight: Math.max(toastColumn.implicitHeight + 16, 1)
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-notifications"

    Column {
        id: toastColumn
        anchors {
            top: parent.top
            right: parent.right
            left: parent.left
            topMargin: 0
            leftMargin: 8
            rightMargin: 8
        }
        spacing: 8

        move: Transition {
            NumberAnimation { properties: "y"; duration: 150; easing.type: Easing.OutCubic }
        }

        Repeater {
            model: Notifications.tracked

            Toast {
                required property var modelData
                notification: modelData
                width: 360
            }
        }
    }
}
