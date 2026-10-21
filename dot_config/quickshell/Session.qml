import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// wlogout replacement: same five buttons and keys (l m d r s), same dim background
// (rgba(13,17,23,.78)), same icons from ~/.config/mango/wlogout/icons, hover = rgba(88,166,255,.3).
// Namespace "logout_dialog" keeps mango's zoom layer_rule.
Scope {
    id: root
    property bool open: false
    function toggle() { open = !open }
    function close() { open = false }

    readonly property var buttons: [
        { id: "lock",     label: "Lock",     key: Qt.Key_L, icon: "lock.png",    run: () => Actions.lock() },
        { id: "logout",   label: "Logout",   key: Qt.Key_M, icon: "logout.png",  run: () => Actions.logout() },
        { id: "shutdown", label: "Shutdown", key: Qt.Key_D, icon: "power.png",   run: () => Actions.shutdown() },
        { id: "reboot",   label: "Reboot",   key: Qt.Key_R, icon: "restart.png", run: () => Actions.reboot() },
        { id: "suspend",  label: "Suspend",  key: Qt.Key_S, icon: "sleep.png",   run: () => Actions.suspend() }
    ]

    function activate(b) { close(); b.run() }

    Variants {
        model: Quickshell.screens
        delegate: PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            visible: root.open
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "#c70d1117"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "logout_dialog"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            onVisibleChanged: if (visible) keys.forceActiveFocus()

            MouseArea { anchors.fill: parent; onClicked: root.close() }

            Item {
                id: keys
                anchors.fill: parent
                focus: true
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) { root.close(); event.accepted = true; return }
                    for (const b of root.buttons) {
                        if (event.key === b.key) { root.activate(b); event.accepted = true; return }
                    }
                }
            }

            RowLayout {
                anchors.fill: parent
                spacing: 0
                Repeater {
                    model: root.buttons
                    delegate: Item {
                        id: cell
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Rectangle {
                            anchors.fill: parent
                            anchors.topMargin: 120; anchors.bottomMargin: 120      // wlogout: margin-top/bottom 120px
                            radius: 20
                            color: area.containsMouse ? "#4d58a6ff" : "transparent"
                            Behavior on color { ColorAnimation { duration: 300 } }

                            Image {
                                anchors.centerIn: parent
                                readonly property real base: Math.min(parent.width, parent.height)
                                width: base * (area.containsMouse ? 0.8 : 0.6)     // background-size 60 % -> 80 %
                                height: width
                                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                                source: "file://" + Theme.wlogoutIcons + "/" + cell.modelData.icon
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                            }
                            Text {
                                anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 14 }
                                text: cell.modelData.label
                                color: Theme.fg
                                font.family: Theme.fontFamily; font.pixelSize: 16; font.bold: true
                            }
                            MouseArea {
                                id: area
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: root.activate(cell.modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}
