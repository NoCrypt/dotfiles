//@ pragma Env QS_NO_RELOAD_POPUP=1
import QtQuick
import Quickshell
import Quickshell.Io

// Quickshell replacement for: mangobar + mako + fuzzel + wlogout + swaylock.
// Launch with `hl.on("hyprland.start", ...)` in hyprland.lua.
ShellRoot {
    Variants {
        model: Quickshell.screens
        delegate: Bar {}
    }

    Notifs {}
    Picker { id: picker }
    Session { id: session }
    Lock { id: screenLock }

    Connections {
        target: Bus
        function onLauncherRequested() { picker.show("apps") }
        function onSessionRequested() { session.toggle() }
        function onLockRequested() { screenLock.lock() }
    }

    // qs ipc call <target> <function>
    IpcHandler {
        target: "bar"
        function refresh(): void { Bus.refresh() }
        function toggle(): void { Bus.barVisible = !Bus.barVisible }
    }
    IpcHandler {
        target: "launcher"
        function toggle(): void { picker.show("apps") }
        function close(): void { picker.close() }
    }
    IpcHandler {
        target: "clipboard"
        function toggle(): void { picker.show("clip") }
    }
    IpcHandler {
        target: "keybinds"
        function toggle(): void { picker.show("keys") }
    }
    IpcHandler {
        target: "session"
        function toggle(): void { session.toggle() }
    }
    IpcHandler {
        target: "lock"
        function lock(): void { Bus.lockRequested() }
        function isLocked(): bool { return screenLock.locked }
    }
}
