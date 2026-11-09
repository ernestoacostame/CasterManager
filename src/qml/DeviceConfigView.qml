import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: root
    objectName: "deviceConfigView"

    property int activeTab: 0 // 0: Output, 1: Display, 2: System

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 28
        spacing: 20

        // Header Title Row & Tab Bar
        RowLayout {
            Layout.fillWidth: true
            spacing: 20

            Text {
                text: stateManager ? stateManager.strings.hub_device_config : "Configuración del Dispositivo"
                font.pixelSize: 22
                font.bold: true
                color: "#FFFFFF"
            }

            Item { Layout.fillWidth: true }

            // Tab Bar
            Rectangle {
                height: 38
                width: tabRow.width + 12
                radius: 8
                color: "#1C1C1F"
                border.color: "#2C2C32"
                border.width: 1

                Row {
                    id: tabRow
                    anchors.centerIn: parent
                    spacing: 4

                    // Tab 0: Output
                    Rectangle {
                        width: 90
                        height: 30
                        radius: 6
                        color: root.activeTab === 0 ? "#CBA158" : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: stateManager ? stateManager.strings.tab_output : "Salida"
                            font.pixelSize: 12
                            font.bold: true
                            color: root.activeTab === 0 ? "#121214" : "#AAAAAA"
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.activeTab = 0
                        }
                    }

                    // Tab 1: Display
                    Rectangle {
                        width: 90
                        height: 30
                        radius: 6
                        color: root.activeTab === 1 ? "#CBA158" : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: stateManager ? stateManager.strings.tab_display : "Pantalla"
                            font.pixelSize: 12
                            font.bold: true
                            color: root.activeTab === 1 ? "#121214" : "#AAAAAA"
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.activeTab = 1
                        }
                    }

                    // Tab 2: System
                    Rectangle {
                        width: 90
                        height: 30
                        radius: 6
                        color: root.activeTab === 2 ? "#CBA158" : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: stateManager ? stateManager.strings.tab_system : "Sistema"
                            font.pixelSize: 12
                            font.bold: true
                            color: root.activeTab === 2 ? "#121214" : "#AAAAAA"
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.activeTab = 2
                        }
                    }
                }
            }
        }

        // Tab Content Area with Flickable Scroll
        ScrollView {
            id: configScroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: availableWidth
            clip: true
            ScrollBar.vertical.policy: ScrollBar.AsNeeded

            Item {
                id: scrollContent
                width: configScroll.availableWidth
                implicitHeight: {
                    if (root.activeTab === 0) return tab0Col.implicitHeight + 40;
                    if (root.activeTab === 1) return tab1Col.implicitHeight + 40;
                    return tab2Col.implicitHeight + 40;
                }

                // TAB 0: OUTPUT
                ColumnLayout {
                    id: tab0Col
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: 20
                    visible: root.activeTab === 0

                    // 1. Streamer X UNIFY Multitrack Architecture Card (Prominently at the top when Streamer X is connected)
                    Rectangle {
                        visible: Boolean(stateManager && stateManager.isStreamerX)
                        Layout.fillWidth: true
                        height: unifyCol.height + 40
                        radius: 14
                        color: (stateManager && stateManager.streamerXUnifyInstalled) ? "#151B17" : "#1B1B20"
                        border.color: (stateManager && stateManager.streamerXUnifyInstalled) ? "#28C850" : "#CBA158"
                        border.width: (stateManager && stateManager.streamerXUnifyInstalled) ? 1.5 : 1

                        ColumnLayout {
                            id: unifyCol
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 20
                            spacing: 16

                            // Header with icon badge, title, status and action button
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 16

                                // Unify Icon Badge
                                Rectangle {
                                    width: 48
                                    height: 48
                                    radius: 10
                                    color: (stateManager && stateManager.streamerXUnifyInstalled) ? "#1A3824" : "#2A2318"
                                    border.color: (stateManager && stateManager.streamerXUnifyInstalled) ? "#28C850" : "#CBA158"
                                    border.width: 1.5

                                    Text {
                                        anchors.centerIn: parent
                                        text: "🎛️"
                                        font.pixelSize: 24
                                    }
                                }

                                ColumnLayout {
                                    spacing: 4
                                    Layout.fillWidth: true

                                    RowLayout {
                                        spacing: 10
                                        Text {
                                            text: "Arquitectura Multipista PipeWire (UNIFY para Linux)"
                                            font.pixelSize: 16
                                            font.bold: true
                                            color: "#FFFFFF"
                                        }
                                        Rectangle {
                                            width: 76
                                            height: 20
                                            radius: 10
                                            color: (stateManager && stateManager.streamerXUnifyInstalled) ? "#163820" : "#2C2C34"
                                            border.color: (stateManager && stateManager.streamerXUnifyInstalled) ? "#28C850" : "#4A4A56"
                                            border.width: 1
                                            Text {
                                                anchors.centerIn: parent
                                                text: (stateManager && stateManager.streamerXUnifyInstalled) ? "● ACTIVO" : "○ INACTIVO"
                                                font.pixelSize: 9
                                                font.bold: true
                                                color: (stateManager && stateManager.streamerXUnifyInstalled) ? "#28C850" : "#9A9A9E"
                                            }
                                        }
                                    }

                                    Text {
                                        text: "Crea dispositivos de audio virtuales nativos independientes en PipeWire con enrutamiento automático de baja latencia hacia los auriculares del Streamer X y OBS Studio."
                                        font.pixelSize: 11
                                        color: "#9A9A9E"
                                        Layout.preferredWidth: root.width - 320
                                        wrapMode: Text.WordWrap
                                    }
                                }

                                Button {
                                    text: (stateManager && stateManager.streamerXUnifyInstalled) ? "Desactivar UNIFY" : "Activar UNIFY en Linux"
                                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                                    contentItem: Text {
                                        text: parent.text
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: "#FFFFFF"
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    background: Rectangle {
                                        implicitWidth: 170
                                        implicitHeight: 38
                                        radius: 8
                                        color: (stateManager && stateManager.streamerXUnifyInstalled) ? "#8A2A2A" : "#24733F"
                                        border.color: (stateManager && stateManager.streamerXUnifyInstalled) ? "#C93B3B" : "#32A056"
                                        border.width: 1
                                    }
                                    onClicked: {
                                        if (stateManager) stateManager.toggleStreamerXUnifyProfile();
                                    }
                                }
                            }

                            // Grid of Virtual Channels Cards
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                Repeater {
                                    model: [
                                        {"icon": "🎮", "name": "Game", "desc": "Juegos (Steam, etc.)", "color": "#3C96FF"},
                                        {"icon": "💬", "name": "Chat", "desc": "Discord / Teams / Meet", "color": "#28C850"},
                                        {"icon": "🎵", "name": "Music", "desc": "Spotify / Navegador", "color": "#FF9600"},
                                        {"icon": "🔔", "name": "System", "desc": "Alertas y SO", "color": "#A050E6"},
                                        {"icon": "🎙️", "name": "Stream Mix", "desc": "Salida OBS Broadcast", "color": "#FF3C3C"}
                                    ]

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 58
                                        radius: 8
                                        color: "#212128"
                                        border.color: (stateManager && stateManager.streamerXUnifyInstalled) ? modelData.color : "#2F2F38"
                                        border.width: (stateManager && stateManager.streamerXUnifyInstalled) ? 1.5 : 1

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: 10
                                            spacing: 10

                                            Text { text: modelData.icon; font.pixelSize: 18 }
                                            ColumnLayout {
                                                spacing: 2
                                                Layout.fillWidth: true
                                                Text {
                                                    text: modelData.name
                                                    font.pixelSize: 12
                                                    font.bold: true
                                                    color: (stateManager && stateManager.streamerXUnifyInstalled) ? modelData.color : "#FFFFFF"
                                                }
                                                Text {
                                                    text: modelData.desc
                                                    font.pixelSize: 10
                                                    color: "#8E8E93"
                                                    elide: Text.ElideRight
                                                    Layout.fillWidth: true
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Bottom Info Tip
                            Rectangle {
                                Layout.fillWidth: true
                                height: 34
                                radius: 6
                                color: "#18181E"
                                border.color: "#282834"
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    spacing: 8

                                    Text { text: "💡"; font.pixelSize: 12 }
                                    Text {
                                        text: "Al activar esta opción, en OBS Studio o tu DAW podrás capturar cada canal por separado en pistas 1 a 6 para mezclar y editar audio multicanal."
                                        font.pixelSize: 11
                                        color: "#CBA158"
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }
                            }
                        }
                    }

                    // 2. Headphones Card
                    Rectangle {
                        Layout.fillWidth: true
                        height: hpCol.height + 36
                        radius: 12
                        color: "#1A1A1D"
                        border.color: "#2C2C32"
                        border.width: 1

                        ColumnLayout {
                            id: hpCol
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 18
                        spacing: 14

                        Text {
                            text: "🎧 " + (stateManager ? stateManager.strings.headphones : "Auriculares")
                            font.pixelSize: 15
                            font.bold: true
                            color: "#FFFFFF"
                        }

                        // Headphone 1
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 14

                            Text {
                                text: "Headphone 1"
                                font.pixelSize: 13
                                color: "#E0E0E0"
                                Layout.preferredWidth: 120
                            }

                            Row {
                                spacing: 8
                                Repeater {
                                    model: ["RØDE NTH-100", "High Sensitivity", "Low Sensitivity"]
                                    Rectangle {
                                        width: 130
                                        height: 32
                                        radius: 6
                                        color: (stateManager && stateManager.headphone1Type === index) ? "#CBA158" : "#28282E"
                                        border.color: "#3A3A42"
                                        border.width: 1

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData
                                            font.pixelSize: 11
                                            font.bold: stateManager && stateManager.headphone1Type === index
                                            color: (stateManager && stateManager.headphone1Type === index) ? "#121214" : "#D0D0D0"
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (stateManager) stateManager.setHeadphone1Type(index);
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Headphone 2
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 14

                            Text {
                                text: "Headphone 2"
                                font.pixelSize: 13
                                color: "#E0E0E0"
                                Layout.preferredWidth: 120
                            }

                            Row {
                                spacing: 8
                                Repeater {
                                    model: ["RØDE NTH-100", "High Sensitivity", "Low Sensitivity"]
                                    Rectangle {
                                        width: 130
                                        height: 32
                                        radius: 6
                                        color: (stateManager && stateManager.headphone2Type === index) ? "#CBA158" : "#28282E"
                                        border.color: "#3A3A42"
                                        border.width: 1

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData
                                            font.pixelSize: 11
                                            font.bold: stateManager && stateManager.headphone2Type === index
                                            color: (stateManager && stateManager.headphone2Type === index) ? "#121214" : "#D0D0D0"
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (stateManager) stateManager.setHeadphone2Type(index);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // 2. Monitor & Routing Options Card
                Rectangle {
                    Layout.fillWidth: true
                    height: monCol.height + 36
                    radius: 12
                    color: "#1A1A1D"
                    border.color: "#2C2C32"
                    border.width: 1

                    ColumnLayout {
                        id: monCol
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 18
                        spacing: 16

                        Text {
                            text: "🔊 " + (stateManager ? stateManager.strings.monitor : "Monitores") + " & " + (stateManager ? stateManager.strings.routing : "Enrutamiento")
                            font.pixelSize: 15
                            font.bold: true
                            color: "#FFFFFF"
                        }

                        // Auto-mute Monitor Output
                        RowLayout {
                            Layout.fillWidth: true
                            ColumnLayout {
                                spacing: 2
                                Text {
                                    text: stateManager ? stateManager.strings.auto_mute_output : "Silenciar monitores al subir micrófono"
                                    font.pixelSize: 13
                                    color: "#E0E0E0"
                                }
                                Text {
                                    text: "Evita retroalimentación acústica al hablar por los micrófonos"
                                    font.pixelSize: 11
                                    color: "#8E8E93"
                                }
                            }
                            Item { Layout.fillWidth: true }
                            Switch {
                                checked: stateManager ? stateManager.monitorAutoMute : true
                                onToggled: {
                                    if (stateManager) stateManager.setMonitorAutoMute(checked);
                                }
                            }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: "#28282E" }

                        // Auto-mute Bluetooth
                        RowLayout {
                            Layout.fillWidth: true
                            ColumnLayout {
                                spacing: 2
                                Text {
                                    text: stateManager ? stateManager.strings.auto_mute_bt : "Silenciar Bluetooth al subir micrófono"
                                    font.pixelSize: 13
                                    color: "#E0E0E0"
                                }
                                Text {
                                    text: "Atenúa la salida bluetooth mientras hablas"
                                    font.pixelSize: 11
                                    color: "#8E8E93"
                                }
                            }
                            Item { Layout.fillWidth: true }
                            Switch {
                                checked: stateManager ? stateManager.btAutoMute : false
                                onToggled: {
                                    if (stateManager) stateManager.setBtAutoMute(checked);
                                }
                            }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: "#28282E" }

                        // Listen PFL vs AFL
                        RowLayout {
                            Layout.fillWidth: true
                            ColumnLayout {
                                spacing: 2
                                Text {
                                    text: stateManager ? stateManager.strings.listen : "Escucha (Solo)"
                                    font.pixelSize: 13
                                    color: "#E0E0E0"
                                }
                                Text {
                                    text: "Pre-fader (PFL) o After-fader (AFL) para los botones Listen"
                                    font.pixelSize: 11
                                    color: "#8E8E93"
                                }
                            }
                            Item { Layout.fillWidth: true }
                            Row {
                                spacing: 8
                                Rectangle {
                                    width: 100
                                    height: 32
                                    radius: 6
                                    color: (stateManager && !stateManager.listenPrefader) ? "#CBA158" : "#28282E"
                                    Text {
                                        anchors.centerIn: parent
                                        text: "After-Fader"
                                        font.pixelSize: 11
                                        font.bold: stateManager && !stateManager.listenPrefader
                                        color: (stateManager && !stateManager.listenPrefader) ? "#121214" : "#D0D0D0"
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: if (stateManager) stateManager.setListenPrefader(false);
                                    }
                                }
                                Rectangle {
                                    width: 100
                                    height: 32
                                    radius: 6
                                    color: (stateManager && stateManager.listenPrefader) ? "#CBA158" : "#28282E"
                                    Text {
                                        anchors.centerIn: parent
                                        text: "Pre-Fader"
                                        font.pixelSize: 11
                                        font.bold: stateManager && stateManager.listenPrefader
                                        color: (stateManager && stateManager.listenPrefader) ? "#121214" : "#D0D0D0"
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: if (stateManager) stateManager.setListenPrefader(true);
                                    }
                                }
                            }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: "#28282E" }

                        // Multitrack Recording Mode (Duo / Pro II)
                        RowLayout {
                            visible: Boolean(stateManager && !stateManager.isStreamerX)
                            Layout.fillWidth: true
                            ColumnLayout {
                                spacing: 2
                                Text {
                                    text: stateManager ? stateManager.strings.multitrack : "Grabación Multipista"
                                    font.pixelSize: 13
                                    color: "#E0E0E0"
                                }
                                Text {
                                    text: "Graba canales individuales independientes en la tarjeta MicroSD"
                                    font.pixelSize: 11
                                    color: "#8E8E93"
                                }
                            }
                            Item { Layout.fillWidth: true }
                            Row {
                                spacing: 8
                                Repeater {
                                    model: ["Stereo Only", "Post-Fader", "Pre-Fader (Bypass)"]
                                    Rectangle {
                                        width: 120
                                        height: 32
                                        radius: 6
                                        color: (stateManager && stateManager.multitrackMode === index) ? "#CBA158" : "#28282E"
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData
                                            font.pixelSize: 11
                                            font.bold: stateManager && stateManager.multitrackMode === index
                                            color: (stateManager && stateManager.multitrackMode === index) ? "#121214" : "#D0D0D0"
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: if (stateManager) stateManager.setMultitrackMode(index);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // TAB 1: DISPLAY & BRIGHTNESS
            ColumnLayout {
                width: root.width - 56
                spacing: 18
                visible: root.activeTab === 1

                // Brightness & Dimming Card
                Rectangle {
                    Layout.fillWidth: true
                    height: dispCol.height + 36
                    radius: 12
                    color: "#1A1A1D"
                    border.color: "#2C2C32"
                    border.width: 1

                    ColumnLayout {
                        id: dispCol
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 18
                        spacing: 16

                        Text {
                            text: "☀️ " + (stateManager ? stateManager.strings.brightness : "Brillo y Pantalla")
                            font.pixelSize: 15
                            font.bold: true
                            color: "#FFFFFF"
                        }

                        // Screen Brightness Slider
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 14
                            Text {
                                text: stateManager ? stateManager.strings.display_brightness : "Pantalla"
                                font.pixelSize: 13
                                color: "#E0E0E0"
                                Layout.preferredWidth: 100
                            }
                            Slider {
                                Layout.fillWidth: true
                                from: 20
                                to: 255
                                value: stateManager ? stateManager.screenBrightness : 250
                                onMoved: {
                                    if (stateManager) stateManager.setScreenBrightness(Math.round(value));
                                }
                            }
                            Text {
                                text: Math.round(((stateManager ? stateManager.screenBrightness : 250) / 255.0) * 100) + "%"
                                font.pixelSize: 12
                                color: "#CBA158"
                                Layout.preferredWidth: 45
                            }
                        }

                        // Buttons Brightness Slider
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 14
                            Text {
                                text: stateManager ? stateManager.strings.buttons_brightness : "Botones"
                                font.pixelSize: 13
                                color: "#E0E0E0"
                                Layout.preferredWidth: 100
                            }
                            Slider {
                                Layout.fillWidth: true
                                from: 20
                                to: 255
                                value: stateManager ? stateManager.buttonBrightness : 255
                                onMoved: {
                                    if (stateManager) stateManager.setButtonBrightness(Math.round(value));
                                }
                            }
                            Text {
                                text: Math.round(((stateManager ? stateManager.buttonBrightness : 255) / 255.0) * 100) + "%"
                                font.pixelSize: 12
                                color: "#CBA158"
                                Layout.preferredWidth: 45
                            }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: "#28282E" }

                        // Auto Brightness
                        RowLayout {
                            Layout.fillWidth: true
                            ColumnLayout {
                                spacing: 2
                                Text {
                                    text: stateManager ? stateManager.strings.auto_brightness : "Brillo Automático"
                                    font.pixelSize: 13
                                    color: "#E0E0E0"
                                }
                                Text {
                                    text: "Ajustar el sensor de luz ambiental automáticamente"
                                    font.pixelSize: 11
                                    color: "#8E8E93"
                                }
                            }
                            Item { Layout.fillWidth: true }
                            Switch {
                                checked: stateManager ? stateManager.autoBrightness : false
                                onToggled: {
                                    if (stateManager) stateManager.setAutoBrightness(checked);
                                }
                            }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: "#28282E" }

                        // Metering Cards (Default vs Broadcast)
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            Text {
                                text: stateManager ? stateManager.strings.metering : "Vúmetros (Metering)"
                                font.pixelSize: 13
                                font.bold: true
                                color: "#E0E0E0"
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 16

                                // Card 1: Default
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 130
                                    radius: 10
                                    color: (stateManager && !stateManager.broadcastMeters) ? "#25252D" : "#1F1F23"
                                    border.color: (stateManager && !stateManager.broadcastMeters) ? "#CBA158" : "#2E2E36"
                                    border.width: (stateManager && !stateManager.broadcastMeters) ? 2 : 1

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 14
                                        spacing: 8

                                        RowLayout {
                                            Text {
                                                text: "Default"
                                                font.pixelSize: 14
                                                font.bold: true
                                                color: (stateManager && !stateManager.broadcastMeters) ? "#CBA158" : "#FFFFFF"
                                            }
                                            Item { Layout.fillWidth: true }
                                            Text {
                                                visible: Boolean(stateManager && !stateManager.broadcastMeters)
                                                text: "✓ Activo"
                                                font.pixelSize: 11
                                                font.bold: true
                                                color: "#34C759"
                                            }
                                        }

                                        Text {
                                            text: "Los vúmetros incluyen marcadores a intervalos regulares e indican el nivel de ganancia unitario estándar."
                                            font.pixelSize: 11
                                            color: "#9A9A9E"
                                            wrapMode: Text.WordWrap
                                            Layout.fillWidth: true
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: if (stateManager) stateManager.setBroadcastMeters(false);
                                    }
                                }

                                // Card 2: Broadcast
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 130
                                    radius: 10
                                    color: (stateManager && stateManager.broadcastMeters) ? "#25252D" : "#1F1F23"
                                    border.color: (stateManager && stateManager.broadcastMeters) ? "#CBA158" : "#2E2E36"
                                    border.width: (stateManager && stateManager.broadcastMeters) ? 2 : 1

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 14
                                        spacing: 8

                                        RowLayout {
                                            Text {
                                                text: "Broadcast"
                                                font.pixelSize: 14
                                                font.bold: true
                                                color: (stateManager && stateManager.broadcastMeters) ? "#CBA158" : "#FFFFFF"
                                            }
                                            Item { Layout.fillWidth: true }
                                            Text {
                                                visible: Boolean(stateManager && stateManager.broadcastMeters)
                                                text: "✓ Activo"
                                                font.pixelSize: 11
                                                font.bold: true
                                                color: "#34C759"
                                            }
                                        }

                                        Text {
                                            text: "Los vúmetros incluyen marcadores precisos de escala dBFS en cada canal y medidores de reducción de ganancia (compresor)."
                                            font.pixelSize: 11
                                            color: "#9A9A9E"
                                            wrapMode: Text.WordWrap
                                            Layout.fillWidth: true
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: if (stateManager) stateManager.setBroadcastMeters(true);
                                    }
                                }
                            }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: "#28282E" }

                        // Haptic Feedback
                        RowLayout {
                            Layout.fillWidth: true
                            ColumnLayout {
                                spacing: 2
                                Text {
                                    text: stateManager ? stateManager.strings.haptics : "Respuesta Háptica"
                                    font.pixelSize: 13
                                    color: "#E0E0E0"
                                }
                                Text {
                                    text: "Vibración al tocar los pads y controles táctiles"
                                    font.pixelSize: 11
                                    color: "#8E8E93"
                                }
                            }
                            Item { Layout.fillWidth: true }
                            Row {
                                spacing: 8
                                Repeater {
                                    model: ["Off", "Low", "Medium", "High"]
                                    Rectangle {
                                        width: 70
                                        height: 32
                                        radius: 6
                                        color: (stateManager && stateManager.hapticFeedback === index) ? "#CBA158" : "#28282E"
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData
                                            font.pixelSize: 11
                                            font.bold: stateManager && stateManager.hapticFeedback === index
                                            color: (stateManager && stateManager.hapticFeedback === index) ? "#121214" : "#D0D0D0"
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: if (stateManager) stateManager.setHapticFeedback(index);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // TAB 2: SYSTEM
            ColumnLayout {
                width: root.width - 56
                spacing: 18
                visible: root.activeTab === 2

                // System Info Card
                Rectangle {
                    Layout.fillWidth: true
                    height: sysCol.height + 36
                    radius: 12
                    color: "#1A1A1D"
                    border.color: "#2C2C32"
                    border.width: 1

                    ColumnLayout {
                        id: sysCol
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 18
                        spacing: 16

                        Text {
                            text: "ℹ️ " + (stateManager ? stateManager.strings.information : "Información del Sistema")
                            font.pixelSize: 15
                            font.bold: true
                            color: "#FFFFFF"
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Dispositivo"; font.pixelSize: 13; color: "#8E8E93"; Layout.preferredWidth: 150 }
                            Text { text: stateManager ? stateManager.modelName : "RØDECaster Duo"; font.pixelSize: 13; font.bold: true; color: "#FFFFFF" }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Firmware"; font.pixelSize: 13; color: "#8E8E93"; Layout.preferredWidth: 150 }
                            Text { text: "v" + (stateManager ? stateManager.firmwareVersion : "1.7.7"); font.pixelSize: 13; font.bold: true; color: "#FFFFFF" }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: stateManager ? stateManager.strings.serial_number : "Número de Serie"; font.pixelSize: 13; color: "#8E8E93"; Layout.preferredWidth: 150 }
                            Text { text: stateManager && stateManager.serialNumber ? stateManager.serialNumber : "N/A"; font.pixelSize: 13; font.bold: true; color: "#FFFFFF" }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: "#28282E" }

                        // USB MIDI Control Toggle
                        RowLayout {
                            Layout.fillWidth: true
                            ColumnLayout {
                                spacing: 2
                                Text {
                                    text: stateManager ? stateManager.strings.midi_control : "Control MIDI"
                                    font.pixelSize: 13
                                    color: "#E0E0E0"
                                }
                                Text {
                                    text: stateManager ? stateManager.strings.midi_control_desc : "Permitir comunicación MIDI bidireccional por USB"
                                    font.pixelSize: 11
                                    color: "#8E8E93"
                                }
                            }
                            Item { Layout.fillWidth: true }
                            Switch {
                                checked: stateManager ? stateManager.midiControl : false
                                onToggled: {
                                    if (stateManager) stateManager.setMidiControl(checked);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
}

