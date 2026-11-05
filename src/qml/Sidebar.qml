import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {
    id: root
    width: 250
    color: "#18181A"

    // Right divider line
    Rectangle {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: 1
        color: "#252528"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 20

        // Device Info Card
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 140
            radius: 10
            color: "#212124"
            border.color: stateManager && stateManager.connected ? "#303035" : "#442222"
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                RowLayout {
                    spacing: 12

                    // Device Hardware Illustration Icon
                    Rectangle {
                        width: 44
                        height: 44
                        radius: 8
                        color: "#161618"
                        border.color: "#2C2C30"
                        border.width: 1
                        clip: true

                        Image {
                            anchors.centerIn: parent
                            width: 36
                            height: 36
                            source: "../../assets/rodecaster.svg"
                            fillMode: Image.PreserveAspectFit
                            mipmap: true
                            smooth: true
                            sourceSize.width: 72
                            sourceSize.height: 72
                        }
                    }

                    ColumnLayout {
                        spacing: 2
                        Layout.fillWidth: true

                        Text {
                            text: stateManager ? stateManager.modelName : "RØDECaster"
                            font.pixelSize: 13
                            font.bold: true
                            color: "#FFFFFF"
                        }

                        Text {
                            text: "Firmware " + (stateManager ? stateManager.firmwareVersion : "1.7.7")
                            font.pixelSize: 11
                            color: "#8E8E93"
                        }

                        Row {
                            spacing: 6
                            Rectangle {
                                width: 7
                                height: 7
                                radius: 3.5
                                anchors.verticalCenter: parent.verticalCenter
                                color: stateManager && stateManager.connected ? "#34C759" : "#FF3B30"
                            }
                            Text {
                                text: stateManager && stateManager.connected ? "Conectada" : "Desconectada"
                                font.pixelSize: 10
                                color: stateManager && stateManager.connected ? "#34C759" : "#FF453A"
                            }
                        }
                    }
                }

                // SD Card Storage Meter
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    RowLayout {
                        Text {
                            text: "💾 MicroSD"
                            font.pixelSize: 11
                            color: "#9A9A9E"
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: (stateManager ? stateManager.sdCardUsed : "0 GB") + " / " + (stateManager ? stateManager.sdCardTotal : "119 GB")
                            font.pixelSize: 11
                            color: "#8E8E93"
                        }
                    }

                    // Progress Bar
                    Rectangle {
                        Layout.fillWidth: true
                        height: 4
                        radius: 2
                        color: "#323236"

                        Rectangle {
                            width: Math.max(4, parent.width * ((stateManager ? stateManager.sdCardPercent : 0) / 100.0))
                            height: parent.height
                            radius: 2
                            color: "#CBA158"
                        }
                    }
                }
            }
        }

        // Permission warning banner if permission is not set
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 110
            radius: 8
            color: "#2C1B1B"
            border.color: "#8A3030"
            visible: stateManager && stateManager.permissionError

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6

                Text {
                    text: "⚠️ Permiso USB requerido"
                    font.pixelSize: 12
                    font.bold: true
                    color: "#FFA2A2"
                }

                Text {
                    text: "Para interactuar con el dispositivo, ejecuta:\n./install.sh en la carpeta del programa"
                    font.pixelSize: 10
                    color: "#D0D0D0"
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
            }
        }

        Item { Layout.fillHeight: true }

        // Bottom quick info
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#252528"
            }

            RowLayout {
                Text {
                    text: "CasterManager"
                    font.pixelSize: 11
                    font.bold: true
                    color: "#777777"
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: "v1.0 Linux"
                    font.pixelSize: 10
                    color: "#555555"
                }
            }
        }
    }
}

