import QtQuick
import Quickshell
import Quickshell.Bluetooth
import "."

Picker {
    id: root

    open: BluetoothPickerState.open
    onCloseRequested: BluetoothPickerState.open = false

    placeholder: "bluetooth"
    subtitleField: "subtitle"
    highlightField: "connected"
    altKey: Qt.Key_R
    altLabel: {
        const a = Bluetooth.defaultAdapter
        if (!a) return ""
        if (a.discovering) return "Enter: toggle connection    Ctrl+R: stop scanning"
        return "Enter: toggle connection    Ctrl+R: scan for new devices"
    }

    onEnter: item => {
        if (!item || !item.device) return
        if (item.device.connected) item.device.disconnect()
        else item.device.connect()
    }

    onAltAction: () => {
        const a = Bluetooth.defaultAdapter
        if (!a) return
        a.discovering = !a.discovering
    }

    items: {
        const a = Bluetooth.defaultAdapter
        if (!a) return []
        const out = []
        const devs = a.devices ? a.devices.values : []
        for (let i = 0; i < devs.length; i++) {
            const d = devs[i]
            if (!d.paired && !d.connected) continue
            const battery = d.batteryAvailable ? "  · " + Math.round(d.battery * 100) + "%" : ""
            let state
            if (d.pairing) state = "pairing…"
            else if (d.connected) state = "connected" + battery
            else state = "paired"
            out.push({
                device: d,
                label: d.name || d.deviceName || d.address,
                subtitle: state,
                connected: d.connected
            })
        }
        out.sort((a, b) => {
            if (a.connected !== b.connected) return a.connected ? -1 : 1
            return a.label.localeCompare(b.label)
        })
        return out
    }
}
