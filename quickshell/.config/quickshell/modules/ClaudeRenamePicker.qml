import QtQuick
import Quickshell
import "."

Picker {
    id: root

    open: ClaudeRenamePickerState.open
    onCloseRequested: ClaudeRenamePickerState.open = false

    placeholder: ClaudeRenamePickerState.sid
        ? ("session name → " + ClaudeRenamePickerState.sid.substring(0, 8))
        : "session name"
    freeText: true

    onEnterText: text => {
        const name = text.replace(/[^a-zA-Z0-9_-]/g, "")
        if (name.length === 0) return
        const sid = ClaudeRenamePickerState.sid
        if (!sid) return
        Quickshell.execDetached([
            Quickshell.env("HOME") + "/.config/niri/scripts/claude-rename",
            "--id", sid, name
        ])
    }
}
