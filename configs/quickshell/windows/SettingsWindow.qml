import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Widgets
import Quickshell.Hyprland
import "../"

PopupWindow {
    id: settingsWindow
    property var anchorWindow

    anchor.window: anchorWindow
    anchor.rect.x: (screen.width  - width)  / 2
    anchor.rect.y: (screen.height - height) / 2

    implicitWidth:  900
    implicitHeight: 580
    color: "transparent"

    // ── Pending state ─────────────────────────────────────────────────────────
    property string pendingWallpaper:   Theme.wallpaper
    property int    pendingFontSize:    Theme.fontSize
    property int    pendingRadius:      Theme.radius
    property int    pendingWorkspaces:  Theme.workspaceCount
    property bool   pendingShowClock:   Theme.showClock
    property bool   pendingShowTray:    Theme.showTray
    property bool   pendingShowMpris:   Theme.showMpris
    property string pendingFontFamily:  Theme.fontFamily
    property string pendingFontDisplay: Theme.fontDisplay
    property string activePreset:       ""

    property bool hasChanges:
        pendingWallpaper   !== Theme.wallpaper      ||
        pendingFontSize    !== Theme.fontSize       ||
        pendingRadius      !== Theme.radius         ||
        pendingWorkspaces  !== Theme.workspaceCount ||
        pendingShowClock   !== Theme.showClock      ||
        pendingShowTray    !== Theme.showTray       ||
        pendingShowMpris   !== Theme.showMpris      ||
        pendingFontFamily  !== Theme.fontFamily     ||
        pendingFontDisplay !== Theme.fontDisplay

    // ── System fonts ──────────────────────────────────────────────────────────
    property var availableFonts: []
    Process {
        id: fontListProc
        command: ["bash", "-c", "fc-list : family | sed 's/,.*//' | sort -u"]
        stdout: StdioCollector {
            onStreamFinished: {
                settingsWindow.availableFonts = text.trim().split("\n").filter(f => f.trim() !== "")
            }
        }
    }

    // ── System info ───────────────────────────────────────────────────────────
    // FIX: one value per line in a fixed order — no KEY= parsing, no delimiter collisions
    property string sysHostname: "…"
    property string sysDistro:   "…"
    property string sysKernel:   "…"
    property string sysCpu:      "…"
    property string sysRam:      "…"
    property string sysDisk:     "…"
    property string sysUptime:   "…"
    property int packagesCount: 0
    Process {
        id: sysInfoProc
        command: ["bash", "-c", [
            "echo KERNEL=$(uname -r)",
            "echo DISTRO=$(. /etc/os-release && echo $PRETTY_NAME)",
            "echo CPU=$(grep 'model name' /proc/cpuinfo | head -1 | cut -d: -f2 | sed 's/^ //')",
            "echo RAM=$(free -h | awk '/Mem/{print $2}')",
            "echo DISK=$(df -h / | awk 'NR==2{print \"on \"$1 \": \"$2 \" total, \" $5 \" used\"}')",
            "echo UPTIME=$(uptime -p | sed 's/up //')",
            "echo HOSTNAME=$(echo $(whoami)@$(cat /etc/hostname))"
        ].join(" && ")]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split("\n")
                for (var i = 0; i < lines.length; i++) {
                    var kv = lines[i].split("=")
                    if (kv.length < 2) continue
                    var key = kv[0]; var val = kv.slice(1).join("=")
                    if      (key === "KERNEL")   settingsWindow.sysKernel   = val
                    else if (key === "DISTRO")   settingsWindow.sysDistro   = val
                    else if (key === "CPU")      settingsWindow.sysCpu      = val
                    else if (key === "RAM")      settingsWindow.sysRam      = val
                    else if (key === "DISK")     settingsWindow.sysDisk     = val
                    else if (key === "UPTIME")   settingsWindow.sysUptime   = val
                    else if (key === "HOSTNAME") settingsWindow.sysHostname = val
                }
            }
        }
    }

    // ── Color presets ─────────────────────────────────────────────────────────
    readonly property var presets: ({
        "Tokyo Night":      { bg: "#1a1b26", fg: "#c0caf5", blue: "#7aa2f7", cyan: "#0db9d7", muted: "#565f89", surface: "#24283b" },
        "Catppuccin Mocha": { bg: "#1e1e2e", fg: "#cdd6f4", blue: "#89b4fa", cyan: "#89dceb", muted: "#585b70", surface: "#313244" },
        "Gruvbox":          { bg: "#282828", fg: "#ebdbb2", blue: "#458588", cyan: "#689d6a", muted: "#928374", surface: "#3c3836" },
        "Nord":             { bg: "#2e3440", fg: "#eceff4", blue: "#5e81ac", cyan: "#88c0d0", muted: "#4c566a", surface: "#3b4252" },
        "Dracula":          { bg: "#282a36", fg: "#f8f8f2", blue: "#6272a4", cyan: "#8be9fd", muted: "#6272a4", surface: "#44475a" },
        "Rose Pine":        { bg: "#191724", fg: "#e0def4", blue: "#31748f", cyan: "#9ccfd8", muted: "#6e6a86", surface: "#26233a" }
    })

    // ── Processes ─────────────────────────────────────────────────────────────
    Process {
        id: pickerProc
        command: ["zenity", "--file-selection", "--title=Choose Wallpaper",
                  "--file-filter=Images | *.jpg *.jpeg *.png *.webp *.gif",
                  "--filename=" + settingsWindow.pendingWallpaper]
        stdout: StdioCollector {
            onStreamFinished: {
                var path = text.trim()
                if (path !== "") settingsWindow.pendingWallpaper = path
            }
        }
    }

    // FIX: use Quickshell.shellDir (configDir is deprecated in v0.2.1)
    // FIX: restart quickshell after writing Theme.qml
    Process {
        id: applyProc
        command: ["bash", "-c",
            "sed -i " +
            "'s|readonly property string wallpaper:.*|readonly property string wallpaper: \"" + pendingWallpaper + "\"|;" +
            "s|readonly property int    fontSize:.*|readonly property int    fontSize:    " + pendingFontSize + "|;" +
            "s|readonly property int    radius:.*|readonly property int    radius:      " + pendingRadius + "|;" +
            "s|readonly property int    workspaceCount:.*|readonly property int    workspaceCount: " + pendingWorkspaces + "|;" +
            "s|readonly property bool   showClock:.*|readonly property bool   showClock:   " + pendingShowClock + "|;" +
            "s|readonly property bool   showTray:.*|readonly property bool   showTray:    " + pendingShowTray + "|;" +
            "s|readonly property bool   showMpris:.*|readonly property bool   showMpris:   " + pendingShowMpris + "|;" +
            "s|readonly property string fontFamily:.*|readonly property string fontFamily:  \\\"" + pendingFontFamily + "\\\"|;" +
            "s|readonly property string fontDisplay:.*|readonly property string fontDisplay: \\\"" + pendingFontDisplay + "\\\"|" +
            "' " + Quickshell.shellDir + "/Theme.qml && " +
            "bash " + Quickshell.shellDir + "/scripts/apply-theme.sh ; " +
            "quickshell -p " + Quickshell.shellDir + " &"]
        stdout: StdioCollector { onStreamFinished: applyStatus.show("Saved! Restarting…") }
    }

    Process { id: presetProc }

    // ── Open / close ──────────────────────────────────────────────────────────
    function open() {
        pendingWallpaper   = Theme.wallpaper
        pendingFontSize    = Theme.fontSize
        pendingRadius      = Theme.radius
        pendingWorkspaces  = Theme.workspaceCount
        pendingShowClock   = Theme.showClock
        pendingShowTray    = Theme.showTray
        pendingShowMpris   = Theme.showMpris
        pendingFontFamily  = Theme.fontFamily
        pendingFontDisplay = Theme.fontDisplay
        sysInfoProc.running  = true
        fontListProc.running = true
        card.opacity = 0
        settingsWindow.visible = true
        fadeAnim.from = 0; fadeAnim.to = 1; fadeAnim.running = true
    }
    function close() {
        fadeAnim.from = 1; fadeAnim.to = 0; fadeAnim.running = true
    }
    function toggle() {
        if (settingsWindow.visible) close()
        else open()
    }

    GlobalShortcut {
        name: "togglesettings"
        description: "Toggle settings window"
        onPressed: settingsWindow.toggle()
    }

    // ── Root card ─────────────────────────────────────────────────────────────
    Rectangle {
        
        id: card
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.colOverlay
        border.color: Theme.colBorder
        border.width: 1
        clip: true
        opacity: 0

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // ── Sidebar ───────────────────────────────────────────────────────
            Rectangle {
                Layout.preferredWidth: 190
                Layout.fillHeight: true
                color: Qt.rgba(0, 0, 0, 0.25)
                radius: 20
                Rectangle {
                    anchors.right: parent.right
                    width: 20; height: parent.height
                    color: parent.color
                }
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 4

                    Item { Layout.preferredHeight: 8 }
                    Text {
                        text: "Settings"
                        color: Theme.colWhite
                        font { family: Theme.fontDisplay; pixelSize: 22; bold: true }
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Text {
                        text: "Pala's Shell"
                        color: Theme.colMuted
                        font { family: Theme.fontFamily; pixelSize: 11 }
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Item { Layout.preferredHeight: 12 }

                    SidebarBtn { label: "Colors";    icon: "󰌁";  page: 0; currentPage: stack.currentIndex; onNav: stack.currentIndex = page }
                    SidebarBtn { label: "Presets";   icon: "󰏘"; page: 1; currentPage: stack.currentIndex; onNav: stack.currentIndex = page }
                    SidebarBtn { label: "Wallpaper"; icon: "󰸉"; page: 2; currentPage: stack.currentIndex; onNav: stack.currentIndex = page }
                    SidebarBtn { label: "Fonts";     icon: "";  page: 3; currentPage: stack.currentIndex; onNav: stack.currentIndex = page }
                    SidebarBtn { label: "Bar";       icon: "󰀘"; page: 4; currentPage: stack.currentIndex; onNav: stack.currentIndex = page }
                    SidebarBtn { label: "Layout";    icon: "󰙖"; page: 5; currentPage: stack.currentIndex; onNav: stack.currentIndex = page }
                    SidebarBtn { label: "About";     icon: "󰋼"; page: 6; currentPage: stack.currentIndex; onNav: stack.currentIndex = page }

                    Item { Layout.fillHeight: true }

                    // Apply & Restart button
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 38
                        radius: 10
                        color: settingsWindow.hasChanges
                            ? (applyMouse.containsMouse ? Qt.lighter(Theme.colBlue, 1.2) : Theme.colBlue)
                            : Qt.rgba(1,1,1,0.05)
                        Behavior on color { ColorAnimation { duration: 150 } }
                        RowLayout {
                            anchors.centerIn: parent; spacing: 8
                            Text {
                                text: ""
                                color: settingsWindow.hasChanges ? Theme.colWhite : Theme.colMuted
                                font { family: "Symbols Nerd Font"; pixelSize: 14 }
                            }
                            Text {
                                text: "Apply & Restart"
                                color: settingsWindow.hasChanges ? Theme.colWhite : Theme.colMuted
                                font { family: Theme.fontFamily; pixelSize: 12; bold: true }
                            }
                        }
                        MouseArea {
                            id: applyMouse
                            anchors.fill: parent; hoverEnabled: true
                            cursorShape: settingsWindow.hasChanges ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: { if (settingsWindow.hasChanges) applyProc.running = true }
                        }
                    }

                    // Close button
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        radius: 10
                        color: closeArea.containsMouse ? Qt.rgba(1,1,1,0.08) : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }
                        RowLayout {
                            anchors.centerIn: parent; spacing: 8
                            Text { text: ""; color: Theme.colMuted; font { family: "Symbols Nerd Font"; pixelSize: 14 } }
                            Text { text: "Close"; color: Theme.colMuted; font { family: Theme.fontFamily; pixelSize: 13 } }
                        }
                        MouseArea {
                            id: closeArea
                            anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: settingsWindow.close()
                        }
                    }
                    Item { Layout.preferredHeight: 8 }
                }
            }

            // ── Pages ─────────────────────────────────────────────────────────
            StackLayout {
                id: stack
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: 0

                // ── Page 0 — Colors ───────────────────────────────────────────
                SettingsPage {
                    title: "Colors"; subtitle: "Your current shell palette"
                    ColumnLayout {
                        width: parent.width; spacing: 12
                        ColorRow { label: "Background";  value: Theme.colBg.toString() }
                        ColorRow { label: "Foreground";  value: Theme.colFg.toString() }
                        ColorRow { label: "Accent Blue"; value: Theme.colBlue.toString() }
                        ColorRow { label: "Accent Cyan"; value: Theme.colCyan.toString() }
                        ColorRow { label: "Muted";       value: Theme.colMuted.toString() }
                        ColorRow { label: "Surface";     value: Theme.colSurface.toString() }
                        Item { Layout.preferredHeight: 4 }
                        Text {
                            text: "Use the Presets page for one-click themes, or edit Theme.qml directly."
                            color: Theme.colMuted; font { family: Theme.fontFamily; pixelSize: 11 }
                            wrapMode: Text.WordWrap; Layout.fillWidth: true
                        }
                    }
                }

                // ── Page 1 — Presets ──────────────────────────────────────────
                SettingsPage {
                    title: "Presets"; subtitle: "One-click color themes"
                    // FIX: Column+Row with explicit widths instead of GridLayout
                    // GridLayout mis-sizes inside Flickable
                    Column {
                        width: parent.width; spacing: 12
                        Repeater {
                            model: {
                                var keys = Object.keys(settingsWindow.presets)
                                var rows = []
                                for (var i = 0; i < keys.length; i += 2)
                                    rows.push([ keys[i], i+1 < keys.length ? keys[i+1] : null ])
                                return rows
                            }
                            delegate: Row {
                                required property var modelData
                                width: parent.width; spacing: 12
                                Repeater {
                                    model: modelData.filter(k => k !== null)
                                    delegate: Rectangle {
                                        required property string modelData
                                        width: (parent.width - 12) / 2; height: 80; radius: 12
                                        color: settingsWindow.activePreset === modelData
                                            ? Qt.rgba(1,1,1,0.12)
                                            : (pm.containsMouse ? Qt.rgba(1,1,1,0.07) : Qt.rgba(1,1,1,0.04))
                                        border.color: settingsWindow.activePreset === modelData ? Theme.colBlue : Theme.colBorder
                                        border.width: settingsWindow.activePreset === modelData ? 2 : 1
                                        Behavior on color { ColorAnimation { duration: 120 } }
                                        RowLayout {
                                            anchors.fill: parent; anchors.margins: 12; spacing: 12
                                            ColumnLayout {
                                                spacing: 4
                                                RowLayout {
                                                    spacing: 4
                                                    Repeater {
                                                        model: [settingsWindow.presets[modelData].bg, settingsWindow.presets[modelData].blue, settingsWindow.presets[modelData].cyan, settingsWindow.presets[modelData].fg]
                                                        Rectangle { width: 16; height: 16; radius: 4; color: modelData }
                                                    }
                                                }
                                                RowLayout {
                                                    spacing: 4
                                                    Repeater {
                                                        model: [settingsWindow.presets[modelData].surface, settingsWindow.presets[modelData].muted, settingsWindow.presets[modelData].fg, settingsWindow.presets[modelData].blue]
                                                        Rectangle { width: 16; height: 16; radius: 4; color: modelData }
                                                    }
                                                }
                                            }
                                            Item { Layout.fillWidth: true }
                                            ColumnLayout {
                                                spacing: 2; Layout.fillWidth: true; anchors.horizontalCenter: parent.horizontalCenter
                                                Text { Layout.alignment: Qt.AlignCenter; text: modelData; color: Theme.colWhite; font { family: Theme.fontFamily; pixelSize: 13; bold: true } }
                                                Text {
                                                    Layout.alignment: Qt.AlignCenter
                                                    text: settingsWindow.activePreset === modelData ? "Active" : "Click to apply"
                                                    color: settingsWindow.activePreset === modelData ? Theme.colCyan : Theme.colMuted
                                                    font { family: Theme.fontFamily; pixelSize: 11 }
                                                }
                                            }
                                        }
                                        MouseArea {
                                            id: pm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                var p = settingsWindow.presets[modelData]
                                                presetProc.command = ["bash", "-c",
                                                    "sed -i " +
                                                    "'s|readonly property color colBg:.*|readonly property color colBg:      \"" + p.bg      + "\"|;" +
                                                    "s|readonly property color colFg:.*|readonly property color colFg:      \"" + p.fg      + "\"|;" +
                                                    "s|readonly property color colBlue:.*|readonly property color colBlue:    \"" + p.blue    + "\"|;" +
                                                    "s|readonly property color colCyan:.*|readonly property color colCyan:    \"" + p.cyan    + "\"|;" +
                                                    "s|readonly property color colMuted:.*|readonly property color colMuted:   \"" + p.muted   + "\"|;" +
                                                    "s|readonly property color colSurface:.*|readonly property color colSurface: \"" + p.surface + "\"|" +
                                                    "' " + Quickshell.shellDir + "/Theme.qml"]
                                                presetProc.running = true
                                                settingsWindow.activePreset = modelData
                                                applyStatus.show("Preset applied! Restart shell to see colors.")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        Text {
                            width: parent.width
                            text: "Presets write directly to Theme.qml. Restart Quickshell to see color changes."
                            color: Theme.colMuted; font { family: Theme.fontFamily; pixelSize: 11 }
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                // ── Page 2 — Wallpaper ────────────────────────────────────────
                SettingsPage {
                    title: "Wallpaper"; subtitle: "Pick your wallpaper"
                    ColumnLayout {
                        width: parent.width; spacing: 14
                        Rectangle {
                            Layout.fillWidth: true; height: 180; radius: 14
                            color: Theme.colSurface; border.color: Theme.colBorder; border.width: 1; clip: true
                            Image {
                                anchors.fill: parent
                                source: settingsWindow.pendingWallpaper !== "" ? "file://" + settingsWindow.pendingWallpaper : ""
                                fillMode: Image.PreserveAspectCrop
                            }
                            Text {
                                anchors.centerIn: parent
                                visible: settingsWindow.pendingWallpaper === ""
                                text: "No wallpaper selected"; color: Theme.colMuted
                                font { family: Theme.fontFamily; pixelSize: 13 }
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true; spacing: 10
                            Rectangle {
                                Layout.fillWidth: true; height: 38; radius: 10
                                color: Qt.rgba(1,1,1,0.05); border.color: Theme.colBorder; border.width: 1
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left; anchors.leftMargin: 12
                                    anchors.right: parent.right; anchors.rightMargin: 12
                                    text: settingsWindow.pendingWallpaper !== "" ? settingsWindow.pendingWallpaper : "No file selected"
                                    color: settingsWindow.pendingWallpaper !== "" ? Theme.colFg : Theme.colMuted
                                    font { family: Theme.fontFamily; pixelSize: 11 }
                                    elide: Text.ElideLeft
                                }
                            }
                            Rectangle {
                                width: 100; height: 38; radius: 10
                                color: browseArea.containsMouse ? Qt.rgba(1,1,1,0.12) : Qt.rgba(1,1,1,0.06)
                                Behavior on color { ColorAnimation { duration: 120 } }
                                border.color: Theme.colBorder; border.width: 1
                                RowLayout {
                                    anchors.centerIn: parent; spacing: 6
                                    Text { text: "󰥩"; color: Theme.colBlue; font { family: "Symbols Nerd Font"; pixelSize: 14 } }
                                    Text { text: "Browse"; color: Theme.colFg; font { family: Theme.fontFamily; pixelSize: 12 } }
                                }
                                MouseArea {
                                    id: browseArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: pickerProc.running = true
                                }
                            }
                        }
                        Text {
                            text: "Changes are previewed above. Hit Apply in the sidebar to save."
                            color: Theme.colMuted; font { family: Theme.fontFamily; pixelSize: 11 }
                            wrapMode: Text.WordWrap; Layout.fillWidth: true
                        }
                    }
                }

                // ── Page 3 — Fonts ────────────────────────────────────────────
                SettingsPage {
                    title: "Fonts"; subtitle: "Typography settings"
                    ColumnLayout {
                        width: parent.width; spacing: 16

                        // UI Font dropdown
                        FontPickerRow {
                            label: "UI Font"
                            currentFont: settingsWindow.pendingFontFamily
                            fonts: settingsWindow.availableFonts
                            onPicked: (f) => settingsWindow.pendingFontFamily = f
                        }

                        // Display Font dropdown
                        FontPickerRow {
                            label: "Display Font"
                            currentFont: settingsWindow.pendingFontDisplay
                            fonts: settingsWindow.availableFonts
                            onPicked: (f) => settingsWindow.pendingFontDisplay = f
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.colBorder }

                        // Font size slider
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 10
                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "Font Size"; color: Theme.colFg; font { family: Theme.fontFamily; pixelSize: 13 } }
                                Item { Layout.fillWidth: true }
                                Text { text: settingsWindow.pendingFontSize + "px"; color: Theme.colBlue; font { family: Theme.fontFamily; pixelSize: 13; bold: true } }
                            }
                            ShellSlider {
                                id: fontSlider; from: 10; to: 20; stepSize: 1
                                value: settingsWindow.pendingFontSize
                                onMoved: settingsWindow.pendingFontSize = value
                            }
                            Rectangle {
                                Layout.fillWidth: true; height: 48; radius: 10
                                color: Qt.rgba(1,1,1,0.04); border.color: Theme.colBorder; border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: "Preview at " + settingsWindow.pendingFontSize + "px"
                                    color: Theme.colFg
                                    font { family: settingsWindow.pendingFontFamily; pixelSize: settingsWindow.pendingFontSize }
                                }
                            }
                        }
                    }
                }

                // ── Page 4 — Bar ──────────────────────────────────────────────
                SettingsPage {
                    title: "Bar"; subtitle: "Toggle bar elements"
                    // FIX: use Column (not ColumnLayout) as direct container so
                    // ToggleRow Rectangle children size themselves with plain `width`
                    Column {
                        width: parent.width; spacing: 8

                        ToggleRow { label: "Clock";        desc: "Show time and date";     checked: settingsWindow.pendingShowClock;  onToggled: (v) => settingsWindow.pendingShowClock  = v }
                        ToggleRow { label: "System Tray";  desc: "Show tray icons";         checked: settingsWindow.pendingShowTray;   onToggled: (v) => settingsWindow.pendingShowTray   = v }
                        ToggleRow { label: "Media Island"; desc: "Show MPRIS media pill";   checked: settingsWindow.pendingShowMpris;  onToggled: (v) => settingsWindow.pendingShowMpris  = v }

                        Item { width: 1; height: 8 }
                        Rectangle { width: parent.width; height: 1; color: Theme.colBorder }
                        Item { width: 1; height: 8 }

                        // Workspace count
                        ColumnLayout {
                            width: parent.width; spacing: 10
                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "Workspace Count"; color: Theme.colFg; font { family: Theme.fontFamily; pixelSize: 13 } }
                                Item { Layout.fillWidth: true }
                                Text { text: settingsWindow.pendingWorkspaces; color: Theme.colBlue; font { family: Theme.fontFamily; pixelSize: 13; bold: true } }
                            }
                            ShellSlider {
                                id: wsSlider; from: 1; to: 10; stepSize: 1
                                value: settingsWindow.pendingWorkspaces
                                onMoved: settingsWindow.pendingWorkspaces = value
                            }
                        }
                    }
                }

                // ── Page 5 — Layout ───────────────────────────────────────────
                SettingsPage {
                    title: "Layout"; subtitle: "Spacing and shape"
                    ColumnLayout {
                        width: parent.width; spacing: 20
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 10
                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "Border Radius"; color: Theme.colFg; font { family: Theme.fontFamily; pixelSize: 13 } }
                                Item { Layout.fillWidth: true }
                                Text { text: settingsWindow.pendingRadius + "px"; color: Theme.colBlue; font { family: Theme.fontFamily; pixelSize: 13; bold: true } }
                            }
                            ShellSlider {
                                id: radiusSlider; from: 0; to: 30; stepSize: 1
                                value: settingsWindow.pendingRadius
                                onMoved: settingsWindow.pendingRadius = value
                            }
                            Item { Layout.preferredHeight: 12 }
                            Rectangle {
                                Layout.fillWidth: true; height: 70
                                radius: settingsWindow.pendingRadius
                                color: Qt.rgba(1,1,1,0.06); border.color: Theme.colBorder; border.width: 1
                                Behavior on radius { NumberAnimation { duration: 150 } }
                                Text {
                                    anchors.centerIn: parent; text: "Corner preview"
                                    color: Theme.colFg; font { family: Theme.fontFamily; pixelSize: 13 }
                                }
                            }
                        }
                    }
                }

                // ── Page 6 — About ────────────────────────────────────────────
                SettingsPage {
                    title: "About"; subtitle: "System & dotfiles info"

                    
                    ColumnLayout {
                        width: parent.width; spacing: 12

                        // Dotfiles header
                        Rectangle {
                            Layout.fillWidth: true; height: 64; radius: 12
                            color: Qt.rgba(1,1,1,0.05); border.color: Theme.colBorder; border.width: 1
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 16; spacing: 14
                                Text { text: ""; color: Theme.colBlue; font { family: "Symbols Nerd Font"; pixelSize: 28 } }
                                ColumnLayout {
                                    spacing: 2; Layout.fillWidth: true
                                    Text { text: "Pala's Shell"; color: Theme.colWhite; font { family: Theme.fontDisplay; pixelSize: 15; bold: true } }
                                    Text { text: "Quickshell · Hyprland"; color: Theme.colMuted; font { family: Theme.fontFamily; pixelSize: 11 } }
                                }
                            }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.colBorder }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 20
                            Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                        // FIX: each AboutRow uses width: parent.width so it fills correctly
                            ColumnLayout {
                                width: parent.width; spacing: 12
                                AboutRow { icon: "󰌽"; label: "Hostname"; value: settingsWindow.sysHostname }
                                AboutRow { icon: "󰣇"; label: "Distro";   value: settingsWindow.sysDistro   }
                                AboutRow { icon: "󰒋"; label: "Kernel";   value: settingsWindow.sysKernel   }
                                AboutRow { icon: "󰻠"; label: "CPU";      value: settingsWindow.sysCpu      }
                                AboutRow { icon: "󰍛"; label: "RAM";      value: settingsWindow.sysRam      }
                                AboutRow { icon: "󰋊"; label: "Disk";     value: settingsWindow.sysDisk     }
                                AboutRow { icon: "󱑀"; label: "Uptime";   value: settingsWindow.sysUptime   }
                            }
                            /*Rectangle {
                                width: 2
                                color: Theme.colBorder                    
                                Layout.fillHeight: true
                            }
                            ColumnLayout {
                                width: parent.width; spacing: 12
                                AboutRow { icon: "󰏗"; label: "Packages installed"; value: settingsWindow.packagesCount }
                                
                            }*/
                        }
                    }
                }
            }
        }

        // Toast
        Rectangle {
            id: applyStatus
            anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter; anchors.bottomMargin: 16
            width: statusText.implicitWidth + 32; height: 34; radius: 17
            color: Theme.colBlue; opacity: 0; visible: opacity > 0
            function show(msg) { statusText.text = msg; toastAnim.running = true }
            Text { id: statusText; anchors.centerIn: parent; color: Theme.colWhite; font { family: Theme.fontFamily; pixelSize: 12; bold: true } }
            SequentialAnimation {
                id: toastAnim
                NumberAnimation { target: applyStatus; property: "opacity"; to: 1; duration: 150 }
                PauseAnimation  { duration: 1800 }
                NumberAnimation { target: applyStatus; property: "opacity"; to: 0; duration: 300 }
            }
        }

        NumberAnimation {
            id: fadeAnim; target: card; property: "opacity"; duration: 250; easing.type: Easing.OutCubic
            onStopped: { if (card.opacity === 0) settingsWindow.visible = false }
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // Components
    // ═══════════════════════════════════════════════════════════════════════════

    component SidebarBtn: Rectangle {
        property string label: ""; property string icon: ""
        property int page: 0; property int currentPage: 0
        signal nav(int page)
        Layout.fillWidth: true; height: 38; radius: 10
        color: currentPage === page ? Qt.rgba(1,1,1,0.10) : (btnMouse.containsMouse ? Qt.rgba(1,1,1,0.06) : "transparent")
        Behavior on color { ColorAnimation { duration: 120 } }
        RowLayout {
            anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 12; spacing: 10
            Text { 
                text: icon
                color: currentPage === page ? Theme.colBlue : Theme.colMuted
                font { family: "Symbols Nerd Font"; pixelSize: 15 }
                Behavior on color { ColorAnimation { duration: 120 } } 
                }
            Text { 
                text: label
                color: currentPage === page ? Theme.colWhite : Theme.colMuted
                font { family: Theme.fontFamily; pixelSize: 13; bold: currentPage === page } 
                Behavior on color { ColorAnimation { duration: 120 } } 
            }
        }
        MouseArea { id: btnMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: nav(page) }
    }

    component SettingsPage: Item {
        property string title: ""; property string subtitle: ""
        default property alias content: innerCol.children
        Layout.fillWidth: true; Layout.fillHeight: true
        ColumnLayout {
            anchors.fill: parent; anchors.margins: 28; spacing: 0
            Text { text: title;    color: Theme.colWhite; font { family: Theme.fontDisplay; pixelSize: 26; bold: true } }
            Text { text: subtitle; color: Theme.colMuted; font { family: Theme.fontFamily;  pixelSize: 12 } }
            Item { Layout.preferredHeight: 20 }
            Item {
                Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                Flickable {
                    anchors.fill: parent
                    contentHeight: innerCol.implicitHeight
                    contentWidth: width
                    flickableDirection: Flickable.VerticalFlick
                    // only grab scroll when content overflows — lets sliders work normally
                    interactive: contentHeight > height
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                    ColumnLayout {
                        id: innerCol
                        width: parent.width
                        spacing: 12
                    }
                }
            }
        }
    }

    component ColorRow: RowLayout {
        property string label: ""; property string value: ""
        Layout.fillWidth: true; spacing: 12
        Rectangle { width: 36; height: 36; radius: 10; color: value; border.color: Theme.colBorder; border.width: 1 }
        ColumnLayout {
            spacing: 2; Layout.fillWidth: true
            Text { text: label; color: Theme.colFg;    font { family: Theme.fontFamily; pixelSize: 13 } }
            Text { text: value; color: Theme.colMuted; font { family: Theme.fontFamily; pixelSize: 11 } }
        }
    }

    // FIX: ToggleRow root is now a plain Rectangle with explicit width: parent.width
    // NOT using Layout at all — placed inside a Column, not ColumnLayout
    component ToggleRow: Rectangle {
        property string label: ""; property string desc: ""
        property bool checked: false
        signal toggled(bool v)
        // size comes from parent Column, not from Layout engine
        width: parent ? parent.width : 0
        height: 56; radius: 10
        color: Qt.rgba(1,1,1,0.04); border.color: Theme.colBorder; border.width: 1
        RowLayout {
            anchors {
                left: parent.left; right: parent.right
                top: parent.top; bottom: parent.bottom
                leftMargin: 14; rightMargin: 14
            }
            spacing: 10
            ColumnLayout {
                Layout.fillWidth: true; spacing: 2
                Text { text: label; color: Theme.colFg;    font { family: Theme.fontFamily; pixelSize: 13; bold: true } }
                Text { text: desc;  color: Theme.colMuted; font { family: Theme.fontFamily; pixelSize: 11 } }
            }
            Rectangle {
                Layout.alignment: Qt.AlignRight
                width: 44; height: 24; radius: 12
                color: checked ? Theme.colBlue : Qt.rgba(1,1,1,0.12)
                Behavior on color { ColorAnimation { duration: 150 } }
                Rectangle {
                    x: checked ? parent.width - width - 3 : 3
                    y: 3; width: 18; height: 18; radius: 9; color: Theme.colWhite
                    Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: toggled(!checked)
                }
            }
        }
    }

    component ShellSlider: Slider {
        Layout.fillWidth: true
        implicitHeight: 28
        background: Rectangle {
            x: parent.leftPadding; y: parent.topPadding + parent.availableHeight / 2 - height / 2
            width: parent.availableWidth; height: 4; radius: 2; color: Qt.rgba(1,1,1,0.1)
            Rectangle { width: parent.parent.visualPosition * parent.width; height: parent.height; radius: 2; color: Theme.colBlue }
        }
        handle: Rectangle {
            x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
            y: parent.topPadding + parent.availableHeight / 2 - height / 2
            width: 16; height: 16; radius: 8
            color: parent.pressed ? Qt.lighter(Theme.colBlue, 1.2) : Theme.colBlue
            Behavior on color { ColorAnimation { duration: 100 } }
        }
    }

    // Font picker: label + current font preview + scrollable dropdown
    component FontPickerRow: ColumnLayout {
        property string label: ""
        property string currentFont: ""
        property var fonts: []
        signal picked(string font)

        property bool open: false
        Layout.fillWidth: true; spacing: 6

        Text { text: label; color: Theme.colMuted; font { family: Theme.fontFamily; pixelSize: 11 } }

        // Trigger button showing current selection
        Rectangle {
            Layout.fillWidth: true; height: 42; radius: 10
            color: triggerArea.containsMouse ? Qt.rgba(1,1,1,0.08) : Qt.rgba(1,1,1,0.04)
            border.color: open ? Theme.colBlue : Theme.colBorder; border.width: 1
            Behavior on color { ColorAnimation { duration: 100 } }
            Behavior on border.color { ColorAnimation { duration: 100 } }
            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 8
                Text {
                    text: currentFont !== "" ? currentFont : "Select a font…"
                    color: currentFont !== "" ? Theme.colFg : Theme.colMuted
                    font { family: currentFont !== "" ? currentFont : Theme.fontFamily; pixelSize: 14 }
                    Layout.fillWidth: true; elide: Text.ElideRight
                }
                Text {
                    text: open ? "󰅃" : "󰅀"
                    color: Theme.colMuted; font { family: "Symbols Nerd Font"; pixelSize: 14 }
                }
            }
            MouseArea { id: triggerArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: open = !open }
        }

        // Dropdown list
        Rectangle {
            Layout.fillWidth: true
            height: open ? Math.min(fonts.length * 36, 200) : 0
            radius: 10; clip: true
            color: Qt.rgba(0, 0, 0); border.color: Theme.colBorder; border.width: open ? 1 : 0
            visible: open
            Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            ListView {
                anchors.fill: parent; anchors.margins: 4
                model: fonts
                clip: true
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                delegate: Rectangle {
                    required property string modelData
                    required property int index
                    width: ListView.view.width; height: 36; radius: 8
                    color: modelData === currentFont
                        ? Qt.rgba(1,1,1,0.12)
                        : (rowHover.containsMouse ? Qt.rgba(1,1,1,0.07) : Qt.rgba(0, 0, 0, 0.86))
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 8
                        Text {
                            text: modelData; Layout.fillWidth: true; elide: Text.ElideRight
                            color: modelData === currentFont ? Theme.colWhite : Theme.colFg
                            font { family: modelData; pixelSize: 13 }
                        }
                        Text {
                            visible: modelData === currentFont
                            text: ""; color: Theme.colBlue
                            font { family: "Symbols Nerd Font"; pixelSize: 12 }
                        }
                    }
                    MouseArea {
                        id: rowHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { picked(modelData); open = false }
                    }
                }
            }
        }
    }

    component AboutRow: RowLayout {
        property string icon: ""; property string label: ""; property string value: ""
        Layout.fillWidth: true; spacing: 12
        Rectangle {
            width: 36; height: 36; radius: 10
            color: Qt.rgba(1,1,1,0.05); border.color: Theme.colBorder; border.width: 1
            Text { anchors.centerIn: parent; text: icon; color: Theme.colBlue; font { family: "Symbols Nerd Font"; pixelSize: 16 } }
        }
        ColumnLayout {
            spacing: 1; Layout.fillWidth: true
            Text { text: label; color: Theme.colMuted; font { family: Theme.fontFamily; pixelSize: 11 } }
            Text { text: value; color: Theme.colFg; elide: Text.ElideRight; Layout.fillWidth: true; font { family: Theme.fontFamily; pixelSize: 13 } }
        }
    }
}
