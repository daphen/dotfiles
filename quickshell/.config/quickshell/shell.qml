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

    Component {
        id: worktreeCreatePickerFactory
        WorktreeCreatePicker {}
    }

    Component {
        id: lovboxPickerFactory
        LovboxPicker {}
    }

    Component {
        id: bluetoothPickerFactory
        BluetoothPicker {}
    }

    Component {
        id: networkPickerFactory
        NetworkPicker {}
    }

    Component {
        id: asusProfilePickerFactory
        AsusProfilePicker {}
    }

    Component {
        id: emojiPickerFactory
        EmojiPicker {}
    }

    Component.onCompleted: {
        for (const screen of Quickshell.screens) {
            barFactory.createObject(root, { screen: screen })
            overlayFactory.createObject(root, { screen: screen })
        }
        launcherFactory.createObject(root)
        worktreePickerFactory.createObject(root)
        worktreeCreatePickerFactory.createObject(root)
        lovboxPickerFactory.createObject(root)
        bluetoothPickerFactory.createObject(root)
        networkPickerFactory.createObject(root)
        asusProfilePickerFactory.createObject(root)
        emojiPickerFactory.createObject(root)
    }
}
