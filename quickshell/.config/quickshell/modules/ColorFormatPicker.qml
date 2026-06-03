import QtQuick
import Quickshell
import Quickshell.Io
import "."

Picker {
    id: root

    open: ColorFormatPickerState.open
    onCloseRequested: ColorFormatPickerState.open = false

    placeholder: "color format"
    subtitleField: "subtitle"
    highlightField: "current"

    readonly property string formatPath: Quickshell.env("HOME") + "/.config/hyprpicker/format"

    property string currentFormat: "hex"

    FileView {
        path: formatPath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.currentFormat = (text() || "").trim() || "hex"
        onLoadFailed: root.currentFormat = "hex"
    }

    items: [
        { value: "hex",  label: "hex",  subtitle: "#RRGGBB",     current: root.currentFormat === "hex"  },
        { value: "rgb",  label: "rgb",  subtitle: "rgb(r, g, b)", current: root.currentFormat === "rgb"  },
        { value: "hsl",  label: "hsl",  subtitle: "hsl(h, s%, l%)", current: root.currentFormat === "hsl"  },
        { value: "cmyk", label: "cmyk", subtitle: "c,m,y,k",     current: root.currentFormat === "cmyk" }
    ]

    onEnter: item => {
        if (!item || !item.value) return
        const safe = String(item.value).replace(/'/g, "'\\''")
        Quickshell.execDetached(["sh", "-c",
            "mkdir -p \"$(dirname '" + formatPath + "')\" && " +
            "printf '%s' '" + safe + "' > '" + formatPath + "' && " +
            "notify-send 'Color Picker' 'Format set to " + safe + "'"
        ])
    }
}
