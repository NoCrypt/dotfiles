import QtQuick
import QtQuick.Layouts

// One mangobar "module": a rounded chip with a single line of text.
Rectangle {
    id: root

    property string text: ""
    property color fg: Theme.muted
    property color bg: Theme.dark
    property int padding: 12
    property int textOffsetX: 0         // visual centering for asymmetric Nerd Font glyphs
    property int scrollInterval: 0      // ms, mangobar "scroll-interval"
    property alias label: label

    signal clicked(int button)          // Qt.LeftButton / RightButton / MiddleButton
    signal scrolled(int dir)            // +1 = wheel up, -1 = wheel down

    color: bg
    radius: Theme.radius
    Layout.fillHeight: true
    implicitHeight: Theme.barHeight - 2 * Theme.barMarginV
    implicitWidth: label.implicitWidth + 2 * padding

    Text {
        id: label
        anchors.fill: parent
        anchors.leftMargin: root.padding + root.textOffsetX
        anchors.rightMargin: root.padding - root.textOffsetX
        text: root.text
        color: root.fg
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontPx
        font.bold: true
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        textFormat: Text.PlainText
    }

    property real _acc: 0
    property double _last: 0

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: mouse => root.clicked(mouse.button)
        // one step per wheel notch; touchpads accumulate until a full notch
        onWheel: wheel => {
            root._acc += wheel.angleDelta.y
            while (Math.abs(root._acc) >= 120) {
                const dir = root._acc > 0 ? 1 : -1
                root._acc -= dir * 120
                const now = Date.now()
                if (root.scrollInterval > 0 && now - root._last < root.scrollInterval) continue
                root._last = now
                root.scrolled(dir)
            }
        }
    }
}
