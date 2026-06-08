import Quickshell
import QtQml
import "modules"

ShellRoot {
    id: root

    // Per-screen surfaces — Variants reconciles when monitors come and
    // go, so undocking doesn't leave an orphan layer-shell window from
    // the disconnected screen (which niri then framed as a regular
    // toplevel with an empty transparent body).
    Variants {
        model: Quickshell.screens
        Bar { required property var modelData; screen: modelData }
    }

    Variants {
        model: Quickshell.screens
        NotificationOverlay { required property var modelData; screen: modelData }
    }

    Launcher {}
    WorktreePicker {}
    WorktreeCreatePicker {}
    WorktreeNameInputPicker {}
    LovboxPicker {}
    BluetoothPicker {}
    NetworkPicker {}
    AsusProfilePicker {}
    EmojiPicker {}
    ClaudeRenamePicker {}
    ColorFormatPicker {}
    NotesPicker {}
}
