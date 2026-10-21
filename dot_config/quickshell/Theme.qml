pragma Singleton
import QtQuick
import Quickshell

// GitHub Dark (Primer): the same tokens as PALETTE.md in the dotfiles repo.
Singleton {
    readonly property color fg: "#c9d1d9"
    readonly property color fgBright: "#ffffff"
    readonly property color chip: "#21262d"
    readonly property color dark: "#0d1117"
    readonly property color deepest: "#010409"
    readonly property color subtle: "#161b22"
    readonly property color muted: "#8b949e"
    readonly property color placeholder: "#6e7681"
    readonly property color accent: "#58a6ff"
    readonly property color accentLight: "#79c0ff"
    readonly property color selection: "#1f6feb"
    readonly property color border: "#30363d"
    readonly property color danger: "#f85149"
    readonly property color ok: "#3fb950"
    readonly property color warn: "#d29922"

    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property int fontPx: 16          // mangobar: font-size 16px, bold
    readonly property int radius: 10          // mangobar: border-radius 10px

    // bar geometry: 5 px outside the pills, pills are 24 px tall
    readonly property int barHeight: 34
    readonly property int barMarginV: 5
    readonly property int barMarginH: 10
    readonly property int gap: 8

    // mako: width 520, height 160, padding 14, margin 10, border 2, timeout 10 s
    readonly property int notifWidth: 520
    readonly property int notifMaxHeight: 160
    readonly property int notifPadding: 14
    readonly property int notifMargin: 10
    readonly property int notifBorder: 2
    readonly property int notifTimeout: 10000
    readonly property int notifPx: 18         // mako "JetBrainsMono Nerd Font 14" = 14 pt

    // Tested locked in a nested Hyprland session; the fallback timer in Lock.qml
    // guarantees the ext-session-lock surface even if grim hangs.
    readonly property bool qsLock: true
    readonly property string pamConfig: "swaylock"   // /etc/pam.d/swaylock includes login

    readonly property string home: Quickshell.env("HOME")
    readonly property string scripts: home + "/.config/mango/scripts"
    readonly property string wlogoutIcons: home + "/.config/mango/wlogout/icons"

    // Nerd Font glyphs above U+FFFF need String.fromCodePoint
    function g(cp) { return String.fromCodePoint(cp) }
}
