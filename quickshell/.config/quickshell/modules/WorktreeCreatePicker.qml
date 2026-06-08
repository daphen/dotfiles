import QtQuick
import Quickshell
import Quickshell.Io
import "."

Picker {
    id: root

    open: WorktreeCreatePickerState.open
    onCloseRequested: WorktreeCreatePickerState.open = false

    placeholder: "workspace"
    altLabel: "Enter: open / create    Ctrl+W: close worktree"
    subtitleField: "kind"
    highlightField: "active"
    altKey: Qt.Key_W

    items: buildItems(NiriState.version, namesFile.labels, NiriState.activeStack)

    onEnter: item => {
        if (!item) return
        if (item.action === "create-local") {
            WorktreeCreatePickerState.open = false
            WorktreeNameInputPickerState.show("local")
            return
        }
        if (item.action === "create-lol") {
            WorktreeCreatePickerState.open = false
            WorktreeNameInputPickerState.show("lol")
            return
        }
        Quickshell.execDetached([Quickshell.env("HOME") + "/.config/niri/scripts/ws-jump-adjacent", "lovable-" + item.name])
    }

    onAltAction: item => {
        if (!item || item.action) return
        Quickshell.execDetached([Quickshell.env("HOME") + "/.config/niri/scripts/ws-close-worktree", item.name])
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

    function buildItems(_version, lovboxLabels, activeStack) {
        const _ = _version
        const lolNames = {}
        for (const claim in lovboxLabels) lolNames[lovboxLabels[claim]] = true

        const existing = []
        const wsMap = NiriState.workspaces
        for (const id in wsMap) {
            const n = wsMap[id].name || ""
            if (!n.startsWith("lovable-")) continue
            if (n === "lovable" || n === "lovable-main") continue
            existing.push(n.substring("lovable-".length))
        }

        const activeBare = (activeStack || "").replace(/^lovable-/, "")
        const create = [
            { action: "create-local", label: "+ Create local worktree", kind: "WT" },
            { action: "create-lol",   label: "+ Create Lovable-on-Lovable", kind: "LoL" },
        ]
        const wsItems = existing.map(n => ({
            name: n,
            label: n,
            kind: lolNames[n] ? "LoL" : "WT",
            active: n === activeBare,
        }))
        return create.concat(wsItems)
    }
}
