pragma Singleton
import QtQuick

QtObject {

    readonly property string versionName: "26.221" //YY.MDD
    // ── Backgrounds ────────────────────────────────────────────────────────────
    readonly property color colBg:      "#1a1b26"
    readonly property color colSurface: "#24283b"
    readonly property color colOverlay: Qt.rgba(0, 0, 0, 0.85)

    // ── Text ───────────────────────────────────────────────────────────────────
    readonly property color colFg:      "#c0caf5"
    readonly property color colMuted:   "#565f89"
    readonly property color colWhite:   "#ffffff"

    // ── Accents ────────────────────────────────────────────────────────────────
    readonly property color colBlue:    "#7aa2f7"
    readonly property color colCyan:    "#0db9d7"

    // ── Status (CircularWidget) ────────────────────────────────────────────────
    readonly property color colOk:      "#7aa2f7"
    readonly property color colWarn:    "#ff8738"
    readonly property color colCrit:    "#a90000"

    // ── Borders ────────────────────────────────────────────────────────────────
    readonly property color colBorder:  Qt.rgba(1, 1, 1, 0.1)

    // ── Typography ─────────────────────────────────────────────────────────────
    readonly property string fontFamily:  "SF Pro Display"
    readonly property string fontDisplay: "SF Pro Text"
    readonly property int    fontSize:    16

    // ── Shape ──────────────────────────────────────────────────────────────────
    readonly property int    radius:      10

    // ── Wallpaper ──────────────────────────────────────────────────────────────
    readonly property string wallpaper: "/home/pala/Pictures/Wallpapers/tahoe.png"

    // ── Bar toggles ────────────────────────────────────────────────────────────
    readonly property bool   showClock:   true
    readonly property bool   showTray:    true
    readonly property bool   showMpris:   true

    // ── Workspaces ─────────────────────────────────────────────────────────────
    readonly property int    workspaceCount: 6
}
