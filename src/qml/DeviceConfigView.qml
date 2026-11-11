import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: root
    objectName: "deviceConfigView"

    property int activeTab: 0 // 0: Output, 1: Display, 2: System

    readonly property var hoursList: ["00","01","02","03","04","05","06","07","08","09","10","11","12","13","14","15","16","17","18","19","20","21","22","23"]
    readonly property var minutesList: ["00","01","02","03","04","05","06","07","08","09","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30","31","32","33","34","35","36","37","38","39","40","41","42","43","44","45","46","47","48","49","50","51","52","53","54","55","56","57","58","59"]

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

                    // Tab 0: Output / Audio & UNIFY
                    Rectangle {
                        width: (stateManager && stateManager.isStreamerX) ? 120 : 90
                        height: 30
                        radius: 6
                        color: root.activeTab === 0 ? "#CBA158" : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: (stateManager && stateManager.isStreamerX) ? (stateManager ? stateManager.strings.tab_audio_unify : "Audio & UNIFY") : (stateManager ? stateManager.strings.tab_output : "Salida")
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

                    // Tab 1: Display (Streamer X has no LCD: only the button lighting is shown)
                    Rectangle {
                        width: 90
                        height: 30
                        radius: 6
                        color: root.activeTab === 1 ? "#CBA158" : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: (stateManager && stateManager.isStreamerX) ? stateManager.strings.brightness : (stateManager ? stateManager.strings.tab_display : "Pantalla")
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
                        implicitHeight: visible ? (unifyCol.implicitHeight + 40) : 0
                        Layout.preferredHeight: implicitHeight
                        radius: 14
                        color: (stateManager && stateManager.streamerXUnifyInstalled) ? "#141F18" : "#191920"
                        border.color: (stateManager && stateManager.streamerXUnifyInstalled) ? "#28C850" : "#2E2E38"
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

                                // Unify Audio Graphic Badge
                                Rectangle {
                                    width: 46
                                    height: 46
                                    radius: 10
                                    color: (stateManager && stateManager.streamerXUnifyInstalled) ? "#1A3824" : "#22222A"
                                    border.color: (stateManager && stateManager.streamerXUnifyInstalled) ? "#28C850" : "#383844"
                                    border.width: 1

                                    // Stylized multi-channel audio wave graphic
                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 3
                                        Rectangle { width: 3; height: 14; radius: 1.5; color: "#3B82F6"; anchors.verticalCenter: parent.verticalCenter }
                                        Rectangle { width: 3; height: 22; radius: 1.5; color: "#10B981"; anchors.verticalCenter: parent.verticalCenter }
                                        Rectangle { width: 3; height: 18; radius: 1.5; color: "#F59E0B"; anchors.verticalCenter: parent.verticalCenter }
                                        Rectangle { width: 3; height: 26; radius: 1.5; color: "#8B5CF6"; anchors.verticalCenter: parent.verticalCenter }
                                        Rectangle { width: 3; height: 16; radius: 1.5; color: "#EF4444"; anchors.verticalCenter: parent.verticalCenter }
                                    }
                                }

                                ColumnLayout {
                                    spacing: 4
                                    Layout.fillWidth: true

                                    RowLayout {
                                        spacing: 10
                                        Text {
                                            text: stateManager ? stateManager.strings.unify_title : "RØDE UNIFY (PipeWire Linux)"
                                            font.pixelSize: 16
                                            font.bold: true
                                            color: "#FFFFFF"
                                        }
                                        Rectangle {
                                            width: (stateManager && stateManager.streamerXUnifyInstalled) ? 132 : 118
                                            height: 22
                                            radius: 11
                                            color: (stateManager && stateManager.streamerXUnifyInstalled) ? "#153820" : "#24242C"
                                            border.color: (stateManager && stateManager.streamerXUnifyInstalled) ? "#28C850" : "#3E3E4C"
                                            border.width: 1
                                            Text {
                                                anchors.centerIn: parent
                                                text: (stateManager && stateManager.streamerXUnifyInstalled) ? (stateManager ? stateManager.strings.unify_active_mt : "● MULTIPISTA ACTIVA") : (stateManager ? stateManager.strings.unify_active_stereo : "○ STEREO ESTÁNDAR")
                                                font.pixelSize: 9
                                                font.bold: true
                                                color: (stateManager && stateManager.streamerXUnifyInstalled) ? "#28C850" : "#8E8E98"
                                            }
                                        }
                                    }

                                    Text {
                                        text: stateManager ? stateManager.strings.unify_desc : "Crea dispositivos virtuales independientes en PipeWire (Game, Chat, Music, System y Stream Mix) con enrutamiento automático hacia auriculares y OBS Studio."
                                        font.pixelSize: 11
                                        color: "#9A9AA2"
                                        Layout.preferredWidth: root.width - 340
                                        wrapMode: Text.WordWrap
                                    }

                                    // USB multitrack mode (what RØDE UNIFY enables on macOS/Windows)
                                    RowLayout {
                                        spacing: 10
                                        Layout.topMargin: 4

                                        Switch {
                                            id: multitrackSwitch
                                            checked: stateManager ? stateManager.streamerXMultitrack : false
                                            onToggled: if (stateManager) stateManager.setStreamerXMultitrack(checked)
                                        }

                                        Text {
                                            text: (stateManager && stateManager.streamerXMultitrack)
                                                  ? (stateManager ? stateManager.strings.unify_mt_active_desc : "Multipista USB activa: Micrófono, Headset, Wireless, SMART Pads y canales 6-9 como entradas separadas para tu DAW")
                                                  : (stateManager ? stateManager.strings.unify_mt_inactive_desc : "Multipista USB (9 canales): graba cada entrada de la Streamer X en su propia pista")
                                            font.pixelSize: 11
                                            color: (stateManager && stateManager.streamerXMultitrack) ? "#28C850" : "#C8C8D0"
                                            Layout.preferredWidth: root.width - 400
                                            wrapMode: Text.WordWrap
                                        }
                                    }
                                }

                                Button {
                                    text: (stateManager && stateManager.streamerXUnifyInstalled) ? (stateManager ? stateManager.strings.unify_btn_deactivate : "Desactivar UNIFY") : (stateManager ? stateManager.strings.unify_btn_activate : "Activar UNIFY en Linux")
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
                                        implicitWidth: 165
                                        implicitHeight: 38
                                        radius: 8
                                        color: (stateManager && stateManager.streamerXUnifyInstalled) ? "#7D2525" : "#237A42"
                                        border.color: (stateManager && stateManager.streamerXUnifyInstalled) ? "#B23636" : "#32A056"
                                        border.width: 1
                                    }
                                    onClicked: {
                                        if (stateManager) stateManager.toggleStreamerXUnifyProfile();
                                    }
                                }
                            }

                            // 5 Audio Channel Strips Layout
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                Repeater {
                                    model: [
                                        {"name": "GAME", "node": "streamerx_game", "desc": stateManager ? stateManager.strings.unify_game_desc : "Juegos / Steam", "color": "#3B82F6"},
                                        {"name": "CHAT", "node": "streamerx_chat", "desc": stateManager ? stateManager.strings.unify_chat_desc : "Discord / Teams", "color": "#10B981"},
                                        {"name": "MUSIC", "node": "streamerx_music", "desc": stateManager ? stateManager.strings.unify_music_desc : "Spotify / Media", "color": "#F59E0B"},
                                        {"name": "SYSTEM", "node": "streamerx_system", "desc": stateManager ? stateManager.strings.unify_system_desc : "Alertas del SO", "color": "#8B5CF6"},
                                        {"name": "STREAM MIX", "node": "streamerx_stream_mix", "desc": stateManager ? stateManager.strings.unify_stream_mix_desc : "Mezcla Maestra OBS", "color": "#EF4444"}
                                    ]

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 88
                                        radius: 8
                                        color: (stateManager && stateManager.streamerXUnifyInstalled) ? "#1B1F28" : "#1E1E24"
                                        border.color: (stateManager && stateManager.streamerXUnifyInstalled) ? modelData.color : "#2C2C36"
                                        border.width: (stateManager && stateManager.streamerXUnifyInstalled) ? 1.5 : 1
                                        clip: true

                                        // Top accent bar
                                        Rectangle {
                                            anchors.top: parent.top
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            height: 3
                                            color: modelData.color
                                        }

                                        ColumnLayout {
                                            anchors.fill: parent
                                            anchors.topMargin: 10
                                            anchors.bottomMargin: 8
                                            anchors.leftMargin: 10
                                            anchors.rightMargin: 10
                                            spacing: 4

                                            RowLayout {
                                                spacing: 6
                                                Rectangle {
                                                    width: 6
                                                    height: 6
                                                    radius: 3
                                                    color: (stateManager && stateManager.streamerXUnifyInstalled) ? modelData.color : "#606068"
                                                }
                                                Text {
                                                    text: modelData.name
                                                    font.pixelSize: 12
                                                    font.bold: true
                                                    color: (stateManager && stateManager.streamerXUnifyInstalled) ? "#FFFFFF" : "#CCCCCC"
                                                    elide: Text.ElideRight
                                                    Layout.fillWidth: true
                                                }
                                            }

                                            // Monospace Sink Badge
                                            Rectangle {
                                                Layout.fillWidth: true
                                                height: 18
                                                radius: 4
                                                color: "#141418"
                                                border.color: "#26262E"
                                                border.width: 1

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: modelData.node
                                                    font.family: "Monospace"
                                                    font.pixelSize: 9
                                                    color: (stateManager && stateManager.streamerXUnifyInstalled) ? modelData.color : "#888892"
                                                    elide: Text.ElideRight
                                                }
                                            }

                                            Text {
                                                text: modelData.desc
                                                font.pixelSize: 10
                                                color: "#7E7E88"
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }
                                        }
                                    }
                                }
                            }

                            // Bottom Info Tip
                            Rectangle {
                                Layout.fillWidth: true
                                height: 36
                                radius: 8
                                color: "#15151B"
                                border.color: "#252530"
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    spacing: 10

                                    Rectangle {
                                        width: 80
                                        height: 20
                                        radius: 4
                                        color: "#22222E"
                                        border.color: "#353545"
                                        border.width: 1

                                        Text {
                                            anchors.centerIn: parent
                                            text: stateManager ? stateManager.strings.unify_tip_badge : "OBS & DAWs"
                                            font.pixelSize: 10
                                            font.bold: true
                                            color: "#CBA158"
                                        }
                                    }

                                    Text {
                                        text: stateManager ? stateManager.strings.unify_tip_text : "Los 5 canales virtuales aparecen de inmediato en PipeWire para capturar en pistas independientes (1-6) sin solapamiento."
                                        font.pixelSize: 11
                                        color: "#A2A2AC"
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
                        implicitHeight: (stateManager && stateManager.isStreamerX) ? 104 : 150
                        Layout.preferredHeight: implicitHeight
                        radius: 12
                        color: "#1A1A1D"
                        border.color: "#2C2C32"
                        border.width: 1

                        ColumnLayout {
                            id: hpCol
                            anchors.fill: parent
                            anchors.margins: 18
                            spacing: 14

                            Text {
                                text: "🎧 " + (stateManager && stateManager.isStreamerX 
                                      ? (stateManager ? stateManager.strings.hp_front_output : "Salida de Auriculares (Frontal TRRS 3.5mm)") 
                                      : (stateManager ? stateManager.strings.headphones : "Auriculares"))
                                font.pixelSize: 15
                                font.bold: true
                                color: "#FFFFFF"
                            }

                            // Headphone 1 (or Main Headphone for Streamer X)
                            RowLayout {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 32
                                spacing: 14

                                Text {
                                    text: (stateManager && stateManager.isStreamerX) ? (stateManager ? stateManager.strings.headphone : "Auricular") : (stateManager ? stateManager.strings.headphone_1 : "Headphone 1")
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

                            // Headphone 2 (Hidden for Streamer X since it only has 1 headphone output)
                            RowLayout {
                                visible: Boolean(stateManager && !stateManager.isStreamerX)
                                Layout.fillWidth: true
                                Layout.preferredHeight: visible ? 32 : 0
                                spacing: 14

                                Text {
                                    text: stateManager ? stateManager.strings.headphone_2 : "Headphone 2"
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

                    // 3. Monitor & Routing Options Card (Hidden for Streamer X: no monitor speakers or solo buttons)
                    Rectangle {
                        visible: Boolean(stateManager && !stateManager.isStreamerX)
                        Layout.fillWidth: true
                        implicitHeight: visible ? (monCol.implicitHeight + 36) : 0
                        Layout.preferredHeight: implicitHeight
                        radius: 12
                        color: "#1A1A1D"
                        border.color: "#2C2C32"
                        border.width: 1

                        ColumnLayout {
                            id: monCol
                            anchors.fill: parent
                            anchors.margins: 18
                            spacing: 16

                        Text {
                            text: "🔊 " + (stateManager ? stateManager.strings.monitor : "Monitores") + " & " + (stateManager ? stateManager.strings.routing : "Enrutamiento")
                            font.pixelSize: 15
                            font.bold: true
                            color: "#FFFFFF"
                        }

                        // Auto-mute Monitor Output (Duo / Pro II)
                        RowLayout {
                            visible: Boolean(stateManager && !stateManager.isStreamerX)
                            Layout.fillWidth: true
                            ColumnLayout {
                                spacing: 2
                                Text {
                                    text: stateManager ? stateManager.strings.auto_mute_output : "Silenciar monitores al subir micrófono"
                                    font.pixelSize: 13
                                    color: "#E0E0E0"
                                }
                                Text {
                                    text: stateManager ? stateManager.strings.auto_mute_output_desc : "Evita retroalimentación acústica al hablar por los micrófonos"
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

                        Rectangle {
                            visible: Boolean(stateManager && !stateManager.isStreamerX)
                            Layout.fillWidth: true; height: 1; color: "#28282E"
                        }

                        // Auto-mute Bluetooth (Duo / Pro II)
                        RowLayout {
                            visible: Boolean(stateManager && !stateManager.isStreamerX)
                            Layout.fillWidth: true
                            ColumnLayout {
                                spacing: 2
                                Text {
                                    text: stateManager ? stateManager.strings.auto_mute_bt : "Silenciar Bluetooth al subir micrófono"
                                    font.pixelSize: 13
                                    color: "#E0E0E0"
                                }
                                Text {
                                    text: stateManager ? stateManager.strings.auto_mute_bt_desc : "Atenúa la salida bluetooth mientras hablas"
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

                        Rectangle {
                            visible: Boolean(stateManager && !stateManager.isStreamerX)
                            Layout.fillWidth: true; height: 1; color: "#28282E"
                        }

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
                                    text: stateManager ? stateManager.strings.listen_desc : "Pre-fader (PFL) o After-fader (AFL) para los botones Listen"
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
                                    text: stateManager ? stateManager.strings.multitrack_desc : "Graba canales individuales independientes en la tarjeta MicroSD"
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
                    Item { Layout.fillHeight: true }
                }
            }

            // TAB 1: DISPLAY & BRIGHTNESS
            ColumnLayout {
                id: tab1Col
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 18
                visible: root.activeTab === 1

                // Brightness & Dimming Card
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: dispCol.implicitHeight + 36
                    Layout.preferredHeight: implicitHeight
                    radius: 12
                    color: "#1A1A1D"
                    border.color: "#2C2C32"
                    border.width: 1

                    ColumnLayout {
                        id: dispCol
                        anchors.fill: parent
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
                            visible: !(stateManager && stateManager.isStreamerX)
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
                                from: (stateManager && stateManager.isStreamerX ? 0 : 20)
                                to: 255
                                value: stateManager ? stateManager.buttonBrightness : 255
                                onMoved: {
                                    if (stateManager) {
                                        stateManager.setButtonBrightness(Math.round(value));
                                        if (stateManager.isStreamerX && stateManager.brightnessScheduleEnabled) {
                                            if (stateManager.brightnessScheduleIsNight) {
                                                stateManager.setBrightnessScheduleNight(Math.round(value));
                                            } else {
                                                stateManager.setBrightnessScheduleDay(Math.round(value));
                                            }
                                        }
                                    }
                                }
                            }
                            Text {
                                text: Math.round(((stateManager ? stateManager.buttonBrightness : 255) / 255.0) * 100) + "%"
                                font.pixelSize: 12
                                color: "#CBA158"
                                Layout.preferredWidth: 45
                            }
                        }

                        // Scheduled Brightness (Streamer X)
                        Rectangle {
                            visible: stateManager && stateManager.isStreamerX
                            Layout.fillWidth: true
                            height: 1
                            color: "#28282E"
                        }

                        ColumnLayout {
                            visible: stateManager && stateManager.isStreamerX
                            Layout.fillWidth: true
                            spacing: 14

                            // Schedule Switch Header
                            RowLayout {
                                Layout.fillWidth: true
                                ColumnLayout {
                                    spacing: 2
                                    Text {
                                        text: stateManager ? stateManager.strings.scheduled_brightness : "Brillo Programado"
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: "#E0E0E0"
                                    }
                                    Text {
                                        text: stateManager ? stateManager.strings.scheduled_brightness_desc : "Ajusta el brillo de los botones automáticamente según el horario"
                                        font.pixelSize: 11
                                        color: "#8E8E93"
                                    }
                                }
                                Item { Layout.fillWidth: true }
                                Switch {
                                    checked: stateManager ? stateManager.brightnessScheduleEnabled : false
                                    onToggled: {
                                        if (stateManager) stateManager.setBrightnessScheduleEnabled(checked);
                                    }
                                }
                            }

                            // Active Status Banner (when enabled)
                            Rectangle {
                                visible: stateManager && stateManager.brightnessScheduleEnabled
                                Layout.fillWidth: true
                                height: 38
                                radius: 8
                                color: (stateManager && stateManager.brightnessScheduleIsNight) ? "#1A1D27" : "#24221A"
                                border.color: (stateManager && stateManager.brightnessScheduleIsNight) ? "#33415F" : "#554622"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 14
                                    anchors.rightMargin: 14
                                    spacing: 10

                                    Text {
                                        text: (stateManager && stateManager.brightnessScheduleIsNight) ? "🌙" : "☀️"
                                        font.pixelSize: 14
                                    }
                                    Text {
                                        text: stateManager ? stateManager.brightnessScheduleStatusText : ""
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: (stateManager && stateManager.brightnessScheduleIsNight) ? "#8BB2FF" : "#F5D061"
                                        Layout.fillWidth: true
                                    }
                                }
                            }

                            // Time Range Pickers
                            ColumnLayout {
                                visible: stateManager && stateManager.brightnessScheduleEnabled
                                Layout.fillWidth: true
                                spacing: 14

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 14

                                    // Start Time Box (Night mode starts)
                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 72
                                        radius: 8
                                        color: "#18181C"
                                        border.color: "#2C2C34"

                                        ColumnLayout {
                                            anchors.fill: parent
                                            anchors.margins: 10
                                            spacing: 6

                                            Text {
                                                text: "🌙 " + (stateManager ? stateManager.strings.schedule_start : "Hora de inicio (Noche)")
                                                font.pixelSize: 11
                                                font.bold: true
                                                color: "#A0A0A8"
                                            }

                                            RowLayout {
                                                spacing: 6
                                                ComboBox {
                                                    id: schedStartHourCombo
                                                    implicitWidth: 64
                                                    implicitHeight: 28
                                                    model: root.hoursList
                                                    currentIndex: stateManager ? stateManager.brightnessScheduleStartHour : 22
                                                    onActivated: (index) => {
                                                        if (stateManager) stateManager.setBrightnessScheduleStart(index, schedStartMinCombo.currentIndex);
                                                    }
                                                    background: Rectangle {
                                                        color: "#222228"
                                                        border.color: "#383842"
                                                        radius: 6
                                                    }
                                                    contentItem: Text {
                                                        text: schedStartHourCombo.displayText
                                                        font.pixelSize: 12
                                                        font.bold: true
                                                        color: "#FFFFFF"
                                                        verticalAlignment: Text.AlignVCenter
                                                        horizontalAlignment: Text.AlignHCenter
                                                    }
                                                    delegate: ItemDelegate {
                                                        width: schedStartHourCombo.width
                                                        implicitHeight: 28
                                                        contentItem: Text {
                                                            text: modelData
                                                            color: highlighted ? "#CBA158" : "#E0E0E0"
                                                            font.pixelSize: 12
                                                            horizontalAlignment: Text.AlignHCenter
                                                            verticalAlignment: Text.AlignVCenter
                                                        }
                                                        background: Rectangle {
                                                            color: highlighted ? "#2A2A35" : "#1B1B1F"
                                                        }
                                                    }
                                                    popup: Popup {
                                                        y: schedStartHourCombo.height + 2
                                                        width: schedStartHourCombo.width
                                                        implicitHeight: Math.min(180, contentItem.implicitHeight + 8)
                                                        padding: 2
                                                        contentItem: ListView {
                                                            clip: true
                                                            implicitHeight: contentHeight
                                                            model: schedStartHourCombo.popup.visible ? schedStartHourCombo.delegateModel : null
                                                            currentIndex: schedStartHourCombo.highlightedIndex
                                                            ScrollIndicator.vertical: ScrollIndicator { }
                                                        }
                                                        background: Rectangle {
                                                            color: "#1B1B1F"
                                                            border.color: "#383842"
                                                            radius: 6
                                                        }
                                                    }
                                                }

                                                Text {
                                                    text: ":"
                                                    font.pixelSize: 14
                                                    font.bold: true
                                                    color: "#8E8E93"
                                                }

                                                ComboBox {
                                                    id: schedStartMinCombo
                                                    implicitWidth: 64
                                                    implicitHeight: 28
                                                    model: root.minutesList
                                                    currentIndex: stateManager ? stateManager.brightnessScheduleStartMinute : 0
                                                    onActivated: (index) => {
                                                        if (stateManager) stateManager.setBrightnessScheduleStart(schedStartHourCombo.currentIndex, index);
                                                    }
                                                    background: Rectangle {
                                                        color: "#222228"
                                                        border.color: "#383842"
                                                        radius: 6
                                                    }
                                                    contentItem: Text {
                                                        text: schedStartMinCombo.displayText
                                                        font.pixelSize: 12
                                                        font.bold: true
                                                        color: "#FFFFFF"
                                                        verticalAlignment: Text.AlignVCenter
                                                        horizontalAlignment: Text.AlignHCenter
                                                    }
                                                    delegate: ItemDelegate {
                                                        width: schedStartMinCombo.width
                                                        implicitHeight: 28
                                                        contentItem: Text {
                                                            text: modelData
                                                            color: highlighted ? "#CBA158" : "#E0E0E0"
                                                            font.pixelSize: 12
                                                            horizontalAlignment: Text.AlignHCenter
                                                            verticalAlignment: Text.AlignVCenter
                                                        }
                                                        background: Rectangle {
                                                            color: highlighted ? "#2A2A35" : "#1B1B1F"
                                                        }
                                                    }
                                                    popup: Popup {
                                                        y: schedStartMinCombo.height + 2
                                                        width: schedStartMinCombo.width
                                                        implicitHeight: Math.min(180, contentItem.implicitHeight + 8)
                                                        padding: 2
                                                        contentItem: ListView {
                                                            clip: true
                                                            implicitHeight: contentHeight
                                                            model: schedStartMinCombo.popup.visible ? schedStartMinCombo.delegateModel : null
                                                            currentIndex: schedStartMinCombo.highlightedIndex
                                                            ScrollIndicator.vertical: ScrollIndicator { }
                                                        }
                                                        background: Rectangle {
                                                            color: "#1B1B1F"
                                                            border.color: "#383842"
                                                            radius: 6
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // End Time Box (Day mode starts)
                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 72
                                        radius: 8
                                        color: "#18181C"
                                        border.color: "#2C2C34"

                                        ColumnLayout {
                                            anchors.fill: parent
                                            anchors.margins: 10
                                            spacing: 6

                                            Text {
                                                text: "☀️ " + (stateManager ? stateManager.strings.schedule_end : "Hora de fin (Día)")
                                                font.pixelSize: 11
                                                font.bold: true
                                                color: "#A0A0A8"
                                            }

                                            RowLayout {
                                                spacing: 6
                                                ComboBox {
                                                    id: schedEndHourCombo
                                                    implicitWidth: 64
                                                    implicitHeight: 28
                                                    model: root.hoursList
                                                    currentIndex: stateManager ? stateManager.brightnessScheduleEndHour : 7
                                                    onActivated: (index) => {
                                                        if (stateManager) stateManager.setBrightnessScheduleEnd(index, schedEndMinCombo.currentIndex);
                                                    }
                                                    background: Rectangle {
                                                        color: "#222228"
                                                        border.color: "#383842"
                                                        radius: 6
                                                    }
                                                    contentItem: Text {
                                                        text: schedEndHourCombo.displayText
                                                        font.pixelSize: 12
                                                        font.bold: true
                                                        color: "#FFFFFF"
                                                        verticalAlignment: Text.AlignVCenter
                                                        horizontalAlignment: Text.AlignHCenter
                                                    }
                                                    delegate: ItemDelegate {
                                                        width: schedEndHourCombo.width
                                                        implicitHeight: 28
                                                        contentItem: Text {
                                                            text: modelData
                                                            color: highlighted ? "#CBA158" : "#E0E0E0"
                                                            font.pixelSize: 12
                                                            horizontalAlignment: Text.AlignHCenter
                                                            verticalAlignment: Text.AlignVCenter
                                                        }
                                                        background: Rectangle {
                                                            color: highlighted ? "#2A2A35" : "#1B1B1F"
                                                        }
                                                    }
                                                    popup: Popup {
                                                        y: schedEndHourCombo.height + 2
                                                        width: schedEndHourCombo.width
                                                        implicitHeight: Math.min(180, contentItem.implicitHeight + 8)
                                                        padding: 2
                                                        contentItem: ListView {
                                                            clip: true
                                                            implicitHeight: contentHeight
                                                            model: schedEndHourCombo.popup.visible ? schedEndHourCombo.delegateModel : null
                                                            currentIndex: schedEndHourCombo.highlightedIndex
                                                            ScrollIndicator.vertical: ScrollIndicator { }
                                                        }
                                                        background: Rectangle {
                                                            color: "#1B1B1F"
                                                            border.color: "#383842"
                                                            radius: 6
                                                        }
                                                    }
                                                }

                                                Text {
                                                    text: ":"
                                                    font.pixelSize: 14
                                                    font.bold: true
                                                    color: "#8E8E93"
                                                }

                                                ComboBox {
                                                    id: schedEndMinCombo
                                                    implicitWidth: 64
                                                    implicitHeight: 28
                                                    model: root.minutesList
                                                    currentIndex: stateManager ? stateManager.brightnessScheduleEndMinute : 0
                                                    onActivated: (index) => {
                                                        if (stateManager) stateManager.setBrightnessScheduleEnd(schedEndHourCombo.currentIndex, index);
                                                    }
                                                    background: Rectangle {
                                                        color: "#222228"
                                                        border.color: "#383842"
                                                        radius: 6
                                                    }
                                                    contentItem: Text {
                                                        text: schedEndMinCombo.displayText
                                                        font.pixelSize: 12
                                                        font.bold: true
                                                        color: "#FFFFFF"
                                                        verticalAlignment: Text.AlignVCenter
                                                        horizontalAlignment: Text.AlignHCenter
                                                    }
                                                    delegate: ItemDelegate {
                                                        width: schedEndMinCombo.width
                                                        implicitHeight: 28
                                                        contentItem: Text {
                                                            text: modelData
                                                            color: highlighted ? "#CBA158" : "#E0E0E0"
                                                            font.pixelSize: 12
                                                            horizontalAlignment: Text.AlignHCenter
                                                            verticalAlignment: Text.AlignVCenter
                                                        }
                                                        background: Rectangle {
                                                            color: highlighted ? "#2A2A35" : "#1B1B1F"
                                                        }
                                                    }
                                                    popup: Popup {
                                                        y: schedEndMinCombo.height + 2
                                                        width: schedEndMinCombo.width
                                                        implicitHeight: Math.min(180, contentItem.implicitHeight + 8)
                                                        padding: 2
                                                        contentItem: ListView {
                                                            clip: true
                                                            implicitHeight: contentHeight
                                                            model: schedEndMinCombo.popup.visible ? schedEndMinCombo.delegateModel : null
                                                            currentIndex: schedEndMinCombo.highlightedIndex
                                                            ScrollIndicator.vertical: ScrollIndicator { }
                                                        }
                                                        background: Rectangle {
                                                            color: "#1B1B1F"
                                                            border.color: "#383842"
                                                            radius: 6
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                // Day Brightness Slider
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 14
                                    Text {
                                        text: "☀️ " + (stateManager ? stateManager.strings.schedule_day_brightness : "Brillo de día")
                                        font.pixelSize: 13
                                        color: "#E0E0E0"
                                        Layout.preferredWidth: 140
                                    }
                                    Slider {
                                        Layout.fillWidth: true
                                        from: 0
                                        to: 255
                                        value: stateManager ? stateManager.brightnessScheduleDay : 255
                                        onMoved: {
                                            if (stateManager) stateManager.setBrightnessScheduleDay(Math.round(value));
                                        }
                                    }
                                    Text {
                                        text: Math.round(((stateManager ? stateManager.brightnessScheduleDay : 255) / 255.0) * 100) + "%"
                                        font.pixelSize: 12
                                        color: "#CBA158"
                                        Layout.preferredWidth: 45
                                    }
                                }

                                // Night Brightness Slider
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 14
                                    Text {
                                        text: "🌙 " + (stateManager ? stateManager.strings.schedule_night_brightness : "Brillo de noche")
                                        font.pixelSize: 13
                                        color: "#E0E0E0"
                                        Layout.preferredWidth: 140
                                    }
                                    Slider {
                                        Layout.fillWidth: true
                                        from: 0
                                        to: 255
                                        value: stateManager ? stateManager.brightnessScheduleNight : 0
                                        onMoved: {
                                            if (stateManager) stateManager.setBrightnessScheduleNight(Math.round(value));
                                        }
                                    }
                                    Text {
                                        text: Math.round(((stateManager ? stateManager.brightnessScheduleNight : 0) / 255.0) * 100) + "%"
                                        font.pixelSize: 12
                                        color: "#CBA158"
                                        Layout.preferredWidth: 45
                                    }
                                }
                            }
                        }

                        Rectangle { visible: !(stateManager && stateManager.isStreamerX); Layout.fillWidth: true; height: 1; color: "#28282E" }

                        // Auto Brightness
                        RowLayout {
                            visible: !(stateManager && stateManager.isStreamerX)
                            Layout.fillWidth: true
                            ColumnLayout {
                                spacing: 2
                                Text {
                                    text: stateManager ? stateManager.strings.auto_brightness : "Brillo Automático"
                                    font.pixelSize: 13
                                    color: "#E0E0E0"
                                }
                                Text {
                                    text: stateManager ? stateManager.strings.auto_brightness_desc : "Ajustar el sensor de luz ambiental automáticamente"
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

                        Rectangle { visible: !(stateManager && stateManager.isStreamerX); Layout.fillWidth: true; height: 1; color: "#28282E" }

                        // Metering Cards (Default vs Broadcast)
                        ColumnLayout {
                            visible: !(stateManager && stateManager.isStreamerX)
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
                                                text: stateManager && stateManager.language === "es" ? "✓ Activo" : "✓ Active"
                                                font.pixelSize: 11
                                                font.bold: true
                                                color: "#34C759"
                                            }
                                        }

                                        Text {
                                            text: stateManager ? stateManager.strings.metering_standard_desc : "Los vúmetros incluyen marcadores a intervalos regulares e indican el nivel de ganancia unitario estándar."
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
                                                text: stateManager && stateManager.language === "es" ? "✓ Activo" : "✓ Active"
                                                font.pixelSize: 11
                                                font.bold: true
                                                color: "#34C759"
                                            }
                                        }

                                        Text {
                                            text: stateManager ? stateManager.strings.metering_broadcast_desc : "Los vúmetros incluyen marcadores precisos de escala dBFS en cada canal y medidores de reducción de ganancia (compresor)."
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

                        Rectangle { visible: !(stateManager && stateManager.isStreamerX); Layout.fillWidth: true; height: 1; color: "#28282E" }

                        // Haptic Feedback
                        RowLayout {
                            visible: !(stateManager && stateManager.isStreamerX)
                            Layout.fillWidth: true
                            ColumnLayout {
                                spacing: 2
                                Text {
                                    text: stateManager ? stateManager.strings.haptics : "Respuesta Háptica"
                                    font.pixelSize: 13
                                    color: "#E0E0E0"
                                }
                                Text {
                                    text: stateManager ? stateManager.strings.haptics_desc : "Vibración al tocar los pads y controles táctiles"
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
                Item { Layout.fillHeight: true }
            }

            // TAB 2: SYSTEM
            ColumnLayout {
                id: tab2Col
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 18
                visible: root.activeTab === 2

                // System Info Card
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: sysCol.implicitHeight + 36
                    Layout.preferredHeight: implicitHeight
                    radius: 12
                    color: "#1A1A1D"
                    border.color: "#2C2C32"
                    border.width: 1

                    ColumnLayout {
                        id: sysCol
                        anchors.fill: parent
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
                            Text { text: stateManager ? stateManager.strings.device_label : "Dispositivo"; font.pixelSize: 13; color: "#8E8E93"; Layout.preferredWidth: 150 }
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
                Item { Layout.fillHeight: true }
            }
        }
    }
}
}

