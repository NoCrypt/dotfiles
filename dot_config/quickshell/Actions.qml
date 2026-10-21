pragma Singleton
import QtQuick
import Quickshell

// The same commands wlogout's layout file runs.
Singleton {
    function lock() {
        if (Theme.qsLock) Bus.lockRequested()
        else Quickshell.execDetached(["swaylock", "-f", "-c", "000000"])
    }
    function logout()   { Hypr.exitSession() }
    function shutdown() { Quickshell.execDetached(["shutdown", "-h", "now"]) }
    function reboot()   { Quickshell.execDetached(["reboot"]) }
    function suspend()  { Quickshell.execDetached(["systemctl", "suspend"]) }
}
