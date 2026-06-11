import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import "."

Rectangle {
    id: root

    required property var notification

    property bool shown: false
    property bool dismissing: false
    property bool collapsed: false

    opacity: (shown && !dismissing && !collapsed) ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    // Never animate height: it propagates to the PanelWindow's
    // implicitHeight, and per-frame layer-shell resizes render at ~10fps.
    // Fade first, snap the height once fully invisible.
    height: (collapsed && opacity === 0) ? 0 : implicitHeight
    clip: true

    Component.onCompleted: shown = true

    function beginDismiss() {
        if (dismissing) return
        dismissing = true
    }

    Timer {
        id: dismissDelay
        running: root.dismissing
        interval: 220
        onTriggered: if (notification) notification.dismiss()
    }

    readonly property bool isCritical: notification && notification.urgency === NotificationUrgency.Critical
    readonly property bool isInboxApp: {
        const a = (notification && notification.appName || "").toLowerCase()
        return a === "slack" || a === "endcord" || a === "kitty"
    }
    readonly property real effectiveTimeout: {
        if (!notification) return 5000
        if (isCritical) return 30000
        const t = notification.expireTimeout
        if (t < 0) return 5000
        if (t === 0) return 5000
        return t
    }

    implicitWidth: 360
    implicitHeight: content.implicitHeight + 24

    color: Theme.notch
    radius: Theme.radius
    border.color: isCritical ? Theme.red : Theme.hairline
    border.width: 1

    Column {
        id: content
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 12
        }
        spacing: 4

        Text {
            width: parent.width
            text: notification ? (notification.appName || "Notification") : ""
            color: Theme.fg_muted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 2
            font.weight: Theme.fontWeight
            renderType: Text.NativeRendering
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            text: notification ? notification.summary : ""
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight: 600
            renderType: Text.NativeRendering
            wrapMode: Text.WordWrap
            elide: Text.ElideRight
            maximumLineCount: 2
        }

        Text {
            width: parent.width
            visible: text.length > 0
            text: notification ? notification.body : ""
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 1
            font.weight: Theme.fontWeight
            renderType: Text.NativeRendering
            textFormat: Text.MarkdownText
            wrapMode: Text.WordWrap
            elide: Text.ElideRight
            maximumLineCount: 5
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.beginDismiss()
    }

    Timer {
        running: effectiveTimeout > 0 && !root.dismissing && !root.collapsed
        interval: effectiveTimeout
        onTriggered: {
            if (root.isInboxApp) root.collapsed = true
            else root.beginDismiss()
        }
    }
}
