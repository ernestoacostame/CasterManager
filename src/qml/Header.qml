import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {
    id: root
    height: 60
    color: "#161616"

    signal backClicked()
    signal settingsClicked()
    signal editProfileClicked()

    readonly property var iconColors: ["#CBA158", "#FF3C3C", "#28C850", "#3C96FF", "#A050E6", "#FF8C28"]

    // Bottom subtle divider
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: "#242424"
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        spacing: 16

        // Back button
        Rectangle {
            width: 36
            height: 36
            radius: 18
            color: backArea.containsMouse ? "#2A2A2A" : "transparent"

            Text {
                anchors.centerIn: parent
                text: "‹"
                font.pixelSize: 28
                font.bold: true
                color: backArea.containsMouse ? "#FFFFFF" : "#AAAAAA"
            }

            MouseArea {
                id: backArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.backClicked()
            }
        }

        Item { Layout.fillWidth: true }

        // Center: CasterManager title with gold dot
        Column {
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            spacing: 2

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "CasterManager"
                font.pixelSize: 17
                font.bold: true
                font.letterSpacing: 1.2
                color: "#FFFFFF"
            }

            // Iconic gold dot
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 6
                height: 6
                radius: 3
                color: "#CBA158"
            }
        }

        Item { Layout.fillWidth: true }

        // Profile Avatar + Name (Interactive click to edit)
        Rectangle {
            Layout.preferredHeight: 38
            Layout.preferredWidth: profileRow.width + 16
            radius: 19
            color: profileArea.containsMouse ? "#25252A" : "transparent"

            Row {
                id: profileRow
                anchors.centerIn: parent
                spacing: 10

                // Profile Avatar Circle
                Rectangle {
                    width: 30
                    height: 30
                    radius: 15
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.iconColors[stateManager ? (stateManager.showIcon % root.iconColors.length) : 0]
                    border.color: "#FFFFFF"
                    border.width: 1.5
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: stateManager ? stateManager.showName : "TuPodcast"
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    color: "#E0E0E0"
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "✎"
                    font.pixelSize: 11
                    color: "#888888"
                }
            }

            MouseArea {
                id: profileArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.editProfileClicked();
                }
            }
        }

        // Settings gear
        Rectangle {
            width: 36
            height: 36
            radius: 18
            color: settingsArea.containsMouse ? "#2A2A2A" : "transparent"

            Text {
                anchors.centerIn: parent
                text: "⚙"
                font.pixelSize: 18
                color: settingsArea.containsMouse ? "#FFFFFF" : "#999999"
            }

            MouseArea {
                id: settingsArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.settingsClicked()
            }
        }
    }
}
