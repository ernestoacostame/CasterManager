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

        // 2x2 Grid of Main Features
        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 2
            rowSpacing: 20
            columnSpacing: 20

            // 1. Audio Setup
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 14
                color: card1Area.containsMouse ? "#26262B" : "#1C1C1F"
                border.color: card1Area.containsMouse ? "#CBA158" : "#2E2E33"
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 20

                    // Icon badge
                    Rectangle {
                        width: 58
                        height: 58
                        radius: 12
                        color: "#2C2C32"
                        border.color: "#3E3E46"
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "🎚️"
                            font.pixelSize: 28
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            text: stateManager ? stateManager.strings.hub_audio_setup : "Configuración de Audio"
                            font.pixelSize: 18
                            font.bold: true
                            color: "#FFFFFF"
                        }

                        Text {
                            text: stateManager ? stateManager.strings.hub_audio_setup_desc : "Faders, canales, enrutamiento y vúmetros en vivo"
                            font.pixelSize: 13
                            color: "#9A9A9E"
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }

                    Text {
                        text: "›"
                        font.pixelSize: 26
                        font.bold: true
                        color: card1Area.containsMouse ? "#CBA158" : "#666666"
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

            // 2. Device Configuration
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 14
                color: card2Area.containsMouse ? "#26262B" : "#1C1C1F"
                border.color: card2Area.containsMouse ? "#CBA158" : "#2E2E33"
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 20

                    // Icon badge
                    Rectangle {
                        width: 58
                        height: 58
                        radius: 12
                        color: "#2C2C32"
                        border.color: "#3E3E46"
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "⚙️"
                            font.pixelSize: 28
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            text: stateManager ? stateManager.strings.hub_device_config : "Configuración del Dispositivo"
                            font.pixelSize: 18
                            font.bold: true
                            color: "#FFFFFF"
                        }

                        Text {
                            text: stateManager ? stateManager.strings.hub_device_config_desc : "Salidas, pantalla, brillo, vúmetros y sistema"
                            font.pixelSize: 13
                            color: "#9A9A9E"
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }

                    Text {
                        text: "›"
                        font.pixelSize: 26
                        font.bold: true
                        color: card2Area.containsMouse ? "#CBA158" : "#666666"
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
                Layout.fillHeight: true
                radius: 14
                color: card3Area.containsMouse ? "#26262B" : "#1C1C1F"
                border.color: card3Area.containsMouse ? "#CBA158" : "#2E2E33"
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 20

                    // Icon badge: mini pad preview
                    Rectangle {
                        width: 58
                        height: 58
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
                                    width: 11
                                    height: 11
                                    radius: 2
                                    color: ["#FF3C3C", "#FF8C28", "#FFDC28", "#28C850", "#3C96FF", "#A050E6", "#E650B4", "#28C8DC"][index % 8]
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            text: stateManager ? stateManager.strings.hub_smart_pads : "Personalizar SMART Pads"
                            font.pixelSize: 18
                            font.bold: true
                            color: "#FFFFFF"
                        }

                        Text {
                            text: stateManager ? stateManager.strings.hub_smart_pads_desc : "Sonidos, efectos de voz, censura y comandos MIDI"
                            font.pixelSize: 13
                            color: "#9A9A9E"
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }

                    Text {
                        text: "›"
                        font.pixelSize: 26
                        font.bold: true
                        color: card3Area.containsMouse ? "#CBA158" : "#666666"
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

            // 4. Transfer Recordings
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 14
                color: card4Area.containsMouse ? "#26262B" : "#1C1C1F"
                border.color: card4Area.containsMouse ? "#CBA158" : "#2E2E33"
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 20

                    // Icon badge
                    Rectangle {
                        width: 58
                        height: 58
                        radius: 12
                        color: "#2C2C32"
                        border.color: "#3E3E46"
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: (stateManager && stateManager.isStreamerX) ? "🎛️" : "🎙️"
                            font.pixelSize: 28
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            text: (stateManager && stateManager.isStreamerX)
                                  ? "Arquitectura Multipista UNIFY"
                                  : (stateManager ? stateManager.strings.hub_recordings : "Transferir Grabaciones")
                            font.pixelSize: 18
                            font.bold: true
                            color: "#FFFFFF"
                        }

                        Text {
                            text: (stateManager && stateManager.isStreamerX)
                                  ? "Enrutamiento PipeWire virtual para Game, Chat, Música y OBS"
                                  : (stateManager ? stateManager.strings.hub_recordings_desc : "Gestiona podcasts y tomas grabadas en la MicroSD")
                            font.pixelSize: 13
                            color: "#9A9A9E"
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }

                    Text {
                        text: "›"
                        font.pixelSize: 26
                        font.bold: true
                        color: card4Area.containsMouse ? "#CBA158" : "#666666"
                    }
                }

                MouseArea {
                    id: card4Area
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (stateManager) {
                            if (stateManager.isStreamerX) {
                                stateManager.navigateTo("config");
                            } else {
                                stateManager.navigateTo("recordings");
                            }
                        }
                    }
                }
            }
        }
    }
}

