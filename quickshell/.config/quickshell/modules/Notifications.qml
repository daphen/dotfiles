pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Singleton {
    id: root

    readonly property alias server: notifServer
    readonly property alias tracked: notifServer.trackedNotifications

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
