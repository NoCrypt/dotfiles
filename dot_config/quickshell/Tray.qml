import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

// mangobar "tray": icon-size 18, spacing 10, #161b22 chip with 15 px padding.
// left = activate, middle = secondary activate, right = menu, wheel = scroll.
Rectangle {
    id: root
    signal menuRequested(var handle, real x)

    visible: SystemTray.items.values.length > 0
    color: Theme.subtle
    radius: Theme.radius
    Layout.fillHeight: true
    implicitHeight: Theme.barHeight - 2 * Theme.barMarginV
    implicitWidth: row.implicitWidth + 30

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 10

        Repeater {
            model: SystemTray.items
            delegate: Item {
                id: slot
                required property var modelData
                implicitWidth: 18
                implicitHeight: 18

                IconImage {
                    anchors.fill: parent
                    source: slot.modelData.icon
                }
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onClicked: mouse => {
                        const it = slot.modelData
                        if (mouse.button === Qt.MiddleButton) {
                            it.secondaryActivate()
                        } else if (mouse.button === Qt.RightButton || it.onlyMenu) {
                            if (it.hasMenu)
                                root.menuRequested(it.menu, slot.mapToItem(null, slot.width / 2, 0).x)
                        } else {
                            it.activate()
                        }
                    }
                    onWheel: wheel => slot.modelData.scroll(wheel.angleDelta.y, false)
                }
            }
        }
    }
}
