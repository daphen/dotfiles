pragma Singleton

import QtQuick
import Quickshell
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
        actionsSupported: false

        onNotification: notification => {
            console.log("[qs-notif] received:", notification.appName, "/", notification.summary, "/ body:", notification.body)
            if (DndState.active && notification.urgency !== NotificationUrgency.Critical) {
                console.log("[qs-notif] dismissed by DND")
                notification.dismiss()
                return
            }
            notification.tracked = true
            console.log("[qs-notif] tracked. count:", notifServer.trackedNotifications.values.length)
        }
    }
}
