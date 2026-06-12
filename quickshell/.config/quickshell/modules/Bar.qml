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

    // Outer = hairline-colored backdrop. Inner = notch fill, flush on top
    // (no top border) but inset 1px on left/right/bottom so those 3 edges
    // show as borders, including following the bottom rounded corners.
    Rectangle {
        id: notch
        anchors {
            top: parent.top
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
        }
        width: Math.max(
            leftGroup.implicitWidth + rightGroup.implicitWidth
                + centerGroup.implicitWidth + Theme.notchInnerGap * 2 + Theme.notchPadH * 2,
            Theme.notchMinWidth
        )

        color: Theme.hairline
        topLeftRadius:     0
        topRightRadius:    0
        bottomLeftRadius:  Theme.notchRadius
        bottomRightRadius: Theme.notchRadius

        Rectangle {
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                leftMargin: 1
                rightMargin: 1
                bottomMargin: 1
            }
            color: Theme.notch
            topLeftRadius:     0
            topRightRadius:    0
            bottomLeftRadius:  Theme.notchRadius - 1
            bottomRightRadius: Theme.notchRadius - 1
        }

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

    // WPM pill — mirror of worktreePill on the left side. Inner inset on
    // right + bottom + rounded bottom-right corner.
    Rectangle {
        id: wpmPill
        anchors {
            top: parent.top
            left: parent.left
        }
        width: wpmPillRow.implicitWidth + Theme.notchPadH * 2
        height: Theme.barHeight

        color: Theme.hairline
        topLeftRadius:     0
        topRightRadius:    0
        bottomLeftRadius:  0
        bottomRightRadius: Theme.notchRadius

        Rectangle {
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                rightMargin: 1
                bottomMargin: 1
            }
            color: Theme.notch
            topLeftRadius:     0
            topRightRadius:    0
            bottomLeftRadius:  0
            bottomRightRadius: Theme.notchRadius - 1
        }

        Row {
            id: wpmPillRow
            anchors.centerIn: parent
            // Matches the notch's effective inter-module gap:
            // modulePadH + group spacing + modulePadH.
            spacing: Theme.modulePadH * 2 + 8

            Row {
                spacing: 8
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    text: "󰌌" // nf-md-keyboard
                    color: Theme.fg
                    font.family: Theme.iconFontFamily
                    font.pixelSize: Theme.fontSize + 2
                    font.weight: Theme.fontWeight
                    font.hintingPreference: Font.PreferFullHinting
                    renderType: Text.NativeRendering
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    visible: WpmState.value === 0
                    text: "∞"
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize + 7
                    font.weight: Theme.fontWeight
                    font.hintingPreference: Font.PreferFullHinting
                    renderType: Text.NativeRendering
                    anchors.verticalCenter: parent.verticalCenter
                    // The glyph sits in the x-height band; its box's empty
                    // descender space makes true-center look high.
                    anchors.verticalCenterOffset: 1
                }

                Text {
                    text: (WpmState.value > 0 ? WpmState.value + " " : "") + "wpm"
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    font.weight: Theme.fontWeight
                    font.hintingPreference: Font.PreferFullHinting
                    renderType: Text.NativeRendering
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Item {
                visible: SpendState.current >= 0
                width: spendRow.implicitWidth
                height: spendRow.implicitHeight
                anchors.verticalCenter: parent.verticalCenter

                Row {
                    id: spendRow
                    spacing: 8

                    Text {
                        text: "󰚩" // nf-md-robot
                        color: Theme.fg_muted
                        font.family: Theme.iconFontFamily
                        font.pixelSize: Theme.fontSize + 2
                        font.weight: Theme.fontWeight
                        font.hintingPreference: Font.PreferFullHinting
                        renderType: Text.NativeRendering
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: {
                            const v = SpendState.current
                            const amount = v >= 1000
                                ? (v / 1000).toFixed(1) + "k"
                                : v >= 100 ? Math.round(v)
                                : v >= 10 ? v.toFixed(1)
                                : v.toFixed(2)
                            const tag = SpendState.mode === "day" ? "d"
                                : SpendState.mode === "month" ? "m" : "∀"
                            return "$" + amount + " " + tag
                        }
                        color: Theme.fg_muted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        font.weight: Theme.fontWeight
                        font.hintingPreference: Font.PreferFullHinting
                        renderType: Text.NativeRendering
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: SpendState.cycle()
                }
            }
        }
    }

    // Outer = hairline-colored "border" rectangle. Inner = notch-colored
    // fill, flush on top + right (no border there), inset 1px on the left
    // + bottom (the 1px gap of outer color reads as a border on those
    // sides + the rounded bottom-left corner). Pure Rectangle.border is
    // all-four-sides so this stacked-rect trick is needed for per-side.
    Rectangle {
        id: worktreePill
        anchors {
            top: parent.top
            right: parent.right
        }
        visible: bar.worktreeStack.length > 0
        width: pillRow.implicitWidth + Theme.notchPadH * 2
        height: Theme.barHeight

        color: Theme.hairline
        topLeftRadius:     0
        topRightRadius:    0
        bottomLeftRadius:  Theme.notchRadius
        bottomRightRadius: 0

        Rectangle {
            anchors {
                top: parent.top
                right: parent.right
                left: parent.left
                bottom: parent.bottom
                leftMargin: 1
                bottomMargin: 1
            }
            color: Theme.notch
            topLeftRadius:     0
            topRightRadius:    0
            bottomLeftRadius:  Theme.notchRadius - 1
            bottomRightRadius: 0
        }

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
