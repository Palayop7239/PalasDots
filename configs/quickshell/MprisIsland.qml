import QtQuick
import QtQuick.Layouts
import Quickshell.Wayland
import Quickshell.Services.Mpris
import Quickshell.Widgets

import "../"

Rectangle {
    id: island

    property var targetWindow
    property MprisPlayer player: null   // receives shell.activePlayer directly

    // Derived from the player object — all reactive, no polling
    readonly property string title:      player?.trackTitle  ?? ""
    readonly property string artist:     player?.trackArtist.replace(/ - Topic/gi, "") ?? ""
    readonly property string album:      player?.trackAlbum  ?? ""
    readonly property string coverUrl:   player?.trackArtUrl ?? ""
    readonly property string playerName: {
        var name = player?.identity ?? ""
        if (name.toLowerCase() === "vlc") return "VLC"
        return name.charAt(0).toUpperCase() + name.slice(1)
    }

    visible: true
    height: 22
    width: islandRow.implicitWidth * 1.25 + (coverUrl.length > 0 ? 38 : 75)
    radius: 11
    color: Theme.colOverlay
    border.color: Theme.colBorder
    border.width: 1
    clip: true

    Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

    Timer {
        id: hideTimer
        interval: 500
        onTriggered: {
            if (!controlPopup.isActive())
                controlPopup.close()
            else
                hideTimer.restart()
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        onEntered: { hideTimer.stop(); controlPopup.open() }
        onExited:  hideTimer.restart()
    }

    IslandWindow {
        id: controlPopup
        visible: false
        anchorWindow: island.targetWindow
        player: island.player               // pass it straight through
        /*onActiveChanged: {
            if (controlPopup.isActive()) hideTimer.stop()
            else hideTimer.restart()
        }*/
    }

    // Album art thumbnail
    ClippingWrapperRectangle {
        id: thumb
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: island.coverUrl.length > 0 ? 22 : 0
        height: 22
        radius: 10
        color: "transparent"
        clip: true
        border.color: Theme.colBorder
        border.width: 1
        Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Image {
            anchors.fill: parent
            source: island.coverUrl
            fillMode: Image.PreserveAspectCrop
        }
    }

    Row {
        id: islandRow
        anchors.left: island.coverUrl.length > 0 ? thumb.right : parent.left
        anchors.leftMargin: island.coverUrl.length > 0 ? 6 : 12
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.centerIn: parent
        Text {
            text: "     " + island.title
            color: Theme.colWhite
            horizontalAlignment: Qt.AlignCenter
            font { family: Theme.fontFamily; pixelSize: 11; bold: true }
            elide: Text.ElideRight
        }
    }
}
