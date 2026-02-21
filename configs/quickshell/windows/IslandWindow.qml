import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell.Widgets

import "../widgets"
import "../"

PopupWindow {
    id: islandPop

    property var anchorWindow
    property MprisPlayer player: null   // receives the player object directly

    // All derived reactively — no polling, no prop-drilling strings
    readonly property string title:      player?.trackTitle  ?? ""
    readonly property string artist:     player?.trackArtist.replace(/ - Topic/gi, "") ?? ""
    readonly property string album:      player?.trackAlbum  ?? ""
    readonly property string coverUrl:   player?.trackArtUrl ?? ""
    readonly property bool   isPlaying:  player?.playbackState === MprisPlaybackState.Playing
    readonly property string playerName: {
        var name = player?.identity ?? ""
        if (name.toLowerCase() === "vlc") return "VLC"
        return name.charAt(0).toUpperCase() + name.slice(1)
    }

    property var hoveredItems: [popupHoverArea, buttonArea,settingsArea, prevButton, playButton, nextButton]

    function isActive() {
        for (var i = 0; i < hoveredItems.length; i++) {
            var item = hoveredItems[i]
            if (!item) continue
            if (item.hovered !== undefined ? item.hovered : item.containsMouse)
                return true
        }
        return false
    }

    anchor.window: anchorWindow
    anchor.rect.x: anchorWindow ? (anchorWindow.width / 2 - width / 2) : 0
    anchor.rect.y: anchorWindow ? anchorWindow.height : 0

    implicitWidth: 750
    implicitHeight: 500
    color: "transparent"

    function open() {
        card.opacity = 0
        this.visible = true
        fadeAnim.from = 0
        fadeAnim.to = 1
        fadeAnim.running = true
        island.width = islandRow.implicitWidth * 1.75 + (coverUrl.length > 0 ? 38 : 150)
    }

    function close() {
        fadeAnim.from = 1
        fadeAnim.to = 0
        fadeAnim.running = true
        island.width = islandRow.implicitWidth * 1.25 + (coverUrl.length > 0 ? 38 : 75)
    }

    // ── System stats ──────────────────────────────────────────────────────────
    property int cpuPercent:  0
    property int memPercent:  0
    property int gpuPercent:  0
    property int lastCpuIdle: 0
    property int lastCpuTotal: 0

    Timer {
        interval: 2000; repeat: true; running: true
        onTriggered: { cpuProc.running = true; memProc.running = true; gpuProc.running = true }
    }
    Process {
        id: cpuProc
        command: ["sh", "-c", "head -1 /proc/stat"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var p     = data.trim().split(/\s+/)
                var idle  = parseInt(p[4]) + parseInt(p[5])
                var total = p.slice(1, 8).reduce((a, b) => a + parseInt(b), 0)
                if (lastCpuTotal > 0)
                    cpuPercent = Math.round(100 * (1 - (idle - lastCpuIdle) / (total - lastCpuTotal)))
                lastCpuTotal = total
                lastCpuIdle  = idle
            }
        }
        Component.onCompleted: running = true
    }
    Process {
        id: memProc
        command: ["sh", "-c", "free | grep Mem"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var parts     = data.trim().split(/\s+/)
                var total     = parseInt(parts[1])
                var available = parseInt(parts[6])
                memPercent = Math.round(100 * ((total - available) / total))
            }
        }
        Component.onCompleted: running = true
    }
    Process {
        id: gpuProc
        command: ["sh", "-c", "cat /sys/class/drm/card1/device/gpu_busy_percent"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                gpuPercent = parseInt(data.trim())
            }
        }
        Component.onCompleted: running = true
    }

    // ── UI ────────────────────────────────────────────────────────────────────
    Rectangle {
        id: card
        anchors.fill: parent
        radius: 24
        color: Theme.colOverlay
        border.color: Theme.colBorder
        border.width: 5
        clip: true
        opacity: 1

        MouseArea {
            id: popupHoverArea
            anchors.fill: parent
            hoverEnabled: true
            propagateComposedEvents: true
            preventStealing: true
            onPressed: mouse.accepted = false
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15

            // Header
            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                Rectangle {
                    id: cheatsheetButton
                    color: Theme.colSurface
                    border.color: Theme.colBorder
                    border.width: 2
                    radius: 24
                    Layout.alignment: Qt.AlignLeft
                    Layout.preferredWidth: 42
                    Layout.preferredHeight: 42
                    Text {
                        anchors.centerIn: parent
                        text: "󰌌"
                        color: Theme.colWhite
                        font { pixelSize: 22 }
                    }
                    MouseArea {
                        id: buttonArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: cheatsheetButton.color = '#8a8a8a'
                        onExited:  cheatsheetButton.color = Theme.colSurface
                        onClicked: cheatsheet.toggleCheatsheet()
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "System Overview"
                    color: Theme.colWhite
                    font { family: Theme.fontDisplay; pixelSize: 32; bold: true }
                }
                Item { Layout.fillWidth: true }
                Rectangle {
                    id: settingsButton
                    color: Theme.colSurface
                    border.color: Theme.colBorder
                    border.width: 2
                    radius: 24
                    Layout.alignment: Qt.AlignLeft
                    Layout.preferredWidth: 42
                    Layout.preferredHeight: 42
                    Text {
                        anchors.centerIn: parent
                        text: ""
                        color: Theme.colWhite
                        font { pixelSize: 22 }
                    }
                    MouseArea {
                        id: settingsArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: settingsButton.color = '#8a8a8a'
                        onExited:  settingsButton.color = Theme.colSurface
                        onClicked: {
                            if (settingsWindow !== undefined)
                            settingsWindow.toggle()
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }

            // Player name
            Text {
                text: islandPop.playerName !== "" ? "Playing on " + islandPop.playerName : ""
                color: Theme.colWhite
                font { family: Theme.fontDisplay; pixelSize: 16; bold: true }
                Layout.alignment: Qt.AlignHCenter
            }

            // MPRIS section
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 150
                spacing: 0

                ClippingWrapperRectangle {
                    Layout.preferredWidth: 125
                    Layout.preferredHeight: 125
                    radius: 28
                    color: Theme.colSurface
                    clip: true
                    Image {
                        anchors.fill: parent
                        anchors.centerIn: parent
                        source: islandPop.coverUrl
                        fillMode: Image.PreserveAspectCrop
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 0

                    Item { Layout.fillHeight: true }

                    Text {
                        text: islandPop.title !== "" ? islandPop.title : "Nothing is playing"
                        color: Theme.colWhite
                        font { family: Theme.fontDisplay; pixelSize: 16; bold: true }
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Text {
                        text: islandPop.album
                        color: Theme.colFg
                        font { family: Theme.fontDisplay; pixelSize: 15 }
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Text {
                        text: islandPop.artist
                        color: Theme.colFg
                        font { family: Theme.fontDisplay; pixelSize: 15 }
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Item { Layout.preferredHeight: 6 }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Item { Layout.fillWidth: true }
                        ControlBtn { id: prevButton; text: "󰒮"; onClicked: islandPop.player?.previous() }
                        Item { Layout.preferredWidth: 16 }
                        ControlBtn {
                            id: playButton
                            text: islandPop.isPlaying ? "󰏤" : "󰐊"
                            onClicked: islandPop.player?.togglePlaying()
                        }
                        Item { Layout.preferredWidth: 16 }
                        ControlBtn { id: nextButton; text: "󰒭"; onClicked: islandPop.player?.next() }
                        Item { Layout.fillWidth: true }
                    }

                    Item { Layout.preferredHeight: 8 }
                    Item { Layout.fillHeight: true }
                }
            }

            Item { Layout.fillHeight: true }

            Text {
                text: "Performance Monitor"
                color: Theme.colWhite
                font { family: Theme.fontDisplay; pixelSize: 16; bold: true }
                Layout.alignment: Qt.AlignHCenter
            }

            // CPU / RAM / GPU
            RowLayout {
                spacing: 75
                Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                CircularWidget { progress: cpuPercent / 100; label: "CPU"; Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter }
                CircularWidget { progress: memPercent / 100; label: "RAM"; Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter }
                CircularWidget { progress: gpuPercent / 100; label: "GPU"; Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter }
            }
        }
    }

    NumberAnimation {
        id: fadeAnim
        target: card
        property: "opacity"
        duration: 300
        easing.type: Easing.OutCubic
        onStopped: { if (card.opacity === 0) islandPop.visible = false }
    }

    component ControlBtn: Text {
        signal clicked()
        property bool hovered: false
        color: hovered ? Theme.colBlue : Theme.colWhite
        font { family: "Symbols Nerd Font"; pixelSize: 32 }
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
            onEntered: parent.hovered = true
            onExited:  parent.hovered = false
        }
    }
}
