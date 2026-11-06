import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: root

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 28
        spacing: 20

        // Header Title Row
        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            Text {
                text: stateManager ? stateManager.strings.hub_recordings : "Transferir Grabaciones"
                font.pixelSize: 22
                font.bold: true
                color: "#FFFFFF"
            }

            Rectangle {
                width: 8
                height: 8
                radius: 4
                color: "#CBA158"
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                text: stateManager ? stateManager.strings.hub_recordings_desc : "Gestiona podcasts y tomas grabadas en la MicroSD"
                font.pixelSize: 13
                color: "#8E8E93"
            }

            Item { Layout.fillWidth: true }

            // Live REC Button in Header
            Rectangle {
                height: 36
                width: recRow.width + 24
                radius: 18
                color: (stateManager && stateManager.isRecording) ? "#FF3B30" : "#28282E"
                border.color: (stateManager && stateManager.isRecording) ? "#FF453A" : "#3E3E46"
                border.width: 1

                Row {
                    id: recRow
                    anchors.centerIn: parent
                    spacing: 8

                    Rectangle {
                        width: 10
                        height: 10
                        radius: 5
                        color: (stateManager && stateManager.isRecording) ? "#FFFFFF" : "#FF3B30"
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: (stateManager && stateManager.isRecording) 
                              ? ("REC " + stateManager.recordTimeString) 
                              : (stateManager ? stateManager.strings.rec_start : "Grabar")
                        font.pixelSize: 12
                        font.bold: true
                        color: "#FFFFFF"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (stateManager) stateManager.toggleRecord();
                    }
                }
            }
        }

        // SD Card Storage Bar Card
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 100
            radius: 12
            color: "#1A1A1D"
            border.color: "#2C2C32"
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true

                    Row {
                        spacing: 8
                        Text { text: "💾"; font.pixelSize: 16 }
                        Text {
                            text: (stateManager ? stateManager.strings.microsd : "Tarjeta MicroSD") + " (" + (stateManager ? stateManager.sdCardTotal : "119 GB") + ")"
                            font.pixelSize: 14
                            font.bold: true
                            color: "#FFFFFF"
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: (stateManager ? stateManager.sdCardUsed : "0 GB") + " usado de " + (stateManager ? stateManager.sdCardTotal : "119 GB") + " (" + Math.round(stateManager ? stateManager.sdCardPercent : 0) + "%)"
                        font.pixelSize: 12
                        color: "#CBA158"
                    }
                }

                // Storage progress bar
                Rectangle {
                    Layout.fillWidth: true
                    height: 8
                    radius: 4
                    color: "#28282E"

                    Rectangle {
                        width: Math.max(6, parent.width * ((stateManager ? stateManager.sdCardPercent : 0) / 100.0))
                        height: parent.height
                        radius: 4
                        color: "#CBA158"
                    }
                }
            }
        }

        // USB Mass Storage Transfer Mode Control Card
        Rectangle {
            Layout.fillWidth: true
            height: transferCol.height + 36
            radius: 12
            color: (stateManager && stateManager.transferModeActive) ? "#262319" : "#1A1A1D"
            border.color: (stateManager && stateManager.transferModeActive) ? "#CBA158" : "#2C2C32"
            border.width: 1

            ColumnLayout {
                id: transferCol
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 18
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 14

                    ColumnLayout {
                        spacing: 4
                        Layout.fillWidth: true

                        Text {
                            text: (stateManager && stateManager.transferModeActive) 
                                  ? "🟢 Modo Transferencia USB Activo" 
                                  : "📁 Modo Transferencia de Grabaciones (Almacenamiento Masivo)"
                            font.pixelSize: 15
                            font.bold: true
                            color: (stateManager && stateManager.transferModeActive) ? "#CBA158" : "#FFFFFF"
                        }

                        Text {
                            text: (stateManager && stateManager.transferModeActive)
                                  ? "La MicroSD está montada en tu sistema. Puedes copiar tus episodios desde tu gestor de archivos (Dolphin, Nautilus, etc.)."
                                  : "Al activar este modo, la consola comparte la tarjeta MicroSD por USB como pendrive para transferir podcasts a tu PC."
                            font.pixelSize: 12
                            color: "#9A9A9E"
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }

                    // Toggle Button
                    Rectangle {
                        width: 170
                        height: 38
                        radius: 8
                        color: (stateManager && stateManager.transferModeActive) ? "#CBA158" : "#28282E"
                        border.color: "#3E3E46"
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: (stateManager && stateManager.transferModeActive) ? "Salir de Transferencia" : "Activar Transferencia"
                            font.pixelSize: 12
                            font.bold: true
                            color: (stateManager && stateManager.transferModeActive) ? "#121214" : "#FFFFFF"
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (stateManager) {
                                    if (stateManager.transferModeActive) {
                                        stateManager.exitTransferMode();
                                    } else {
                                        stateManager.enterTransferMode();
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Recordings List
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            Text {
                text: "Grabaciones en Tarjeta"
                font.pixelSize: 15
                font.bold: true
                color: "#FFFFFF"
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 12
                color: "#1A1A1D"
                border.color: "#2C2C32"
                border.width: 1

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 10

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "🎙️"
                        font.pixelSize: 36
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: stateManager && stateManager.language === "es" 
                              ? "No hay tomas grabadas recientemente en la tarjeta"
                              : "No recent recorded takes found on card"
                        font.pixelSize: 14
                        color: "#8E8E93"
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: stateManager && stateManager.language === "es"
                              ? "Pulsa el botón REC arriba para iniciar una nueva grabación en la Duo"
                              : "Press REC above to start a new take on the Duo"
                        font.pixelSize: 12
                        color: "#666666"
                    }
                }
            }
        }
    }
}
