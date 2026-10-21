pragma Singleton
import QtQuick
import Quickshell

// Tiny event bus between the bar, the overlays and the IPC handlers in shell.qml.
Singleton {
    property bool barVisible: true
    signal refresh()            // re-run the script-backed bar modules
    signal launcherRequested()
    signal sessionRequested()
    signal lockRequested()
}
