import QtQuick
import QtQuick.Shapes

Item {
    id: root

    property string name: ""
    property color color: "#C8C8CC"
    property real strokeWidth: 2.0

    implicitWidth: 24
    implicitHeight: 24

    readonly property bool isFilled: {
        return name === "toggle" || name === "oneshot" || name === "hold";
    }

    readonly property string pathData: {
        switch (name) {
        case "toggle":
            // Play / Pause combined
            return "M 5 5 L 13 12 L 5 19 Z M 16 5.5 H 18 V 18.5 H 16 Z M 20 5.5 H 22 V 18.5 H 20 Z";
        case "oneshot":
            // Single Play triangle
            return "M 6 4 L 19 12 L 6 20 Z";
        case "hold":
            // Play with hold stop bar
            return "M 5 5 L 14 12 L 5 19 Z M 18 5 H 20 V 19 H 18 Z";
        case "loop_on":
            // Clean repeat loop arrows
            return "M 17 2 L 21 6 L 17 10 M 3 11 V 10 C 3 7.8 4.8 6 7 6 H 21 M 7 22 L 3 18 L 7 14 M 21 13 V 14 C 21 16.2 19.2 18 17 18 H 3";
        case "loop_off":
            // Repeat loop with diagonal slash
            return "M 17 2 L 21 6 L 17 10 M 3 11 V 10 C 3 7.8 4.8 6 7 6 H 21 M 7 22 L 3 18 L 7 14 M 21 13 V 14 C 21 16.2 19.2 18 17 18 H 3 M 2 2 L 22 22";
        case "replay":
            // Rotate-CCW / Replay circular arrow
            return "M 3 12 A 9 9 0 1 0 6 5.3 L 3 8 M 3 3 V 8 H 8";
        case "folder":
            // Standard Feather Folder
            return "M 22 19 A 2 2 0 0 1 20 21 H 4 A 2 2 0 0 1 2 19 V 5 A 2 2 0 0 1 4 3 H 9 L 11 6 H 20 A 2 2 0 0 1 22 8 Z";
        case "drag_drop":
            // Import / Tray with down arrow
            return "M 21 15 V 19 A 2 2 0 0 1 19 21 H 5 A 2 2 0 0 1 3 19 V 15 M 7 10 L 12 15 L 17 10 M 12 15 V 3";
        case "export":
            // Export / Tray with up arrow
            return "M 21 15 V 19 A 2 2 0 0 1 19 21 H 5 A 2 2 0 0 1 3 19 V 15 M 17 8 L 12 3 L 7 8 M 12 3 V 15";
        case "sound_wave":
            // Audio wave bars
            return "M 2 10 V 14 M 6 6 V 18 M 10 3 V 21 M 14 7 V 17 M 18 5 V 19 M 22 10 V 14";
        case "eraser":
            // Trash / delete pad
            return "M 3 6 H 21 M 19 6 V 20 A 2 2 0 0 1 17 22 H 7 A 2 2 0 0 1 5 20 V 6 M 8 6 V 4 A 2 2 0 0 1 10 2 H 14 A 2 2 0 0 1 16 4 V 6 M 10 11 V 17 M 14 11 V 17";
        case "pencil":
            // Edit pencil
            return "M 17 3 A 2.85 2.83 0 1 1 21 7 L 7.5 20.5 L 2 22 L 3.5 16.5 Z";
        default:
            return "";
        }
    }

    Item {
        anchors.centerIn: parent
        width: 24
        height: 24
        scale: Math.min(root.width / 24.0, root.height / 24.0)
        transformOrigin: Item.Center

        Shape {
            anchors.fill: parent
            layer.enabled: true
            layer.samples: 8

            ShapePath {
                strokeColor: root.color
                strokeWidth: root.isFilled ? 0.5 : root.strokeWidth
                fillColor: root.isFilled ? root.color : "transparent"
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin

                PathSvg {
                    path: root.pathData
                }
            }
        }
    }
}
