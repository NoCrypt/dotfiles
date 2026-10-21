import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "Fuzzy.js" as Fuzzy

// fuzzel replacement, one overlay with three modes:
//   apps  : desktop entries (Super+Space). Terminal=true entries run through `kitty -e`.
//   clip  : cliphist history, pick = wl-copy (scripts/clipboard.sh)
//   keys  : keybind cheat sheet from keybinds.sh --list (read-only, like the fuzzel dmenu)
// Same colours as fuzzel.ini; the layer namespace "fuzzel" keeps mango's zoom layer_rule.
Scope {
    id: root

    property string mode: ""
    readonly property bool open: mode !== ""
    property var items: []
    property var results: []
    property string query: ""
    property int current: 0

    readonly property int maxRows: mode === "keys" ? 25 : 15
    readonly property string prompt: mode === "clip" ? "  " : mode === "keys" ? "keybinds> " : "> "

    function show(m) {
        if (mode === m) { close(); return }
        query = ""; current = 0; items = []; results = []
        mode = m
        load()
    }
    function close() { mode = "" }

    function load() {
        if (mode === "apps") {
            const list = []
            for (const e of DesktopEntries.applications.values) {
                if (e.noDisplay) continue
                list.push({ title: e.name, sub: e.genericName || e.comment || "",
                            hay: Array.from(e.keywords || []).join(" "), icon: e.icon, entry: e, raw: "" })
            }
            list.sort((a, b) => a.title.localeCompare(b.title))
            items = list
            refilter()
        } else if (mode === "clip") {
            fetch.command = ["cliphist", "list"]
            fetch.running = true
        } else if (mode === "keys") {
            fetch.command = [Theme.home + "/.config/hypr/keybinds.sh", "--list"]
            fetch.running = true
        }
    }

    function setLines(text) {
        const clip = mode === "clip"
        items = text.split("\n").filter(l => l !== "").map(l => ({
            title: clip ? l.replace(/^\d+\t/, "").replace(/\s+/g, " ") : l,
            sub: "", hay: "", icon: "", entry: null, raw: l }))
        refilter()
    }

    function refilter() {
        let out = []
        if (query === "") {
            out = items.map(i => ({ item: i, idx: [], score: 0 }))
        } else {
            for (const i of items) {
                const m = Fuzzy.match(query, i.title)
                if (m) { out.push({ item: i, idx: m.idx, score: m.score + 10 }); continue }
                const m2 = Fuzzy.match(query, i.sub + " " + i.hay)
                if (m2) out.push({ item: i, idx: [], score: m2.score })
            }
            out.sort((a, b) => b.score - a.score)
        }
        results = out.slice(0, 300)
        current = 0
    }

    function accept() {
        const r = results[current]
        if (!r) return
        const m = mode
        close()
        if (m === "apps") {
            const e = r.item.entry
            if (e.runInTerminal) Quickshell.execDetached(["kitty", "-e"].concat(Array.from(e.command)))
            else e.execute()
        } else if (m === "clip") {
            Quickshell.execDetached(["sh", "-c", 'printf "%s" "$1" | cliphist decode | wl-copy', "sh", r.item.raw])
        }
    }

    Process {
        id: fetch
        stdout: StdioCollector { onStreamFinished: root.setLines(text) }
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

            visible: root.open && here
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            implicitWidth: root.mode === "keys" ? Math.min(modelData.width - 80, 900) : 560
            implicitHeight: 52 + Math.max(1, Math.min(root.maxRows, root.results.length)) * 32 + 12
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "fuzzel"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            onVisibleChanged: if (visible) { input.text = ""; input.forceActiveFocus() }

            Rectangle {
                anchors.fill: parent
                color: Theme.dark
                border.color: Theme.border
                border.width: 1
                radius: 10

                RowLayout {
                    id: head
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
                    height: 36
                    Text {
                        text: root.prompt
                        color: Theme.muted
                        font.family: Theme.fontFamily; font.pixelSize: 16
                    }
                    TextInput {
                        id: input
                        Layout.fillWidth: true
                        color: Theme.fg
                        selectionColor: Theme.selection
                        font.family: Theme.fontFamily; font.pixelSize: 16
                        clip: true
                        onTextChanged: { root.query = text; root.refilter() }
                        Keys.onPressed: event => {
                            const ctrl = event.modifiers & Qt.ControlModifier
                            if (event.key === Qt.Key_Escape) { root.close(); event.accepted = true }
                            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { root.accept(); event.accepted = true }
                            else if (event.key === Qt.Key_Up || (ctrl && (event.key === Qt.Key_K || event.key === Qt.Key_P))) {
                                root.current = Math.max(0, root.current - 1); event.accepted = true }
                            else if (event.key === Qt.Key_Down || (ctrl && (event.key === Qt.Key_J || event.key === Qt.Key_N))) {
                                root.current = Math.min(root.results.length - 1, root.current + 1); event.accepted = true }
                            else if (event.key === Qt.Key_PageUp) { root.current = Math.max(0, root.current - root.maxRows); event.accepted = true }
                            else if (event.key === Qt.Key_PageDown) { root.current = Math.min(root.results.length - 1, root.current + root.maxRows); event.accepted = true }
                        }
                    }
                    Text {
                        text: root.results.length + "/" + root.items.length
                        color: Theme.placeholder
                        font.family: Theme.fontFamily; font.pixelSize: 14
                    }
                }

                ListView {
                    id: list
                    anchors { left: parent.left; right: parent.right; top: head.bottom; bottom: parent.bottom
                              leftMargin: 8; rightMargin: 8; topMargin: 8; bottomMargin: 8 }
                    clip: true
                    model: root.results
                    currentIndex: root.current
                    onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Rectangle {
                        id: rowItem
                        required property var modelData
                        required property int index
                        readonly property bool selected: index === root.current
                        width: ListView.view.width
                        height: 32
                        radius: 6
                        color: selected ? Theme.selection : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10; anchors.rightMargin: 10
                            spacing: 10
                            Image {
                                visible: root.mode === "apps"
                                source: root.mode === "apps" ? Quickshell.iconPath(rowItem.modelData.item.icon, true) : ""
                                Layout.preferredWidth: 22; Layout.preferredHeight: 22
                                sourceSize.width: 44; sourceSize.height: 44
                                asynchronous: true
                            }
                            Text {
                                Layout.fillWidth: true
                                textFormat: Text.RichText
                                elide: Text.ElideRight
                                color: rowItem.selected ? Theme.fgBright : Theme.fg
                                font.family: Theme.fontFamily; font.pixelSize: 16
                                text: "<span style='white-space:pre'>" + Fuzzy.highlight(rowItem.modelData.item.title,
                                      rowItem.modelData.idx, rowItem.selected ? "#79c0ff" : "#58a6ff") + "</span>"
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: { root.current = rowItem.index; root.accept() }
                        }
                    }
                }
            }
        }
    }
}
