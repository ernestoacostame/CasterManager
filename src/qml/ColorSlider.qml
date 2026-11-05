import QtQuick
import QtQuick.Controls

Item {
    id: root
    implicitWidth: 260
    implicitHeight: 28

    property int selectedIndex: 0
    signal colorSelected(int index)

    readonly property var colors: [
        "#FF3C3C", "#FF8C28", "#FFDC28", "#8CE63C",
        "#28C850", "#28D2AA", "#28C8DC", "#3C96FF",
        "#5050FF", "#A050E6", "#E650B4", "#E63C78"
    ]

    // Track
    Rectangle {
        id: track
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: 6
        radius: 3
        clip: true

        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.00; color: "#FF3C3C" }
            GradientStop { position: 0.09; color: "#FF8C28" }
            GradientStop { position: 0.18; color: "#FFDC28" }
            GradientStop { position: 0.27; color: "#8CE63C" }
            GradientStop { position: 0.36; color: "#28C850" }
            GradientStop { position: 0.45; color: "#28D2AA" }
            GradientStop { position: 0.54; color: "#28C8DC" }
            GradientStop { position: 0.63; color: "#3C96FF" }
            GradientStop { position: 0.72; color: "#5050FF" }
            GradientStop { position: 0.81; color: "#A050E6" }
            GradientStop { position: 0.90; color: "#E650B4" }
            GradientStop { position: 1.00; color: "#E63C78" }
        }
    }

    // Thumb / Knob
    Rectangle {
        id: thumb
        width: 18
        height: 18
        radius: 9
        y: (parent.height - height) / 2
        x: Math.max(0, Math.min(parent.width - width, (selectedIndex / (colors.length - 1)) * (parent.width - width)))

        color: colors[Math.min(selectedIndex, colors.length - 1)]
        border.color: "#FFFFFF"
        border.width: 2.5

        Behavior on x {
            NumberAnimation { duration: 120; easing.type: Easing.OutQuad }
        }

        // Glow ring
        Rectangle {
            anchors.centerIn: parent
            width: parent.width + 6
            height: parent.height + 6
            radius: width / 2
            color: "transparent"
            border.color: thumb.color
            opacity: 0.4
            border.width: 1.5
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        function updateFromPos(mouseX) {
            let ratio = Math.max(0.0, Math.min(1.0, (mouseX - thumb.width / 2) / (root.width - thumb.width)));
            let idx = Math.round(ratio * (colors.length - 1));
            if (idx !== root.selectedIndex) {
                root.selectedIndex = idx;
                root.colorSelected(idx);
            }
        }

        onPressed: (mouse) => updateFromPos(mouse.x)
        onPositionChanged: (mouse) => {
            if (pressed) updateFromPos(mouse.x);
        }
    }
}

