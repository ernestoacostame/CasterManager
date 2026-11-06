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

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Grabaciones en Tarjeta"
                    font.pixelSize: 15
                    font.bold: true
                    color: "#FFFFFF"
                }
                Item { Layout.fillWidth: true }
                Text {
                    visible: Boolean(stateManager && stateManager.recordings && stateManager.recordings.length > 0)
                    text: (stateManager && stateManager.recordings) ? (stateManager.recordings.length + " tomas encontradas") : ""
                    font.pixelSize: 12
                    color: "#CBA158"
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 12
                color: "#1A1A1D"
                border.color: "#2C2C32"
                border.width: 1
                clip: true

                // When recordings are found
                ScrollView {
                    anchors.fill: parent
                    anchors.margins: 14
                    visible: Boolean(stateManager && stateManager.recordings && stateManager.recordings.length > 0)

                    ColumnLayout {
                        width: parent.width - 24
                        spacing: 10

                        Repeater {
                            model: stateManager ? stateManager.recordings : []

                            Rectangle {
                                Layout.fillWidth: true
                                height: 72
                                radius: 8
                                color: takeArea.containsMouse ? "#24242A" : "#202024"
                                border.color: takeArea.containsMouse ? "#CBA158" : "#2C2C32"
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 14
                                    spacing: 14

                                    Text {
                                        text: "🎙️"
                                        font.pixelSize: 22
                                    }

                                    ColumnLayout {
                                        spacing: 3
                                        Layout.fillWidth: true

                                        Text {
                                            text: modelData.name || modelData.folder
                                            font.pixelSize: 14
                                            font.bold: true
                                            color: "#FFFFFF"
                                        }

                                        Row {
                                            spacing: 10
                                            Text {
                                                text: "📅 " + (modelData.date || "")
                                                font.pixelSize: 11
                                                color: "#8E8E93"
                                            }
                                            Text {
                                                text: "⏱️ " + (modelData.duration || "00:00")
                                                font.pixelSize: 11
                                                color: "#CBA158"
                                            }
                                            Text {
                                                text: "💾 " + (modelData.size || "")
                                                font.pixelSize: 11
                                                color: "#9A9A9E"
                                            }
                                        }
                                    }

                                    // Multitrack badge
                                    Rectangle {
                                        height: 24
                                        width: multiText.implicitWidth + 14
                                        radius: 4
                                        color: modelData.multitrack ? "#1E3A28" : "#26262C"
                                        border.color: modelData.multitrack ? "#34C759" : "#3E3E46"
                                        border.width: 1

                                        Text {
                                            id: multiText
                                            anchors.centerIn: parent
                                            text: modelData.multitrack ? "Multipista" : "Estéreo"
                                            font.pixelSize: 10
                                            font.bold: true
                                            color: modelData.multitrack ? "#34C759" : "#AAAAAA"
                                        }
                                    }

                                    // Open Folder Button
                                    Rectangle {
                                        width: 130
                                        height: 32
                                        radius: 6
                                        color: openArea.containsMouse ? "#CBA158" : "#2A2A32"
                                        border.color: openArea.containsMouse ? "#CBA158" : "#3E3E48"
                                        border.width: 1

                                        Row {
                                            anchors.centerIn: parent
                                            spacing: 6
                                            Text { text: "📁"; font.pixelSize: 12 }
                                            Text {
                                                text: "Abrir Carpeta"
                                                font.pixelSize: 11
                                                font.bold: true
                                                color: openArea.containsMouse ? "#121214" : "#FFFFFF"
                                            }
                                        }

                                        MouseArea {
                                            id: openArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (stateManager) stateManager.openRecordingFolder(modelData.path);
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    id: takeArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    propagateComposedEvents: true
                                }
                            }
                        }
                    }
                }

                // Empty state when no recordings or not mounted
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 12
                    visible: !stateManager || !stateManager.recordings || stateManager.recordings.length === 0

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "🎙️"
                        font.pixelSize: 38
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: (stateManager && stateManager.transferModeActive)
                              ? "No se encontraron tomas en la MicroSD"
                              : "Activa el Modo Transferencia para explorar los episodios grabados"
                        font.pixelSize: 14
                        font.bold: true
                        color: "#FFFFFF"
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: (stateManager && stateManager.transferModeActive)
                              ? "Las grabaciones realizadas con el botón REC aparecerán aquí"
                              : "Al activar la transferencia, la MicroSD se montará en Linux y CasterManager listará tus tomas"
                        font.pixelSize: 12
                        color: "#8E8E93"
                    }

                    Rectangle {
                        visible: !stateManager || !stateManager.transferModeActive
                        Layout.alignment: Qt.AlignHCenter
                        width: 180
                        height: 36
                        radius: 8
                        color: "#CBA158"

                        Text {
                            anchors.centerIn: parent
                            text: "Activar Transferencia"
                            font.pixelSize: 12
                            font.bold: true
                            color: "#121214"
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (stateManager) stateManager.enterTransferMode();
                            }
                        }
                    }
                }
            }
        }
    }
}
