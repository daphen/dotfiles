import QtQuick
import Quickshell
import "."

PanelWindow {
    id: bar

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Theme.barHeight
    color: "transparent"

    Rectangle {
        id: notch
        anchors {
            top: parent.top
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
        }
        // Anchor-based layout (left/center/right) instead of Row flow so
        // the center group stays dead-center regardless of side widths.
        width: Math.max(
            leftGroup.implicitWidth + rightGroup.implicitWidth
                + centerGroup.implicitWidth + Theme.notchInnerGap * 2 + Theme.notchPadH * 2,
            Theme.notchMinWidth
        )

        color: Theme.notch
        topLeftRadius:     0
        topRightRadius:    0
        bottomLeftRadius:  Theme.notchRadius
        bottomRightRadius: Theme.notchRadius
        border.color: Theme.hairline
        border.width: 1

        Row {
            id: leftGroup
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
                leftMargin: Theme.notchPadH
            }
            spacing: 8

            DateText {}
            Weather {}
            Cpu {}
            Memory {}
        }

        Row {
            id: centerGroup
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
                bottom: parent.bottom
            }
            spacing: 0

            Minimap { output: bar.screen ? bar.screen.name : "" }
        }

        Row {
            id: rightGroup
            anchors {
                right: parent.right
                top: parent.top
                bottom: parent.bottom
                rightMargin: Theme.notchPadH
            }
            spacing: 8

            Inbox {}
            Dnd {}
            Network {}
            Audio {}
            Battery {}
            Clock {}
        }
    }

    readonly property string worktreeStack: {
        const _ = NiriState.version
        const name = NiriState.focusedWorkspaceName()
        if (!name.startsWith("lovable-")) return ""
        if (name === "lovable" || name === "lovable-deps") return ""
        return name.substring("lovable-".length)
    }

    Rectangle {
        id: worktreePill
        anchors {
            top: parent.top
            right: parent.right
        }
        visible: bar.worktreeStack.length > 0
        width: pillRow.implicitWidth + Theme.notchPadH * 2
        height: Theme.barHeight

        color: Theme.notch
        topLeftRadius:     0
        topRightRadius:    0
        bottomLeftRadius:  Theme.notchRadius
        bottomRightRadius: 0
        border.color: Theme.hairline
        border.width: 1

        Row {
            id: pillRow
            anchors.centerIn: parent
            spacing: 10

            Image {
                source: "file://" + Quickshell.env("HOME") + "/.local/share/icons/hicolor/512x512/apps/lovable.png"
                sourceSize.width: 16
                sourceSize.height: 16
                width: 16
                height: 16
                smooth: true
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: bar.worktreeStack
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
}
