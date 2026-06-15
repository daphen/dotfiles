import QtQuick
import Quickshell
import "."

Item {
    id: root

    property int _notifTick: 0
    Connections {
        target: Notifications.server
        function onTrackedNotificationsChanged() { root._notifTick++ }
    }

    readonly property var inboxCounts: {
        const _ = root._notifTick
        const model = Notifications.server ? Notifications.server.trackedNotifications : null
        const tracked = model ? model.values : []
        const counts = { slack: 0, endcord: 0 }
        for (let i = 0; i < tracked.length; i++) {
            const app = (tracked[i].appName || "").toLowerCase()
            if (app === "slack" || app === "slk") counts.slack++
            else if (app === "endcord") counts.endcord++
        }
        return counts
    }
    readonly property int total: inboxCounts.slack + inboxCounts.endcord

    implicitWidth: visible ? row.implicitWidth + Theme.modulePadH * 2 : 0
    implicitHeight: parent ? parent.height : Theme.barHeight
    visible: total > 0

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached([Quickshell.env("HOME") + "/.config/niri/scripts/inbox-jump"])
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 10

        Repeater {
            model: [
                { app: "slack",   icon: "󰒱", count: root.inboxCounts.slack },
                { app: "endcord", icon: "󰙯", count: root.inboxCounts.endcord }
            ]
            delegate: Row {
                required property var modelData
                visible: modelData.count > 0
                spacing: 4
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    text: modelData.icon
                    color: Theme.cursor
                    font.family: Theme.iconFontFamily
                    font.pixelSize: Theme.fontSize
                    font.weight: Theme.fontWeight
                    font.hintingPreference: Font.PreferFullHinting
                    renderType: Text.NativeRendering
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    visible: modelData.count > 1
                    text: modelData.count
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 2
                    font.weight: Theme.fontWeight
                    renderType: Text.NativeRendering
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }
}
