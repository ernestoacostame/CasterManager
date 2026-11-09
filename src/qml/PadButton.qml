import QtQuick
import QtQuick.Controls

Item {
    id: root

    property var padData: ({})
    property int padIndex: 0
    property bool isSelected: false
    property color padColor: padData && padData.color_hex ? padData.color_hex : "#5050FF"
    property string padName: padData && padData.name ? padData.name : ""
    property string padType: padData && padData.type ? padData.type : "empty"

    signal clicked()
    signal triggered()

    implicitWidth: 105
    implicitHeight: 95

    DropArea {
        id: dropArea
        anchors.fill: parent
        keys: ["castermanager/pad"]

        onDropped: (drop) => {
            if (drop.source && drop.source.padIndex !== undefined && drop.source.padIndex !== root.padIndex) {
                if (stateManager) {
                    stateManager.copyPad(drop.source.padIndex, root.padIndex);
                }
            }
        }
    }

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: 8
        color: {
            if (dropArea.containsDrag && root.padType === "empty") return "#332B1C";
            if (mouseArea.pressed) return Qt.darker(root.padColor, 2.5);
            if (mouseArea.containsMouse) return "#262628";
            return "#1C1C1E";
        }
        border.color: {
            if (dropArea.containsDrag && root.padType === "empty") return "#CBA158";
            if (root.isSelected) return root.padColor;
            if (mouseArea.containsMouse) return Qt.rgba(root.padColor.r, root.padColor.g, root.padColor.b, 0.4);
            return "#2A2A2D";
        }
        border.width: (dropArea.containsDrag && root.padType === "empty") ? 2 : (root.isSelected ? 2 : 1)

        Behavior on color { ColorAnimation { duration: 100 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }

        // Glow when selected or when drop target
        Rectangle {
            anchors.fill: parent
            anchors.margins: -4
            radius: 12
            color: "transparent"
            border.color: (dropArea.containsDrag && root.padType === "empty") ? "#CBA158" : root.padColor
            border.width: 2
            opacity: (root.isSelected || (dropArea.containsDrag && root.padType === "empty")) ? 0.4 : 0.0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        // Inner content
        Column {
            anchors.centerIn: parent
            spacing: 8
            width: parent.width - 16

            // Icon
            Item {
                width: 32
                height: 32
                anchors.horizontalCenter: parent.horizontalCenter

                // Empty pad '+' icon
                Text {
                    anchors.centerIn: parent
                    visible: root.padType === "empty"
                    text: dropArea.containsDrag ? "📥" : "+"
                    font.pixelSize: dropArea.containsDrag ? 20 : 32
                    font.weight: Font.Light
                    color: (dropArea.containsDrag || mouseArea.containsMouse) ? "#CBA158" : "#666666"
                }

                // Waveform bars representation for Sound pads
                Row {
                    anchors.centerIn: parent
                    spacing: 3
                    visible: root.padType === "sound"

                    Repeater {
                        model: [14, 24, 18, 28, 16]
                        Rectangle {
                            width: 3.5
                            height: modelData
                            radius: 1.5
                            anchors.verticalCenter: parent.verticalCenter
                            color: root.padColor
                        }
                    }
                }

                // FX icon
                Text {
                    anchors.centerIn: parent
                    visible: root.padType === "fx"
                    text: "FX"
                    font.pixelSize: 18
                    font.bold: true
                    color: root.padColor
                }

                // Mixer icon
                Text {
                    anchors.centerIn: parent
                    visible: root.padType === "mixer"
                    text: "🎛️"
                    font.pixelSize: 20
                }
            }

            // Pad Name Label
            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: root.padName
                font.pixelSize: 11
                font.weight: Font.Medium
                color: root.isSelected ? "#FFFFFF" : "#C8C8CC"
                visible: root.padName.length > 0
            }
        }
    }

    // Drag Item representation
    Item {
        id: dragItem
        width: root.width
        height: root.height
        Drag.active: mouseArea.drag.active
        Drag.source: root
        Drag.hotSpot.x: width / 2
        Drag.hotSpot.y: height / 2
        Drag.keys: ["castermanager/pad"]

        // Drag preview tile
        Rectangle {
            anchors.fill: parent
            radius: 8
            color: "#222226"
            border.color: "#CBA158"
            border.width: 2
            visible: mouseArea.drag.active
            opacity: 0.85

            Text {
                anchors.centerIn: parent
                text: root.padName || "Pad"
                font.pixelSize: 11
                font.bold: true
                color: "#FFFFFF"
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: mouseArea.drag.active ? Qt.ClosedHandCursor : Qt.PointingHandCursor

        drag.target: root.padType !== "empty" ? dragItem : undefined
        drag.axis: Drag.XAndYAxis

        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                contextMenu.popup();
            } else {
                root.clicked();
            }
        }

        onDoubleClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                root.triggered();
            }
        }
    }

    Menu {
        id: contextMenu

        MenuItem {
            text: "Copiar Pad"
            visible: root.padType !== "empty"
            onTriggered: {
                if (stateManager) {
                    stateManager.selectPad(root.padIndex);
                    stateManager.copyCurrentPad();
                }
            }
        }

        MenuItem {
            text: "Pegar Pad"
            enabled: stateManager ? stateManager.canPastePad : false
            onTriggered: {
                if (stateManager) {
                    stateManager.pasteToPad(root.padIndex);
                }
            }
        }

        MenuSeparator {
            visible: root.padType !== "empty"
        }

        MenuItem {
            text: "Limpiar Pad"
            visible: root.padType !== "empty"
            onTriggered: {
                if (stateManager) {
                    stateManager.selectPad(root.padIndex);
                    stateManager.clearCurrentPad();
                }
            }
        }
    }
}
