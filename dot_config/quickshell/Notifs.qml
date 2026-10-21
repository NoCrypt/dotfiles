import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications

// mako replacement. Same look (GitHub Dark card, 520 px wide, 160 px max, 2 px border,
// 10 s default timeout, progress hint overlay), stacked top-right with newest on top, on the
// focused output. Left click: screenshot notifications open satty (notif-open.sh), others
// invoke their default action; right click dismisses.
Scope {
    id: root

    NotificationServer {
        id: server
        bodySupported: true
        bodyMarkupSupported: true
        actionsSupported: true
        imageSupported: true
        onNotification: n => { n.tracked = true }
    }

    ScriptModel {
        id: stack
        values: server.trackedNotifications.values.slice().reverse()
    }

    Variants {
        model: Quickshell.screens
        delegate: PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            readonly property bool here: Hypr.focusedName === ""
                ? modelData === Quickshell.screens[0]
                : Hypr.focusedName === modelData.name

            visible: here && stack.values.length > 0
            anchors { top: true; right: true }
            margins { top: Theme.notifMargin; right: Theme.notifMargin }
            implicitWidth: Theme.notifWidth
            implicitHeight: Math.max(1, column.height)
            color: "transparent"
            mask: Region { item: column }
            WlrLayershell.namespace: "notifications"      // keeps the fade layer_rule in mango

            Column {
                id: column
                width: Theme.notifWidth
                spacing: Theme.notifMargin

                Repeater {
                    model: stack
                    delegate: Rectangle {
                        id: card
                        required property var modelData     // Notification

                        readonly property var hintValue: modelData.hints ? modelData.hints["value"] : undefined
                        // Quickshell forwards the D-Bus value (ms); 0 = never, -1 = server default
                        readonly property int timeoutMs: {
                            const t = modelData.expireTimeout
                            if (t === 0) return 0
                            if (t > 0) return t < 100 ? t * 1000 : t
                            return Theme.notifTimeout
                        }
                        readonly property string iconSource: {
                            const img = modelData.image
                            if (img) return img
                            const ic = modelData.appIcon
                            if (!ic) return ""
                            return ic.charAt(0) === "/" ? "file://" + ic : Quickshell.iconPath(ic, true)
                        }

                        width: Theme.notifWidth
                        height: Math.min(Theme.notifMaxHeight, content.implicitHeight + 2 * (Theme.notifPadding + Theme.notifBorder))
                        color: "#ee161b22"
                        border.width: Theme.notifBorder
                        border.color: Theme.border
                        clip: true

                        Rectangle {          // progress-color=over #58a6ff44
                            visible: card.hintValue !== undefined
                            x: Theme.notifBorder; y: Theme.notifBorder
                            height: parent.height - 2 * Theme.notifBorder
                            width: (parent.width - 2 * Theme.notifBorder) * Math.max(0, Math.min(100, Number(card.hintValue))) / 100
                            color: "#4458a6ff"
                        }

                        RowLayout {
                            id: content
                            anchors.fill: parent
                            anchors.margins: Theme.notifBorder + Theme.notifPadding
                            spacing: Theme.notifPadding

                            Image {
                                visible: card.iconSource !== ""
                                source: card.iconSource
                                Layout.preferredWidth: 128
                                Layout.preferredHeight: 128
                                Layout.maximumWidth: 128
                                Layout.alignment: Qt.AlignTop
                                fillMode: Image.PreserveAspectFit
                                sourceSize.width: 256
                                sourceSize.height: 256
                                asynchronous: true
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignTop
                                spacing: 2
                                Text {
                                    Layout.fillWidth: true
                                    text: card.modelData.summary
                                    color: Theme.fg
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.notifPx
                                    font.bold: true
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                    textFormat: Text.PlainText
                                }
                                Text {
                                    visible: text !== ""
                                    Layout.fillWidth: true
                                    text: card.modelData.body
                                    color: Theme.fg
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.notifPx
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 4
                                    elide: Text.ElideRight
                                    textFormat: Text.StyledText
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: mouse => {
                                const n = card.modelData
                                if (mouse.button === Qt.LeftButton) {
                                    if (n.appName === "screenshot") {
                                        Quickshell.execDetached(["sh", "-c",
                                            '[ -f "$1" ] || exit 0; exec satty --filename "$1" --fullscreen current-screen --copy-command wl-copy --actions-on-enter save-to-clipboard --early-exit copy',
                                            "sh", String(n.body).trim()])
                                    } else {
                                        for (const a of n.actions) if (a.identifier === "default") { a.invoke(); break }
                                    }
                                }
                                n.dismiss()
                            }
                        }

                        Timer {
                            interval: card.timeoutMs
                            running: card.timeoutMs > 0
                            onTriggered: card.modelData.expire()
                        }
                    }
                }
            }
        }
    }
}
