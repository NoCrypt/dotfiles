import QtQuick
import Quickshell
import Quickshell.Io

// mangobar "custom/*" module: runs a command, shows its stdout, hides itself when
// the output is empty. Polls every `interval` ms and re-runs on `qs ipc call bar refresh`
// (the replacement for mangobar's SIGRTMIN+N).
Pill {
    id: root

    property var command: []
    property int interval: 30000
    property string prefix: ""
    property string output: ""
    property bool _again: false

    text: prefix + output
    visible: output !== ""

    function run() {
        if (proc.running) _again = true
        else proc.running = true
    }

    Process {
        id: proc
        command: root.command
        stdout: StdioCollector { onStreamFinished: root.output = text.trim() }
        onExited: if (root._again) { root._again = false; proc.running = true }
    }
    Timer {
        interval: root.interval; running: true; repeat: true; triggeredOnStart: true
        onTriggered: root.run()
    }
    Connections {
        target: Bus
        function onRefresh() { root.run() }
    }
}
