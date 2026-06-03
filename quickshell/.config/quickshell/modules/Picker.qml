import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "."

PanelWindow {
    id: root

    property bool open: false
    signal closeRequested()
    property string placeholder: "Search…"
    property var items: []
    property string subtitleField: ""
    property string highlightField: ""
    property var onEnter: function(item) {}
    property var onEnterText: function(text) {}
    property bool freeText: false
    property var onAltAction: null
    property string altLabel: ""
    property int altKey: Qt.Key_W

    property string query: search ? search.text : ""
    property int selectedIndex: 0

    property bool active: false
    visible: active

    onOpenChanged: {
        if (open) { closeDelay.stop(); active = true }
        else closeDelay.restart()
    }
    Timer { id: closeDelay; interval: 300; onTriggered: root.active = false }

    onActiveChanged: {
        if (active && search) {
            search.text = ""
            selectedIndex = 0
            search.forceActiveFocus()
        }
    }
    onQueryChanged: selectedIndex = 0

    readonly property var filtered: {
        const q = query.trim().toLowerCase()
        if (q.length === 0) return items
        const out = []
        for (let i = 0; i < items.length; i++) {
            const it = items[i]
            const label = String(it.label || "").toLowerCase()
            const sub = subtitleField && it[subtitleField] ? String(it[subtitleField]).toLowerCase() : ""
            if (label.indexOf(q) >= 0 || (sub && sub.indexOf(q) >= 0)) out.push(it)
        }
        return out
    }

    function activate() {
        if (freeText) {
            const text = query.trim()
            if (text.length === 0) return
            onEnterText(text)
            closeRequested()
            return
        }
        if (filtered.length === 0) return
        const idx = Math.max(0, Math.min(selectedIndex, filtered.length - 1))
        onEnter(filtered[idx])
        closeRequested()
    }

    function altActivate() {
        if (!onAltAction || filtered.length === 0) return
        const idx = Math.max(0, Math.min(selectedIndex, filtered.length - 1))
        onAltAction(filtered[idx])
    }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-picker"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Rectangle {
        id: dim
        anchors.fill: parent
        color: "#000000"
        opacity: root.open ? 0.35 : 0
        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Keys.onEscapePressed: root.closeRequested()
        MouseArea {
            anchors.fill: parent
            onClicked: root.closeRequested()
        }
    }

    Rectangle {
        id: notch
        anchors {
            bottom: parent.bottom
            bottomMargin: root.open ? 80 : -(height + 40)
            horizontalCenter: parent.horizontalCenter

            Behavior on bottomMargin {
                NumberAnimation {
                    duration: 280
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: [0.32, 0.72, 0.0, 1.0, 1.0, 1.0]
                }
            }
        }
        width: 720
        height: 420

        color: Theme.notch
        radius: Theme.notchRadius
        border.color: Theme.hairline
        border.width: 1

        scale: root.open ? 1.0 : 0.96
        opacity: root.open ? 1.0 : 0.0
        Behavior on scale {
            NumberAnimation {
                duration: 190
                easing.type: Easing.BezierSpline
                easing.bezierCurve: [0.26, 0.08, 0.25, 1.0, 1.0, 1.0]
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: 190
                easing.type: Easing.BezierSpline
                easing.bezierCurve: [0.26, 0.08, 0.25, 1.0, 1.0, 1.0]
            }
        }

        Column {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            TextField {
                id: search
                width: parent.width
                placeholderText: root.placeholder
                color: Theme.fg
                placeholderTextColor: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.5)
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize + 2
                font.weight: Theme.fontWeight
                background: Rectangle {
                    color: "transparent"
                    border.color: Theme.hairline
                    border.width: 1
                    radius: Theme.radiusSm
                }
                padding: 10
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        root.closeRequested()
                        event.accepted = true
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.activate()
                        event.accepted = true
                    } else if (event.key === Qt.Key_Down
                            || (event.key === Qt.Key_J && (event.modifiers & Qt.ControlModifier))) {
                        if (root.filtered.length > 0)
                            root.selectedIndex = Math.min(root.selectedIndex + 1, root.filtered.length - 1)
                        event.accepted = true
                    } else if (event.key === Qt.Key_Up
                            || (event.key === Qt.Key_K && (event.modifiers & Qt.ControlModifier))) {
                        if (root.filtered.length > 0)
                            root.selectedIndex = Math.max(root.selectedIndex - 1, 0)
                        event.accepted = true
                    } else if (event.key === root.altKey && (event.modifiers & Qt.ControlModifier)) {
                        root.altActivate()
                        event.accepted = true
                    }
                }
            }

            ListView {
                id: list
                width: parent.width
                height: parent.height - search.height - parent.spacing - (footer.visible ? footer.height + parent.spacing : 0)
                clip: true
                model: root.filtered
                currentIndex: root.selectedIndex
                spacing: 2

                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    width: list.width
                    height: 36
                    color: index === root.selectedIndex
                        ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.10)
                        : "transparent"
                    radius: Theme.radiusSm

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.right: subtitleText.left
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData ? String(modelData.label || "?") : "?"
                        color: (root.highlightField && modelData && modelData[root.highlightField] === true)
                            ? Theme.cursor : Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        font.weight: Theme.fontWeight
                        renderType: Text.NativeRendering
                        elide: Text.ElideRight
                    }
                    Text {
                        id: subtitleText
                        visible: root.subtitleField && modelData && (modelData[root.subtitleField] || "").length > 0
                        text: modelData && root.subtitleField ? String(modelData[root.subtitleField] || "") : ""
                        color: Theme.fg_muted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 2
                        font.weight: Theme.fontWeight
                        renderType: Text.NativeRendering
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.selectedIndex = index
                            root.activate()
                        }
                    }
                }

                onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
            }

            Text {
                id: footer
                width: parent.width
                visible: root.altLabel.length > 0
                text: root.altLabel
                color: Theme.fg_muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 2
                renderType: Text.NativeRendering
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

}
