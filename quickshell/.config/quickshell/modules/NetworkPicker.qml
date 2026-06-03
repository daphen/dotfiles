import QtQuick
import Quickshell
import Quickshell.Io
import "."

Picker {
    id: root

    open: NetworkPickerState.open
    onCloseRequested: NetworkPickerState.open = false

    placeholder: "wifi"
    subtitleField: "subtitle"
    highlightField: "active"
    altKey: Qt.Key_R
    altLabel: "Enter: connect / disconnect    Ctrl+R: rescan"

    property var networks: []
    property var savedSsids: ({})

    onEnter: item => {
        if (!item || !item.ssid) return
        if (item.active) {
            Quickshell.execDetached(["nmcli", "connection", "down", item.ssid])
            return
        }
        if (item.saved) {
            Quickshell.execDetached(["nmcli", "connection", "up", item.ssid])
            return
        }
        if (item.open) {
            Quickshell.execDetached(["nmcli", "device", "wifi", "connect", item.ssid])
            return
        }
        const safe = item.ssid.replace(/'/g, "'\\''")
        const inner =
            "read -srp 'Password for " + safe + ": ' pw; echo; " +
            "nmcli device wifi connect '" + safe + "' password \"$pw\"; " +
            "code=$?; " +
            "if [ $code -ne 0 ]; then read -rp 'Connection failed (press enter to close): '; fi"
        Quickshell.execDetached(["kitty", "--class", "lovable_picker", "bash", "-c", inner])
    }

    onAltAction: () => Quickshell.execDetached(["nmcli", "device", "wifi", "rescan"])

    function refresh() {
        if (!root.active) return
        listProc.running = true
        savedProc.running = true
    }

    onActiveChanged: if (active) refresh()

    Timer {
        running: root.active
        interval: 4000
        repeat: true
        onTriggered: root.refresh()
    }

    Process {
        id: listProc
        command: ["nmcli", "-t", "-e", "no", "-f", "ACTIVE,SSID,SIGNAL,SECURITY", "device", "wifi", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = []
                const seen = {}
                for (const line of (this.text || "").split("\n")) {
                    if (!line) continue
                    const parts = line.split(":")
                    if (parts.length < 4) continue
                    const active = parts[0] === "yes"
                    const ssid = parts[1]
                    const signal = parseInt(parts[2]) || 0
                    const security = parts.slice(3).join(":") || "--"
                    if (!ssid || seen[ssid]) continue
                    seen[ssid] = true
                    out.push({ active, ssid, signal, security })
                }
                root.networks = out
            }
        }
    }

    Process {
        id: savedProc
        command: ["nmcli", "-t", "-e", "no", "-f", "NAME,TYPE", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                const saved = {}
                for (const line of (this.text || "").split("\n")) {
                    if (!line) continue
                    const idx = line.lastIndexOf(":")
                    if (idx < 0) continue
                    const name = line.substring(0, idx)
                    const type = line.substring(idx + 1)
                    if (type === "802-11-wireless") saved[name] = true
                }
                root.savedSsids = saved
            }
        }
    }

    items: {
        const out = []
        for (const n of root.networks) {
            const secured = n.security && n.security !== "--" && n.security !== ""
            const subtitleParts = []
            if (n.active) subtitleParts.push("connected")
            else if (root.savedSsids[n.ssid]) subtitleParts.push("saved")
            if (secured) subtitleParts.push(n.security)
            else subtitleParts.push("open")
            subtitleParts.push(n.signal + "%")
            out.push({
                ssid: n.ssid,
                label: n.ssid,
                subtitle: subtitleParts.join("  ·  "),
                active: n.active,
                saved: root.savedSsids[n.ssid] === true,
                open: !secured
            })
        }
        out.sort((a, b) => {
            if (a.active !== b.active) return a.active ? -1 : 1
            const ai = root.networks.find(n => n.ssid === a.ssid)
            const bi = root.networks.find(n => n.ssid === b.ssid)
            return (bi ? bi.signal : 0) - (ai ? ai.signal : 0)
        })
        return out
    }
}
