import QtQuick
import QtQuick.Shapes
import Quickshell.Widgets

import "../"
Item {
    id: root
    width: 75
    height: 75

    property real   progress:    0.0   // 0.0 → 1.0
    property string label:       ""
    property int    strokeWidth: 10

    // Track color is always the surface/muted color
    readonly property color trackColor: Theme.colSurface       // ← Theme

    // Progress color shifts based on load — driven by Theme status colors
    property color progressColor: Theme.colOk                  // ← Theme

    readonly property real clampedProgress: Math.max(0, Math.min(1, progress))

    Timer {
        interval: 500; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            if (progress > 0.8)
                progressColor = Theme.colCrit                  // ← Theme
            else if (progress > 0.6)
                progressColor = Theme.colWarn                  // ← Theme
            else
                progressColor = Theme.colOk                    // ← Theme
        }
    }

    Shape {
        anchors.centerIn: parent
        width: 50; height: 50
        antialiasing: true

        // Track arc
        ShapePath {
            strokeWidth: root.strokeWidth
            strokeColor: root.trackColor
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: 25; centerY: 25
                radiusX: 45; radiusY: 45
                startAngle: 135; sweepAngle: 270
            }
        }

        // Progress arc
        ShapePath {
            strokeWidth: root.strokeWidth
            strokeColor: root.progressColor
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                Behavior on sweepAngle { NumberAnimation { duration: 125; easing.type: Easing.OutCubic } }
                centerX: 25; centerY: 25
                radiusX: 45; radiusY: 45
                startAngle: 135
                sweepAngle: 270 * root.clampedProgress
            }
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 2

        Text {
            text: Math.round(root.clampedProgress * 100) + "%"
            font { family: Theme.fontFamily; pixelSize: 14; bold: true } // ← Theme
            color: Theme.colWhite                                         // ← Theme
            horizontalAlignment: Text.AlignHCenter
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: root.label
            font { family: Theme.fontFamily; pixelSize: 18; bold: true } // ← Theme
            color: Theme.colMuted                                         // ← Theme (was "#aaaaaa")
            horizontalAlignment: Text.AlignHCenter
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}
