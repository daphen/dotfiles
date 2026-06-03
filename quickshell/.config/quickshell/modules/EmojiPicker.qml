import QtQuick
import Quickshell
import Quickshell.Io
import "."

Picker {
    id: root

    open: EmojiPickerState.open
    onCloseRequested: EmojiPickerState.open = false

    placeholder: "emoji"
    subtitleField: "subtitle"

    property var emojis: []

    onActiveChanged: if (active && emojis.length === 0) loadProc.running = true

    onEnter: item => {
        if (!item || !item.glyph) return
        Quickshell.execDetached(["sh", "-c", "printf '%s' '" + item.glyph.replace(/'/g, "'\\''") + "' | wl-copy && wtype '" + item.glyph.replace(/'/g, "'\\''") + "'"])
    }

    Process {
        id: loadProc
        command: [Quickshell.env("HOME") + "/.config/quickshell/scripts/emoji-data"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = (this.text || "").split("\n")
                const out = []
                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i]
                    if (!line) continue
                    const sp = line.indexOf(" ")
                    if (sp < 0) continue
                    const glyph = line.substring(0, sp)
                    let rest = line.substring(sp + 1)
                    let keywords = ""
                    const m = rest.match(/<small>\((.+)\)<\/small>\s*$/)
                    if (m) {
                        keywords = m[1]
                        rest = rest.substring(0, rest.length - m[0].length).trim()
                    }
                    out.push({
                        glyph: glyph,
                        label: glyph + "  " + rest,
                        subtitle: keywords
                    })
                }
                root.emojis = out
            }
        }
    }

    items: root.emojis
}
