import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Services.UPower
import Quickshell.Services.SystemTray

import "./windows"
import "./widgets"

ShellRoot {
    id: shell

    FontLoader { source: "file:///usr/share/fonts/apple-fonts/SF-Pro-Text-Regular.otf" }
    FontLoader { source: "file:///usr/share/fonts/apple-fonts/SF-Pro-Text-Bold.otf" }
    FontLoader { source: "file:///usr/share/fonts/apple-fonts/SF-Pro-Display-Regular.otf" }
    FontLoader { source: "file:///usr/share/fonts/apple-fonts/SF-Pro-Display-Bold.otf" }

    // ── MPRIS — pick the first active player reactively, zero polling ─────────
    property MprisPlayer activePlayer: {
        var players = Mpris.players.values
        for (var i = 0; i < players.length; i++)
            if (players[i].playbackState === MprisPlaybackState.Playing)
                return players[i]
        return players.length > 0 ? players[0] : null
    }

    // ── Misc ──────────────────────────────────────────────────────────────────
    Process {
        id: logoffProc; running: false
        command: ["bash", "-c", "rofi -show power-menu -modi power-menu:rofi-power-menu"]
        stdout: StdioCollector { onStreamFinished: logoffProc.running = false }
    }


    // ── Top bar ───────────────────────────────────────────────────────────────
    PanelWindow {
        id: bar
        anchors.top: true; anchors.left: true; anchors.right: true
        implicitHeight: 30
        color: '#00ffffff'

        RowLayout {
            anchors.fill: parent; anchors.margins: 8; spacing: 20

            // Power menu
            Item {
                Layout.preferredWidth: 24; Layout.preferredHeight: 20; Layout.leftMargin: 10
                Image {
                    anchors.fill: parent
                    source: "file:///home/pala/.config/RicingAssets/Icons/ArchLogo.svg"
                    fillMode: Image.PreserveAspectFit
                    opacity: 0.85
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: logoffProc.running = true }
            }


            // Workspaces
            RowLayout {
                spacing: 10
                Repeater {
                    model: Theme.workspaceCount
                    Rectangle {
                        id: workspaceBG
                        Layout.preferredWidth: 25; Layout.preferredHeight: 20
                        color: "#002eac"
                        radius: 5
                        border.color: Theme.colBorder
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            property var ws: Hyprland.workspaces.values.find(w => w.id === index + 1)
                            property bool isActive: Hyprland.focusedWorkspace?.id === (index + 1)
                            text: index + 1
                            color: isActive ? Theme.colCyan : (ws ? Theme.colBlue : Theme.colMuted)
                            font { family: Theme.fontFamily; pixelSize: 14; bold: true }
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: workspaceBG.color = '#3a5398'
                            onExited:  workspaceBG.color = "#002eac"
                            onClicked: Hyprland.dispatch("workspace " + (index + 1))
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // System tray
            RowLayout {
                visible: Theme.showTray
                spacing: 6
                Repeater {
                    model: SystemTray.items
                    delegate: MouseArea {
                        required property var modelData
                        width: 20; height: 20
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        Image {
                            anchors.fill: parent
                            source: modelData.icon
                            fillMode: Image.PreserveAspectFit
                        }
                        onClicked: (mouse) => {
                            if (mouse.button === Qt.LeftButton && modelData.activate)
                                modelData.activate()
                            else if (mouse.button === Qt.RightButton && modelData.display)
                                modelData.display()
                        }
                        onWheel: (event) => { if (modelData.scroll) modelData.scroll(event.angleDelta.y) }
                    }
                }
            }

            // Swaync
            Item {
                Layout.preferredWidth: 16; Layout.preferredHeight: 16
                Image {
                    anchors.fill: parent
                    source: "file:///home/pala/.config/RicingAssets/Icons/ControlPanel.svg"
                    fillMode: Image.PreserveAspectFit
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: notifProc.running = true }
            }
            Process { id: notifProc; running: false; command: ["swaync-client", "-t"] }

            // Clock
            Text {
                id: clockText
                color: Theme.colBlue
                font { family: Theme.fontFamily; pixelSize: Theme.fontSize; bold: true }
                text: new Date().toLocaleString(Qt.locale(), "HH:mm - ddd, MMM dd")
                Timer {
                    interval: 1000; running: true; repeat: true
                    onTriggered: clockText.text = new Date().toLocaleString(Qt.locale(), "HH:mm - ddd, MMM dd")
                }
            }
        }

        // Pass the whole player object — no more string prop-drilling
        MprisIsland {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            targetWindow: bar
            player: shell.activePlayer
        }
    }
    SettingsWindow {
       id: settingsWindow
       anchorWindow: bar 
    }
    KeybindsWindow {
        id: cheatsheet
        anchorWindow: bar
    }
    
}
