pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool ready: !!sink && !!sink.audio
    readonly property int percent: ready ? Math.max(0, Math.min(100, Math.round(sink.audio.volume * 100))) : 0
    readonly property bool muted: ready ? sink.audio.muted : false
    // mangobar: bluez in device.api or in the sink name
    readonly property bool bluetooth: {
        if (!sink) return false
        const api = sink.properties ? String(sink.properties["device.api"] || "") : ""
        return api.indexOf("bluez") >= 0 || String(sink.name || "").indexOf("bluez") >= 0
    }

    PwObjectTracker { objects: root.sink ? [root.sink] : [] }

    // Same wpctl calls as the mangobar config
    function toggleMute() { Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]) }
    function up()   { Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%+"]) }
    function down() { Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%-"]) }
}
