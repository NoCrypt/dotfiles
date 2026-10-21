pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

// Live state of Hyprland. `monitors` mirrors the old Mango singleton shape:
// output name -> { name, active, tags: [live HyprlandWorkspace objects] }.
// The workspace objects are live QObjects, so active/urgent/toplevels update
// without polling.
Singleton {
    id: root

    readonly property string focusedName: Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
    // Hyprland.activeToplevel stays null in 0.56 Lua mode; the wlr foreign-toplevel
    // manager reports the active window correctly. Show its title only on the
    // monitor the window is on (mango showed the active client per monitor).
    readonly property var activeToplevel: ToplevelManager.activeToplevel
    readonly property string activeScreen: activeToplevel && activeToplevel.screens.length > 0
        ? activeToplevel.screens[0].name : ""

    readonly property var monitors: {
        const out = {}
        for (const m of Hyprland.monitors.values) {
            out[m.name] = {
                name: m.name,
                activeWs: m.activeWorkspace ? m.activeWorkspace.id : -1,
                tags: Hyprland.workspaces.values.filter(w => w.monitor === m && w.id > 0)
            }
        }
        return out
    }

    // Hyprland 0.55+ uses Lua dispatcher expressions; the old "workspace 2"
    // strings only work in hyprlang mode.
    function request(expr, legacy) {
        Hyprland.dispatch(Hyprland.usingLua ? expr : legacy)
    }
    function focusWorkspace(id) { request(`hl.dsp.focus({workspace = ${id}})`, "workspace " + id) }
    function cycleWorkspace(dir) {
        const sel = dir > 0 ? "e+1" : "e-1"
        request(`hl.dsp.focus({workspace = "${sel}"})`, "workspace " + sel)
    }
    function exitSession() { request("hl.dsp.exit()", "exit") }
}
