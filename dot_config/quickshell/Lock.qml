import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam

// swaylock-effects replacement (EXPERIMENTAL, off by default: Theme.qsLock).
// Like `screenshots` + `effect-blur`: grim captures every output first, then the session is
// locked and each lock surface shows its blurred capture with the clock ring on top.
// If the shell dies while locked the session STAYS locked (ext-session-lock semantics):
// test `qs ipc call lock lock` with a spare TTY (Ctrl+Alt+F3) before relying on it.
Scope {
    id: root

    readonly property bool locked: sessionLock.locked
    readonly property string runtime: Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"
    property var shots: ({})
    property string password: ""
    property string state: "idle"          // idle | verifying | wrong
    property bool busy: false

    readonly property color ringColor: state === "verifying" ? Theme.accent : state === "wrong" ? Theme.danger : Theme.muted
    readonly property color textColor: state === "verifying" ? Theme.accent : state === "wrong" ? Theme.danger : Theme.fg
    readonly property color insideColor: state === "wrong" ? "#e6161b22" : "#e60d1117"

    function lock() {
        if (sessionLock.locked || busy) return
        busy = true
        const names = Quickshell.screens.map(s => s.name)
        capture.command = ["sh", "-c",
            'for o in "$@"; do grim -o "$o" "$XDG_RUNTIME_DIR/qs-lock-$o.png" || true; done', "sh"].concat(names)
        capture.running = true
        fallback.start()            // never leave the session unlocked because grim hangs
    }
    function engage() {
        if (sessionLock.locked) return
        fallback.stop()
        const haveShots = !capture.running
        if (capture.running) capture.running = false
        const m = {}
        if (haveShots)
            for (const s of Quickshell.screens) m[s.name] = "file://" + runtime + "/qs-lock-" + s.name + ".png"
        shots = m
        password = ""; state = "idle"
        sessionLock.locked = true
        busy = false
        pam.start()
    }
    function submit() {
        if (!pam.responseRequired || password === "") return
        state = "verifying"
        pam.respond(password)
        password = ""
    }

    Process { id: capture; onExited: root.engage() }
    Timer { id: fallback; interval: 700; onTriggered: root.engage() }
    Process { id: cleanup }

    PamContext {
        id: pam
        config: Theme.pamConfig
        onCompleted: result => {
            if (result === PamResult.Success) {
                sessionLock.locked = false
                root.state = "idle"
            } else {
                root.state = "wrong"
                wrongTimer.restart()
                pam.start()
            }
        }
    }
    Timer { id: wrongTimer; interval: 1200; onTriggered: if (root.state === "wrong") root.state = "idle" }

    // idle.sh looks for this flag file to know the session is locked
    Connections {
        target: sessionLock
        function onLockedChanged() {
            if (sessionLock.locked) {
                cleanup.command = ["sh", "-c", ': > "$XDG_RUNTIME_DIR/qs-locked"']
            } else {
                cleanup.command = ["sh", "-c", 'rm -f "$XDG_RUNTIME_DIR/qs-locked" "$XDG_RUNTIME_DIR"/qs-lock-*.png']
            }
            cleanup.running = true
        }
    }

    SystemClock { id: clock; precision: SystemClock.Minutes }

    WlSessionLock {
        id: sessionLock

        WlSessionLockSurface {
            id: surface
            color: Theme.dark

            Image {
                id: shot
                anchors.fill: parent
                source: surface.screen ? (root.shots[surface.screen.name] || "") : ""
                fillMode: Image.PreserveAspectCrop
                cache: false
                visible: false
            }
            MultiEffect {                       // effect-blur=15x5
                anchors.fill: parent
                source: shot
                visible: shot.status === Image.Ready
                blurEnabled: true
                blur: 1.0
                blurMax: 48
            }

            Item {
                id: input
                anchors.fill: parent
                focus: true
                Component.onCompleted: forceActiveFocus()
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) root.submit()
                    else if (event.key === Qt.Key_Backspace) root.password = root.password.slice(0, -1)
                    else if (event.key === Qt.Key_Escape) root.password = ""
                    else if (event.text.length === 1 && event.text >= " ") root.password += event.text
                    else return
                    hl.angle = Math.random() * 360
                    hlTimer.restart()
                    event.accepted = true
                }
            }

            Rectangle {                         // indicator-radius=130, thickness=8
                id: ring
                anchors.centerIn: parent
                width: 260; height: 260; radius: 130
                color: root.insideColor
                border.width: 8
                border.color: root.ringColor

                Shape {                         // key-hl: a short accent arc per keypress
                    id: hl
                    property real angle: 0
                    anchors.fill: parent
                    visible: hlTimer.running
                    ShapePath {
                        strokeColor: root.password === "" ? Theme.danger : Theme.accent
                        strokeWidth: 8
                        fillColor: "transparent"
                        capStyle: ShapePath.FlatCap
                        PathAngleArc {
                            centerX: ring.width / 2; centerY: ring.height / 2
                            radiusX: ring.width / 2 - 4; radiusY: ring.height / 2 - 4
                            startAngle: hl.angle; sweepAngle: 60
                        }
                    }
                }
                Timer { id: hlTimer; interval: 180 }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 0
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: Qt.formatDateTime(clock.date, "HH:mm")
                        color: root.textColor
                        font.family: Theme.fontFamily; font.pixelSize: 42
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: Qt.formatDateTime(clock.date, "dddd dd MMMM")
                        color: root.textColor
                        font.family: Theme.fontFamily; font.pixelSize: 14
                    }
                }
            }
        }
    }
}
