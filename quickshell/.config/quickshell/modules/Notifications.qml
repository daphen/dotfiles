pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import "."

Singleton {
    id: root

    readonly property alias server: notifServer
    readonly property alias tracked: notifServer.trackedNotifications

    readonly property var appIdToNotifAppName: ({
        "endcord": "endcord",
        "Slack":   "slack",
        "claude":  "kitty",
        "kitty":   "kitty"
    })

    readonly property string focusedApp: {
        const _ = NiriState.version
        return NiriState.focusedAppId()
    }

    function _summaryWorkspace(summary) {
        // "Claude · lovable.daphen-1230-publish-progress" → "lovable-1230-publish-progress"
        const m = (summary || "").match(/lovable\.daphen-(\S+)/)
        return m ? "lovable-" + m[1] : ""
    }

    onFocusedAppChanged: {
        const notifApp = appIdToNotifAppName[focusedApp]
        if (!notifApp) return
        const all = notifServer.trackedNotifications.values.slice()
        const isKitty = notifApp === "kitty"
        const focusedWs = isKitty ? NiriState.focusedWorkspaceName() : ""
        for (let i = 0; i < all.length; i++) {
            const n = all[i]
            if ((n.appName || "").toLowerCase() !== notifApp) continue
            if (isKitty) {
                const notifWs = _summaryWorkspace(n.summary)
                // Only dismiss when the notification's workspace marker matches
                // the focused window's workspace. Generic kitty notifications
                // (no marker) stay so the pill keeps reflecting them.
                if (!notifWs || notifWs !== focusedWs) continue
            }
            n.dismiss()
        }
    }

    NotificationServer {
        id: notifServer
        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        imageSupported: true
        actionsSupported: true

        onNotification: notification => {
            if (DndState.active && notification.urgency !== NotificationUrgency.Critical) {
                notification.dismiss()
                return
            }
            const app = (notification.appName || "").toLowerCase()
            if (app === "kitty") {
                const body = notification.body || ""
                const summary = notification.summary || ""
                const others = notifServer.trackedNotifications.values
                let keepNew = true
                for (let i = 0; i < others.length; i++) {
                    const o = others[i]
                    if (o === notification) continue
                    if ((o.appName || "").toLowerCase() !== "kitty") continue
                    if ((o.body || "") !== body) continue
                    // Prefer whichever summary is longer (workspace-tagged > generic).
                    if ((o.summary || "").length >= summary.length) keepNew = false
                    else o.dismiss()
                }
                if (!keepNew) {
                    notification.dismiss()
                    return
                }
            }
            notification.tracked = true
        }
    }

    function _findById(id) {
        const num = parseInt(id)
        const all = notifServer.trackedNotifications.values
        for (let i = 0; i < all.length; i++) if (all[i].id === num) return all[i]
        return null
    }

    IpcHandler {
        target: "notifications"

        function list(): string {
            const all = notifServer.trackedNotifications.values
            const out = []
            for (let i = 0; i < all.length; i++) {
                const n = all[i]
                out.push({
                    id: n.id,
                    app_name: n.appName,
                    summary: n.summary,
                    body: n.body
                })
            }
            return JSON.stringify(out)
        }

        function invoke(id: string): string {
            const n = root._findById(id)
            if (!n) return "no-such-notification"
            const actions = n.actions || []
            for (let i = 0; i < actions.length; i++) {
                if (actions[i].identifier === "default" || actions[i].name === "default") {
                    actions[i].invoke()
                    return "invoked"
                }
            }
            if (actions.length > 0) {
                actions[0].invoke()
                return "invoked-first"
            }
            return "no-actions"
        }

        function dismiss(id: string): string {
            const n = root._findById(id)
            if (!n) return "no-such-notification"
            n.dismiss()
            return "dismissed"
        }

        function dismissAll(): string {
            const all = notifServer.trackedNotifications.values.slice()
            for (let i = 0; i < all.length; i++) all[i].dismiss()
            return "dismissed " + all.length
        }
    }
}
