import QtQuick
import QtQuick.Layouts

// Hyprland workspaces for one monitor (the old mangobar "tags" module).
// `mon.tags` are live HyprlandWorkspace objects: active/urgent/toplevels update
// by themselves. Left click = activate, wheel = next/previous workspace.
RowLayout {
    id: root
    required property var mon
    spacing: Theme.gap

    readonly property var names: [Theme.g(0xF120), Theme.g(0xF0AC), Theme.g(0xF086), "4", "5", "6", "7", "8", "9"]
    // Nerd Font ink is not symmetric inside the glyph advance; nudge the icons left.
    // The chat glyph (id 3) has a much wider advance than its ink, so it needs more.
    readonly property var glyphOffsets: [-4, -3, -8, 0, 0, 0, 0, 0, 0]
    readonly property var pinned: [1, 2, 3]
    property double _lastScroll: 0

    // Existing workspaces plus placeholders for the pinned 1-3, so the three
    // tags are always visible like they were in mangobar.
    readonly property var tags: {
        const list = root.mon ? root.mon.tags.slice() : []
        const have = new Set(list.map(w => w.id))
        for (const id of root.pinned)
            if (!have.has(id)) list.push({ id: id, virtual: true, active: false, urgent: false })
        return list.sort((a, b) => a.id - b.id)
    }

    function scroll(dir) {
        const now = Date.now()
        if (now - _lastScroll < 100) return
        _lastScroll = now
        Hypr.cycleWorkspace(dir)
    }

    Repeater {
        model: root.tags
        delegate: Pill {
            required property var modelData
            readonly property bool isActive: root.mon && modelData.id === root.mon.activeWs
            readonly property bool occupied: !modelData.virtual && modelData.toplevels.values.length > 0
            visible: isActive || modelData.urgent || occupied || root.pinned.indexOf(modelData.id) >= 0
            padding: 14
            textOffsetX: root.glyphOffsets[modelData.id - 1] || 0
            text: root.names[modelData.id - 1] !== undefined ? root.names[modelData.id - 1] : String(modelData.id)
            bg: modelData.urgent ? Theme.danger : isActive ? Theme.accent : occupied ? Theme.dark : Theme.deepest
            fg: modelData.urgent || isActive ? Theme.dark : occupied ? Theme.muted : Theme.fg
            onClicked: Hypr.focusWorkspace(modelData.id)
            onScrolled: dir => root.scroll(dir)
        }
    }
}
