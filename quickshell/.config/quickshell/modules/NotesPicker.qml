import QtQuick
import Quickshell
import "."

Picker {
    id: root

    open: NotesPickerState.open
    onCloseRequested: NotesPickerState.open = false

    placeholder: "capture…"
    subtitleField: "hint"

    items: [
        { label: "Quick note",     type: "note",    hint: "inbox/YYYY-MM-DD-HHMM.md" },
        { label: "Todo",           type: "todo",    hint: "append to today's daily" },
        { label: "Daily note",     type: "daily",   hint: "journal/YYYY-MM-DD.md" },
        { label: "New plan",       type: "plan",    hint: "plans/" },
        { label: "New meeting",    type: "meeting", hint: "meetings/" },
        { label: "New reference",  type: "ref",     hint: "references/" },
        { label: "View notes",     type: "browse",  hint: "nvim at vault root · <leader>oR for recency" },
    ]

    onEnter: item => {
        if (!item || !item.type) return
        Quickshell.execDetached([
            Quickshell.env("HOME") + "/.config/quickshell/scripts/notes-capture",
            item.type
        ])
    }
}
