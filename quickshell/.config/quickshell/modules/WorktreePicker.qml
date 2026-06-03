import QtQuick
import Quickshell
import Quickshell.Io
import "."

Picker {
    id: root

    open: WorktreePickerState.open
    onCloseRequested: WorktreePickerState.open = false

    placeholder: "worktrees"
    altLabel: "Enter: focus    Ctrl+W: close worktree"
    highlightField: "active"
    items: buildItems(NiriState.version, recencyFile.recency, NiriState.activeStack)

    onEnter: item => Quickshell.execDetached([Quickshell.env("HOME") + "/.config/niri/scripts/ws-jump-adjacent", "lovable-" + item.name])
    onAltAction: item => Quickshell.execDetached([Quickshell.env("HOME") + "/.config/niri/scripts/ws-close-worktree", item.name])

    FileView {
        id: recencyFile
        path: Quickshell.env("HOME") + "/.local/state/wt-stacks/ws/recency"
        watchChanges: true
        onFileChanged: reload()

        property var recency: []
        onLoaded: {
            try { recency = JSON.parse(text() || "[]") } catch (e) { recency = [] }
        }
        onLoadFailed: recency = []
    }

    function buildItems(_version, recency, activeStack) {
        const _ = _version
        const existing = []
        const wsMap = NiriState.workspaces
        for (const id in wsMap) {
            const n = wsMap[id].name || ""
            if (!n.startsWith("lovable-")) continue
            if (n === "lovable" || n === "lovable-main") continue
            existing.push(n.substring("lovable-".length))
        }
        const present = {}
        for (const n of existing) present[n] = true

        const activeBare = (activeStack || "").replace(/^lovable-/, "")
        const seen = {}
        const ordered = []
        for (const r of (recency || [])) {
            const bare = String(r).replace(/^lovable-/, "")
            if (present[bare] && !seen[bare]) { ordered.push(bare); seen[bare] = true }
        }
        for (const n of existing) {
            if (!seen[n]) { ordered.push(n); seen[n] = true }
        }

        return ordered.map(n => ({ name: n, label: n, active: n === activeBare }))
    }
}
