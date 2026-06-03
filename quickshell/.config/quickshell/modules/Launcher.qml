import QtQuick
import Quickshell
import "."

Picker {
    id: root

    open: LauncherState.open
    onCloseRequested: LauncherState.open = false

    placeholder: "Search applications…"
    subtitleField: "subtitle"

    items: {
        const all = DesktopEntries.applications.values
        const out = []
        for (let i = 0; i < all.length; i++) {
            const app = all[i]
            if (app.noDisplay) continue
            out.push({
                app: app,
                label: app.name || app.id || "?",
                subtitle: app.genericName || ""
            })
        }
        out.sort((a, b) => a.label.localeCompare(b.label))
        return out
    }

    onEnter: item => {
        if (item && item.app && item.app.execute) item.app.execute()
    }
}
