import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// Themed tray menu (mangobar style.css: bg #161b22, border #30363d, radius 12, 14 px,
// hover #1f6feb). A transparent overlay catches clicks outside so the menu closes.
PanelWindow {
    id: win
    property var handle: null
    property real anchorX: 0

    visible: handle !== null
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-tray-menu"

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onClicked: win.handle = null
    }

    Rectangle {
        id: panel
        x: Math.max(8, Math.min(win.width - width - 8, win.anchorX - width / 2))
        y: Theme.barHeight + 2
        width: Math.max(180, list.implicitWidth + 16)
        height: list.implicitHeight + 16
        radius: 12
        color: Theme.subtle
        border.color: Theme.border
        border.width: 1

        MenuList {
            id: list
            x: 8; y: 8
            width: panel.width - 16
            handle: win.handle
            onDone: win.handle = null
        }
    }
}
