import QtQuick
import QtQuick.Layouts
import Quickshell

// One level of a tray (dbusmenu) menu. Submenus expand inline, one level deeper.
ColumnLayout {
    id: root
    property var handle: null
    property int depth: 0
    signal done()

    spacing: 0

    QsMenuOpener { id: opener; menu: root.handle }

    Repeater {
        model: opener.children
        delegate: Item {
            id: row
            required property var modelData
            property bool expanded: false

            Layout.fillWidth: true
            implicitWidth: label.implicitWidth + 28 + root.depth * 14
            implicitHeight: modelData.isSeparator ? 9 : entryRect.height + sub.height

            Rectangle {      // separator
                visible: row.modelData.isSeparator
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left; anchors.right: parent.right
                anchors.leftMargin: 8; anchors.rightMargin: 8
                height: 1
                color: Theme.border
            }

            Rectangle {
                id: entryRect
                visible: !row.modelData.isSeparator
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                height: 28
                radius: 6
                color: hover.containsMouse && row.modelData.enabled ? Theme.selection : "transparent"

                Text {
                    id: label
                    anchors.verticalCenter: parent.verticalCenter
                    x: 10 + root.depth * 14
                    text: (row.modelData.checkState === Qt.Checked && row.modelData.buttonType !== 0 ? "\u2713 " : "")
                          + row.modelData.text + (row.modelData.hasChildren ? "  \u203A" : "")
                    color: !row.modelData.enabled ? Theme.placeholder
                           : hover.containsMouse ? Theme.fgBright : Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    textFormat: Text.PlainText
                }
                MouseArea {
                    id: hover
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (!row.modelData.enabled) return
                        if (row.modelData.hasChildren) row.expanded = !row.expanded
                        else { row.modelData.triggered(); root.done() }
                    }
                }
            }

            Loader {
                id: sub
                active: row.expanded && row.modelData.hasChildren
                anchors.left: parent.left; anchors.right: parent.right
                anchors.top: entryRect.bottom
                height: active && sub.item ? sub.item.implicitHeight : 0
                source: "MenuList.qml"
                onLoaded: {
                    sub.item.handle = row.modelData
                    sub.item.depth = root.depth + 1
                    sub.item.done.connect(root.done)
                }
            }
        }
    }
}
