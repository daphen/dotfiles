import Quickshell
import QtQml
import "modules"

ShellRoot {
    id: root

    Component {
        id: barFactory
        Bar {}
    }

    Component {
        id: overlayFactory
        NotificationOverlay {}
    }

    Component {
        id: launcherFactory
        Launcher {}
    }

    Component {
        id: worktreePickerFactory
        WorktreePicker {}
    }

    Component.onCompleted: {
        for (const screen of Quickshell.screens) {
            barFactory.createObject(root, { screen: screen })
            overlayFactory.createObject(root, { screen: screen })
        }
        launcherFactory.createObject(root)
        worktreePickerFactory.createObject(root)
    }
}
