import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: root

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 36
        spacing: 24

        // Section Title & Subtitle
        ColumnLayout {
            spacing: 6

            Text {
                text: stateManager ? stateManager.modelName : "RØDECaster"
                font.pixelSize: 26
                font.bold: true
                color: "#FFFFFF"
            }

            Text {
                text: stateManager && stateManager.language === "es" 
                      ? "Selecciona una opción para gestionar tu consola" 
                      : "Select an option to manage your console"
                font.pixelSize: 14
                color: "#8E8E93"
            }
        }

        // Feature Cards Grid
        GridLayout {
            Layout.fillWidth: true
            columns: (stateManager && stateManager.isStreamerX) ? 2 : (root.width > 900 ? 3 : 2)
            rowSpacing: 20
            columnSpacing: 20

            // 1. Audio Setup
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 185
                Layout.minimumHeight: 170
                Layout.maximumHeight: 210
                radius: 14
                color: card1Area.containsMouse ? "#26262B" : "#1C1C1F"
                border.color: card1Area.containsMouse ? "#CBA158" : "#2E2E33"
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 12

                    // Top Row: Icon Badge & Arrow
                    RowLayout {
                        Layout.fillWidth: true

                        Rectangle {
                            width: 50
                            height: 50
                            radius: 12
                            color: "#2C2C32"
                            border.color: "#3E3E46"
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "🎚️"
                                font.pixelSize: 24
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: "›"
                            font.pixelSize: 24
                            font.bold: true
                            color: card1Area.containsMouse ? "#CBA158" : "#666666"
                        }
                    }

                    // Texts section
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 4

                        Text {
                            text: stateManager ? stateManager.strings.hub_audio_setup : "Configuración de Audio"
                            font.pixelSize: 16
                            font.bold: true
                            color: "#FFFFFF"
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        Text {
                            text: stateManager ? stateManager.strings.hub_audio_setup_desc : "Faders, canales, enrutamiento y vúmetros en vivo"
                            font.pixelSize: 12
                            color: "#9A9A9E"
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        Item { Layout.fillHeight: true }
                    }
                }

                MouseArea {
                    id: card1Area
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (stateManager) stateManager.navigateTo("audio_setup");
                    }
                }
            }

            // 2. Audio Processing (APHEX, Dynamics, EQ)
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 185
                Layout.minimumHeight: 170
                Layout.maximumHeight: 210
                radius: 14
                color: cardProcArea.containsMouse ? "#26262B" : "#1C1C1F"
                border.color: cardProcArea.containsMouse ? "#CBA158" : "#2E2E33"
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 12

                    // Top Row: Icon Badge & Arrow
                    RowLayout {
                        Layout.fillWidth: true

                        Rectangle {
                            width: 50
                            height: 50
                            radius: 12
                            color: "#2C2C32"
                            border.color: "#3E3E46"
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "✨"
                                font.pixelSize: 24
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: "›"
                            font.pixelSize: 24
                            font.bold: true
                            color: cardProcArea.containsMouse ? "#CBA158" : "#666666"
                        }
                    }

                    // Texts section
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 4

                        Text {
                            text: stateManager ? stateManager.strings.hub_audio_processing : "Procesamiento de Audio"
                            font.pixelSize: 16
                            font.bold: true
                            color: "#FFFFFF"
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        Text {
                            text: stateManager ? stateManager.strings.hub_audio_processing_desc : "Efectos APHEX®, Puerta de Ruido, Compresor, HPF, De-Esser y EQ"
                            font.pixelSize: 12
                            color: "#9A9A9E"
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        Item { Layout.fillHeight: true }
                    }
                }

                MouseArea {
                    id: cardProcArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (stateManager) stateManager.openAudioProcessing();
                    }
                }
            }

            // 2. Device Configuration
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 185
                Layout.minimumHeight: 170
                Layout.maximumHeight: 210
                radius: 14
                color: card2Area.containsMouse ? "#26262B" : "#1C1C1F"
                border.color: card2Area.containsMouse ? "#CBA158" : "#2E2E33"
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 12

                    // Top Row: Icon Badge & Arrow
                    RowLayout {
                        Layout.fillWidth: true

                        Rectangle {
                            width: 50
                            height: 50
                            radius: 12
                            color: "#2C2C32"
                            border.color: "#3E3E46"
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "⚙️"
                                font.pixelSize: 24
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: "›"
                            font.pixelSize: 24
                            font.bold: true
                            color: card2Area.containsMouse ? "#CBA158" : "#666666"
                        }
                    }

                    // Texts section
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 4

                        Text {
                            text: stateManager ? stateManager.strings.hub_device_config : "Configuración del Dispositivo"
                            font.pixelSize: 16
                            font.bold: true
                            color: "#FFFFFF"
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        Text {
                            text: stateManager ? stateManager.strings.hub_device_config_desc : "Salidas, pantalla, brillo, vúmetros y sistema"
                            font.pixelSize: 12
                            color: "#9A9A9E"
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        Item { Layout.fillHeight: true }
                    }
                }

                MouseArea {
                    id: card2Area
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (stateManager) stateManager.navigateTo("device_config");
                    }
                }
            }

            // 3. Customize SMART Pads
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 185
                Layout.minimumHeight: 170
                Layout.maximumHeight: 210
                radius: 14
                color: card3Area.containsMouse ? "#26262B" : "#1C1C1F"
                border.color: card3Area.containsMouse ? "#CBA158" : "#2E2E33"
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 12

                    // Top Row: Mini Pad Preview Badge & Arrow
                    RowLayout {
                        Layout.fillWidth: true

                        Rectangle {
                            width: 50
                            height: 50
                            radius: 12
                            color: "#2C2C32"
                            border.color: "#3E3E46"
                            border.width: 1

                            Grid {
                                anchors.centerIn: parent
                                columns: (stateManager && stateManager.isStreamerX) ? 2 : (stateManager && stateManager.isDuo ? 3 : 4)
                                spacing: 3

                                Repeater {
                                    model: stateManager ? stateManager.padsPerBank : 6
                                    Rectangle {
                                        width: 10
                                        height: 10
                                        radius: 2
                                        color: ["#FF3C3C", "#FF8C28", "#FFDC28", "#28C850", "#3C96FF", "#A050E6", "#E650B4", "#28C8DC"][index % 8]
                                    }
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: "›"
                            font.pixelSize: 24
                            font.bold: true
                            color: card3Area.containsMouse ? "#CBA158" : "#666666"
                        }
                    }

                    // Texts section
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 4

                        Text {
                            text: stateManager ? stateManager.strings.hub_smart_pads : "Personalizar SMART Pads"
                            font.pixelSize: 16
                            font.bold: true
                            color: "#FFFFFF"
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        Text {
                            text: stateManager ? stateManager.strings.hub_smart_pads_desc : "Sonidos, efectos de voz, censura y comandos MIDI"
                            font.pixelSize: 12
                            color: "#9A9A9E"
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        Item { Layout.fillHeight: true }
                    }
                }

                MouseArea {
                    id: card3Area
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (stateManager) stateManager.navigateTo("smartpads");
                    }
                }
            }

            // 4. Transfer Recordings (Only for Duo/Pro II with SD card support)
            Rectangle {
                visible: !(stateManager && stateManager.isStreamerX)
                Layout.fillWidth: true
                Layout.preferredHeight: 185
                Layout.minimumHeight: 170
                Layout.maximumHeight: 210
                radius: 14
                color: card4Area.containsMouse ? "#26262B" : "#1C1C1F"
                border.color: card4Area.containsMouse ? "#CBA158" : "#2E2E33"
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 12

                    // Top Row: Icon Badge & Arrow
                    RowLayout {
                        Layout.fillWidth: true

                        Rectangle {
                            width: 50
                            height: 50
                            radius: 12
                            color: "#2C2C32"
                            border.color: "#3E3E46"
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "🎙️"
                                font.pixelSize: 24
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: "›"
                            font.pixelSize: 24
                            font.bold: true
                            color: card4Area.containsMouse ? "#CBA158" : "#666666"
                        }
                    }

                    // Texts section
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 4

                        Text {
                            text: stateManager ? stateManager.strings.hub_recordings : "Transferir Grabaciones"
                            font.pixelSize: 16
                            font.bold: true
                            color: "#FFFFFF"
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        Text {
                            text: stateManager ? stateManager.strings.hub_recordings_desc : "Gestiona podcasts y tomas grabadas en la MicroSD"
                            font.pixelSize: 12
                            color: "#9A9A9E"
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        Item { Layout.fillHeight: true }
                    }
                }

                MouseArea {
                    id: card4Area
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (stateManager) {
                            stateManager.navigateTo("recordings");
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}

