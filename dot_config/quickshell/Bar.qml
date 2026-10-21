import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.UPower

// One bar per output; module order and behaviour follow dot_config/mangobar/config.jsonc.
PanelWindow {
    id: bar
    required property var modelData
    screen: modelData

    readonly property var mon: Hypr.monitors[modelData.name] || null
    property bool netAlt: false      // network module: left click toggles the up/down rates

    visible: Bus.barVisible
    anchors { top: true; left: true; right: true }
    implicitHeight: Theme.barHeight
    color: "transparent"
    WlrLayershell.namespace: "qs-bar"

    SystemClock { id: clock; precision: SystemClock.Minutes }

    function levelIcon(icons, pct) {
        let i = Math.floor(pct * icons.length / 101)
        return icons[Math.max(0, Math.min(icons.length - 1, i))]
    }
    function speed(kbps) {
        return kbps >= 1024 ? (kbps / 1024).toFixed(1) + "MB/s" : Math.round(kbps) + "KB/s"
    }
    function run(cmd) { Quickshell.execDetached(cmd) }

    readonly property var volIcons: [Theme.g(0xF057F), Theme.g(0xF0580), Theme.g(0xF057E)]
    readonly property var batIcons: [0xF008E, 0xF007A, 0xF007B, 0xF007C, 0xF007D, 0xF007E, 0xF007F, 0xF0080, 0xF0081, 0xF0082, 0xF0079].map(c => Theme.g(c))
    readonly property var sigIcons: [0xF092F, 0xF091F, 0xF0922, 0xF0925, 0xF0928].map(c => Theme.g(c))

    readonly property string title: bar.mon && Hypr.activeScreen === bar.mon.name && Hypr.activeToplevel ? Hypr.activeToplevel.title : ""
    readonly property real titleMax: Math.max(40, centerRow.x - appPill.width - tags.width - 3 * Theme.gap)

    readonly property var batt: UPower.displayDevice
    readonly property int battPct: batt ? Math.round(batt.percentage * 100) : 0

    function netText() {
        if (netAlt) return "\u2193" + speed(Net.rxKbps) + " \u2191" + speed(Net.txKbps)
        if (!Net.up) return Theme.g(0xEAD0) + " "
        if (Net.kind === 2)
            return Theme.g(0xF05A9) + " " + (Net.signalValid ? levelIcon(sigIcons, Net.signalPercent) : "") + " " + Net.ssid
        if (Net.kind === 1) return Theme.g(0xF0200) + " "
        return Theme.g(0xF1EB) + " "
    }
    function volText() {
        const bt = Audio.bluetooth ? Theme.g(0xF00AF) : ""
        const icon = Audio.muted ? Theme.g(0xF0581) : levelIcon(volIcons, Audio.percent)
        return (icon + " " + Audio.percent + "% " + bt).trim()
    }
    function battText() {
        const s = batt ? batt.state : 0     // UPowerDeviceState: 1 Charging, 4 FullyCharged
        const icon = s === 1 ? Theme.g(0xF0084) : s === 4 ? Theme.g(0xF0079) : levelIcon(batIcons, battPct)
        return icon + " " + battPct + "%" + (UPower.onBattery ? "" : " " + Theme.g(0xF492))
    }

    TrayMenu { id: trayMenu }

    Item {
        anchors.fill: parent
        anchors.topMargin: Theme.barMarginV
        anchors.bottomMargin: Theme.barMarginV
        anchors.leftMargin: Theme.barMarginH
        anchors.rightMargin: Theme.barMarginH

        // ---------------------------------------------------------- left
        RowLayout {
            id: leftRow
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            spacing: Theme.gap

            Pill {      // custom/applist
                id: appPill
                text: Theme.g(0xF003B)
                fg: Theme.accent
                textOffsetX: -1
                onClicked: Bus.launcherRequested()
            }
            Workspaces { id: tags; mon: bar.mon }
            Pill {      // window title: left = region screenshot, right = OCR
                visible: bar.title !== ""
                text: bar.title
                bg: Theme.accent
                fg: Theme.dark
                Layout.maximumWidth: bar.titleMax
                onClicked: button => bar.run(["bash", Theme.scripts + "/" + (button === Qt.RightButton ? "ocr.sh" : "screenshot.sh")])
            }
        }

        // -------------------------------------------------------- center
        RowLayout {
            id: centerRow
            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; bottom: parent.bottom }
            spacing: Theme.gap

            Pill { text: Qt.formatDateTime(clock.date, "dddd dd MMM") }     // clock#date  {:L%A %d %b}
            Pill { text: Qt.formatDateTime(clock.date, "HH:mm") }           // clock#time  {:L%H:%M}
        }

        // --------------------------------------------------------- right
        RowLayout {
            id: rightRow
            anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
            spacing: Theme.gap

            CustomModule {      // custom/record: only visible while recording
                command: [Theme.scripts + "/record.sh", "status"]
                bg: Theme.danger
                fg: Theme.dark
                onClicked: { bar.run([Theme.scripts + "/record.sh", "toggle"]); refreshSoon.restart() }
            }
            Tray {
                onMenuRequested: (handle, x) => { trayMenu.anchorX = x; trayMenu.handle = handle }
            }
            Pill {      // network: left = rates, right = nmtui
                text: bar.netText()
                bg: Net.up ? Theme.accent : Theme.danger
                fg: Theme.dark
                onClicked: button => {
                    if (button === Qt.RightButton) bar.run(["kitty", "--class", "nmtui", "-e", "nmtui"])
                    else { bar.netAlt = !bar.netAlt; Net.fast = bar.netAlt }
                }
            }
            Pill {      // pulseaudio: click = mute, wheel = +-5 %, right = pwvucontrol
                text: bar.volText()
                bg: Theme.accent
                fg: Theme.dark
                onClicked: button => {
                    if (button === Qt.RightButton) bar.run(["pwvucontrol"])
                    else Audio.toggleMute()
                }
                onScrolled: dir => dir > 0 ? Audio.up() : Audio.down()
            }
            Pill {      // cpu
                text: Theme.g(0xF2DB) + " " + Sys.cpu + "%"
                padding: 15
                onClicked: bar.run(["foot", "-e", "gotop"])
            }
            CustomModule {      // custom/memory
                command: [Theme.scripts + "/memory.sh"]
                interval: 5000
                prefix: Theme.g(0xEFC5) + " "
                onClicked: bar.run(["foot", "-e", "gotop"])
            }
            CustomModule {      // custom/brightness: click = next screen, wheel = up/down
                command: [Theme.scripts + "/knob.sh", "show"]
                onClicked: { bar.run([Theme.scripts + "/knob.sh", "screen"]); refreshSoon.restart() }
                onScrolled: dir => { bar.run([Theme.scripts + "/knob.sh", dir > 0 ? "up" : "down"]); refreshSoon.restart() }
            }
            Pill {      // battery: hidden on AC (hide-on-ac)
                visible: !!bar.batt && bar.batt.isPresent && UPower.onBattery
                text: bar.battText()
            }
            CustomModule {      // custom/caffeine
                command: [Theme.scripts + "/caffeine.sh", "show"]
                bg: Theme.accent
                fg: Theme.dark
                onClicked: { bar.run([Theme.scripts + "/caffeine.sh", "toggle"]); refreshSoon.restart() }
            }
            Pill {      // custom/power
                text: Theme.g(0xF32E)
                bg: Theme.accent
                fg: Theme.dark
                onClicked: Bus.sessionRequested()
            }
        }
    }

    // the scripts also signal us (see the integration patch); this covers the click itself
    Timer { id: refreshSoon; interval: 400; onTriggered: Bus.refresh() }
}
