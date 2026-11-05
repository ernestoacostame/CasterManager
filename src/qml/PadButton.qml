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

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: 8
        color: mouseArea.pressed ? Qt.darker(root.padColor, 2.5) : (mouseArea.containsMouse ? "#262628" : "#1C1C1E")
        border.color: root.isSelected ? root.padColor : (mouseArea.containsMouse ? Qt.rgba(root.padColor.r, root.padColor.g, root.padColor.b, 0.4) : "#2A2A2D")
        border.width: root.isSelected ? 2 : 1

        Behavior on color { ColorAnimation { duration: 100 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }

        // Glow when selected
        Rectangle {
            anchors.fill: parent
            anchors.margins: -4
            radius: 12
            color: "transparent"
            border.color: root.padColor
            border.width: 2
            opacity: root.isSelected ? 0.35 : 0.0
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
                    text: "+"
                    font.pixelSize: 32
                    font.weight: Font.Light
                    color: mouseArea.containsMouse ? "#AAAAAA" : "#666666"
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

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            root.clicked();
        }

        onDoubleClicked: {
            root.triggered();
        }
    }
}

