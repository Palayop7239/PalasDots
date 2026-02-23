import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell.Widgets
import Quickshell.Hyprland
import "../"

PopupWindow {
    id: cheatsheet
    property var anchorWindow
    property string fontFamily: Theme.fontDisplay

    anchor.window: anchorWindow
    anchor.rect.x: (screen.width - width) / 2
    anchor.rect.y: (screen.height - height) / 1.1
    implicitWidth: 750
    implicitHeight: 500
    color: "transparent"

    function open() {
        keybindsCard.opacity = 0
        cheatsheet.visible = true
        fadeAnim.from = 0
        fadeAnim.to = 1
        fadeAnim.running = true
    }

    function close() {
        fadeAnim.from = 1
        fadeAnim.to = 0
        fadeAnim.running = true
    }

    Rectangle {
        id: keybindsCard
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.colOverlay                               
        border.color: Theme.colBorder                        
        border.width: 5
        clip: true
        opacity: 0

        MouseArea {
            id: cardArea
            anchors.fill: parent
            hoverEnabled: true
            propagateComposedEvents: true
            onPressed: mouse.accepted = false
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 20
            Layout.alignment: Qt.AlignHCenter

            // Header
            Text {
                text: "Keybinds List"
                color: Theme.colWhite                         
                font { family: cheatsheet.fontFamily; pixelSize: 32; bold: true }
                horizontalAlignment: Text.AlignHCenter
                Layout.alignment: Qt.AlignHCenter
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 20
                Layout.alignment: Qt.AlignHCenter | Qt.AlignTop

                // Left column
                ColumnLayout {
                    spacing: 15

                    KbSection { title: "Window Management" }
                    KbRow { keys: "󰖳  + F";           desc: "Toggle Floating" }
                    KbRow { keys: "󰖳  + Left Click";  desc: "Move Window" }
                    KbRow { keys: "󰖳  + Right Click"; desc: "Resize Window" }

                    KbSection { title: "Utilities" }
                    KbRow { keys: "Print Screen";      desc: "Screenshot (Region)" }
                    KbRow { keys: "󰖳  + Print Screen"; desc: "Screenshot (Screen)" }
                    KbRow { keys: "󰖳  + N";            desc: "Show/Hide this list" }
                    KbRow { keys: "󰖳  + V";            desc: "Clipboard History" }
                    KbRow { keys: "󰖳  + I";            desc: "Pala's Shell Settings" }
                }

                // Divider
                Rectangle {
                    width: 2
                    color: Theme.colBorder                    
                    Layout.fillHeight: true
                }

                // Right column
                ColumnLayout {
                    spacing: 15

                    KbSection { title: "Applications" }
                    KbRow { keys: "󰖳  + E";     desc: "File Explorer" }
                    KbRow { keys: "󰖳  + Space"; desc: "App Launcher" }
                    KbRow { keys: "󰖳  + C";     desc: "Code Editor" }
                    KbRow { keys: "󰖳  + F";     desc: "Web Browser" }
                    KbRow { keys: "󰖳  + A";     desc: "Terminal" }

                    KbSection { title: "Workspaces Management" }
                    KbRow { keys: "󰖳  + Tab";       desc: "Next Workspace" }
                    KbRow { keys: "󰖳  + 1-9";       desc: "Go to Workspace" }
                    KbRow { keys: "󰖳  + Alt + 1-9"; desc: "Move to Workspace" }
                }
            }
        }
    }

    NumberAnimation {
        id: fadeAnim
        target: keybindsCard
        property: "opacity"
        duration: 300
        easing.type: Easing.OutCubic
        onStopped: {
            if (keybindsCard.opacity === 0)
                cheatsheet.visible = false
        }
    }

    function toggleCheatsheet() {
        if (cheatsheet.visible) close()
        else open()
    }

    GlobalShortcut {
        name: "togglekeybinds"
        description: "Toggles the keybinds guide"
        onPressed: cheatsheet.toggleCheatsheet()
    }

    

    component KbSection: Text {
        property string title: ""
        text: title
        color: Theme.colWhite                                  // ← Theme
        font { family: cheatsheet.fontFamily; pixelSize: 24; bold: true }
        horizontalAlignment: Text.AlignHCenter
        Layout.alignment: Qt.AlignHCenter
    }

    component KbRow: RowLayout {
        property string keys: ""
        property string desc: ""
        spacing: 10
        Layout.alignment: Qt.AlignHCenter
        Text { text: keys; color: Theme.colWhite; font { pixelSize: 18; bold: true } }  // ← Theme
        Text { text: desc; color: Theme.colFg;    font { pixelSize: 16 } }              // ← Theme
    }
}
