import QtQuick
import Quickshell
import Quickshell.Io
import "."

Picker {
    id: root

    open: LovboxPickerState.open
    onCloseRequested: LovboxPickerState.open = false

    placeholder: "lovbox"
    subtitleField: "subtitle"

    onEnter: item => {
        if (!item || !item.input) return
        Quickshell.execDetached(["kitty", "--title", "lovssh: " + item.input,
                                 "fish", "-c",
                                 "lovssh '" + item.input.replace(/'/g, "'\\''") + "'; read -P 'Press enter to close: '"])
    }

    FileView {
        id: historyFile
        path: Quickshell.env("HOME") + "/.local/state/lovssh/history.jsonl"
        watchChanges: true
        onFileChanged: reload()

        property var lines: []
        onLoaded: lines = (text() || "").split("\n").filter(l => l.length > 0)
        onLoadFailed: lines = []
    }

    FileView {
        id: namesFile
        path: Quickshell.env("HOME") + "/.local/state/lovssh/names.json"
        watchChanges: true
        onFileChanged: reload()

        property var labels: ({})
        onLoaded: {
            try { labels = JSON.parse(text() || "{}") } catch (e) { labels = {} }
        }
        onLoadFailed: labels = ({})
    }

    function relTime(ts) {
        const t = Date.parse(ts)
        if (isNaN(t)) return ts
        const diff = (Date.now() - t) / 1000
        if (diff < 60) return "just now"
        if (diff < 3600) return Math.floor(diff / 60) + "m ago"
        if (diff < 86400) return Math.floor(diff / 3600) + "h ago"
        if (diff < 604800) return Math.floor(diff / 86400) + "d ago"
        const d = new Date(t)
        return d.toISOString().substring(0, 10)
    }

    items: {
        // Group history by claim, keep most-recent per claim, sort desc by ts.
        const byClaim = {}
        for (const line of historyFile.lines) {
            try {
                const e = JSON.parse(line)
                if (!e.claim) continue
                const prev = byClaim[e.claim]
                if (!prev || (e.timestamp || "") > (prev.timestamp || "")) byClaim[e.claim] = e
            } catch (err) {}
        }
        const entries = Object.values(byClaim).sort((a, b) => (a.timestamp || "") < (b.timestamp || "") ? 1 : -1)
        const labels = namesFile.labels || {}
        return entries.map(e => {
            const id = labels[e.claim] || (e.project_id ? e.project_id.substring(0, 8) : e.claim.substring(0, 8))
            const branch = e.branch ? "(" + e.branch + ")  " : ""
            return {
                input: e.input || "",
                label: id,
                subtitle: branch + root.relTime(e.timestamp)
            }
        })
    }
}
