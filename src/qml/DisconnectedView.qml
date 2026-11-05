import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: root

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 24
        width: Math.min(500, parent.width - 40)

        // Hardware USB Icon
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 80
            height: 80
            radius: 40
            color: "#222225"
            border.color: "#383840"
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "🔌"
                font.pixelSize: 36
            }
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 8

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: stateManager ? stateManager.strings.device_disconnected_title : "RØDECaster Desconectada"
                font.pixelSize: 22
                font.bold: true
                color: "#FFFFFF"
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter
                text: stateManager ? stateManager.strings.device_disconnected_desc : "Conecta tu RØDECaster Duo o Pro II por cable USB a tu computadora para comenzar."
                font.pixelSize: 13
                color: "#99999E"
                wrapMode: Text.Wrap
            }
        }

        // Action button
        Button {
            Layout.alignment: Qt.AlignHCenter
            text: stateManager ? stateManager.strings.scan_device : "Buscar dispositivo ahora"
            HoverHandler { cursorShape: Qt.PointingHandCursor }

            contentItem: Text {
                text: parent.text
                font.pixelSize: 13
                font.weight: Font.Medium
                color: "#FFFFFF"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            background: Rectangle {
                implicitWidth: 200
                implicitHeight: 38
                radius: 6
                color: parent.down ? "#A6823C" : (parent.hovered ? "#DAB265" : "#CBA158")
            }

            onClicked: {
                if (stateManager) stateManager.refresh();
            }
        }
    }
}
