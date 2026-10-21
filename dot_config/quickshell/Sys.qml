pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property int cpu: 0
    property real _total: 0
    property real _idle: 0

    function apply(t) {
        const f = t.trim().split(/\s+/).slice(1).map(Number)   // user nice system idle iowait irq softirq steal
        if (f.length < 5) return
        const idle = f[3] + f[4]
        let total = 0
        for (let i = 0; i < Math.min(f.length, 8); i++) total += f[i]
        if (_total > 0 && total > _total)
            cpu = Math.max(0, Math.min(100, Math.round(100 * (1 - (idle - _idle) / (total - _total)))))
        _total = total
        _idle = idle
    }

    Process {
        id: proc
        command: ["sh", Quickshell.shellPath("scripts/sys-stat.sh")]
        stdout: StdioCollector { onStreamFinished: root.apply(text) }
    }
    Timer {
        interval: 2000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: if (!proc.running) proc.running = true
    }
}
