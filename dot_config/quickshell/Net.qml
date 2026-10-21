pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Default-route interface, Wi-Fi SSID/signal, and throughput. scripts/net-status.sh
// prints "ifname|kind|ssid|dbm|rx_bytes|tx_bytes" (kind: wifi, ethernet, other).
Singleton {
    id: root
    property bool up: false
    property int kind: 0               // 0 other, 1 ethernet, 2 wifi (mangobar's net_kind)
    property string ifname: ""
    property string ssid: ""
    property bool signalValid: false
    property int dbm: 0
    property real rxKbps: 0
    property real txKbps: 0
    property bool fast: false          // 1 Hz while the up/down rate view is showing

    // mangobar: -90 dBm and below = 0 %, -70 dBm and above = 100 %
    readonly property int signalPercent: Math.max(0, Math.min(100, Math.floor((dbm + 90) * 100 / 20)))

    property real _rx: -1
    property real _tx: -1
    property double _t: 0

    function apply(out) {
        const p = out.trim().split("|")
        if (p.length < 6 || p[0] === "") {
            up = false; kind = 0; ifname = ""; ssid = ""; signalValid = false
            _rx = -1; _tx = -1
            return
        }
        up = true
        ifname = p[0]
        kind = p[1] === "wifi" ? 2 : (p[1] === "ethernet" ? 1 : 0)
        ssid = p[2]
        signalValid = p[3] !== ""
        dbm = signalValid ? parseInt(p[3]) : 0
        const rx = Number(p[4]), tx = Number(p[5]), now = Date.now()
        if (_rx >= 0 && now > _t) {
            const s = (now - _t) / 1000
            rxKbps = Math.max(0, (rx - _rx) / 1024 / s)
            txKbps = Math.max(0, (tx - _tx) / 1024 / s)
        }
        _rx = rx; _tx = tx; _t = now
    }

    Process {
        id: proc
        command: ["sh", Quickshell.shellPath("scripts/net-status.sh")]
        stdout: StdioCollector { onStreamFinished: root.apply(text) }
    }
    Timer {
        interval: root.fast ? 1000 : 3000
        running: true; repeat: true; triggeredOnStart: true
        onTriggered: if (!proc.running) proc.running = true
    }
}
