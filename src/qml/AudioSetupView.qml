import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: root

    property int selectedChannelIndex: 0

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 28
        spacing: 24

        // Header Title Row
        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            Text {
                text: stateManager ? stateManager.strings.hub_audio_setup : "Configuración de Audio"
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
                text: stateManager ? stateManager.strings.faders_title : "Mezclador de Faders en Vivo"
                font.pixelSize: 13
                color: "#8E8E93"
            }

            Item { Layout.fillWidth: true }
        }

        // Live Fader Channels Strip (Top Card)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 330
            radius: 12
            color: "#1A1A1D"
            border.color: "#2C2C32"
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                // Row of Fader Channel Strips
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 14

                    Repeater {
                        model: stateManager ? stateManager.faders : []

                        // Single Fader Strip
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 10
                            color: root.selectedChannelIndex === modelData.index ? "#282830" : "#222226"
                            border.color: modelData.mute ? "#FF3B30" : (modelData.listen ? "#34C759" : (root.selectedChannelIndex === modelData.index ? "#CBA158" : "#303036"))
                            border.width: (root.selectedChannelIndex === modelData.index || modelData.mute || modelData.listen) ? 2 : 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 10

                                // Channel Label & Color Pill (Clickable to select channel)
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Rectangle {
                                        width: 10
                                        height: 10
                                        radius: 5
                                        color: modelData.color || "#CBA158"
                                    }

                                    Text {
                                        text: modelData.name || ("Canal " + (index + 1))
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: root.selectedChannelIndex === modelData.index ? "#CBA158" : "#FFFFFF"
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }

                                // Level readout (dB / %)
                                Text {
                                    text: Math.round(modelData.level) + "%"
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: "#CBA158"
                                    Layout.alignment: Qt.AlignHCenter
                                }

                                // Interactive Vertical Level Slider
                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    Slider {
                                        id: faderSlider
                                        anchors.centerIn: parent
                                        height: parent.height - 10
                                        orientation: Qt.Vertical
                                        from: 0
                                        to: 100
                                        value: modelData.level
                                        onMoved: {
                                            if (stateManager) {
                                                stateManager.setFaderLevel(modelData.index, Math.round(value));
                                            }
                                        }

                                        background: Rectangle {
                                            x: faderSlider.leftPadding + faderSlider.availableWidth / 2 - width / 2
                                            y: faderSlider.topPadding
                                            implicitWidth: 6
                                            implicitHeight: 140
                                            width: 6
                                            height: faderSlider.availableHeight
                                            radius: 3
                                            color: "#151517"

                                            Rectangle {
                                                anchors.bottom: parent.bottom
                                                width: parent.width
                                                height: (faderSlider.value / 100.0) * parent.height
                                                color: modelData.color || "#CBA158"
                                                radius: 3
                                            }
                                        }

                                        handle: Rectangle {
                                            x: faderSlider.leftPadding + faderSlider.availableWidth / 2 - width / 2
                                            y: faderSlider.topPadding + faderSlider.visualPosition * (faderSlider.availableHeight - height)
                                            implicitWidth: 26
                                            implicitHeight: 14
                                            radius: 3
                                            color: "#E5E5EA"
                                            border.color: "#8E8E93"
                                            border.width: 1
                                        }
                                    }
                                }

                                // Mute & Listen Buttons
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    // Mute Button
                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 28
                                        radius: 6
                                        color: modelData.mute ? "#FF3B30" : "#2E2E34"
                                        border.color: modelData.mute ? "#FF453A" : "#3E3E46"
                                        border.width: 1

                                        Text {
                                            anchors.centerIn: parent
                                            text: "MUTE"
                                            font.pixelSize: 10
                                            font.bold: true
                                            color: modelData.mute ? "#FFFFFF" : "#AAAAAA"
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (stateManager) stateManager.toggleFaderMute(modelData.index);
                                            }
                                        }
                                    }

                                    // Listen (Solo) Button
                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 28
                                        radius: 6
                                        color: modelData.listen ? "#34C759" : "#2E2E34"
                                        border.color: modelData.listen ? "#30D158" : "#3E3E46"
                                        border.width: 1

                                        Text {
                                            anchors.centerIn: parent
                                            text: "LISTEN"
                                            font.pixelSize: 10
                                            font.bold: true
                                            color: modelData.listen ? "#FFFFFF" : "#AAAAAA"
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (stateManager) stateManager.toggleFaderListen(modelData.index);
                                            }
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                z: -1
                                onClicked: root.selectedChannelIndex = modelData.index
                            }
                        }
                    }
                }
            }
        }

        // Available Input Sources Pool (Bottom Section)
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: stateManager ? stateManager.strings.input_sources_pool : "Fuentes de Entrada Disponibles"
                    font.pixelSize: 14
                    font.bold: true
                    color: "#FFFFFF"
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: "Haz clic en una fuente para asignarla al " + (stateManager && stateManager.faders[root.selectedChannelIndex] ? stateManager.faders[root.selectedChannelIndex].name : "Canal " + (root.selectedChannelIndex + 1))
                    font.pixelSize: 11
                    color: "#CBA158"
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 4
                rowSpacing: 10
                columnSpacing: 10

                Repeater {
                    model: [
                        {"id": 0, "name": "Input 1 (Mic / Inst)", "desc": "Neutrik Combo XLR", "icon": "🎙️", "tag": "+48V"},
                        {"id": 1, "name": "Input 2 (Mic / Inst)", "desc": "Neutrik Combo XLR", "icon": "🎙️", "tag": "+48V"},
                        {"id": 2, "name": "Wireless 1", "desc": "Receptor 2.4 GHz dual", "icon": "📡", "tag": ""},
                        {"id": 3, "name": "Wireless 2", "desc": "Receptor 2.4 GHz dual", "icon": "📡", "tag": ""},
                        {"id": 7, "name": "USB 1 Audio (Main)", "desc": "Multicanal 24-bit / 48kHz", "icon": "💻", "tag": ""},
                        {"id": 8, "name": "USB 1 Chat", "desc": "Mix-minus automático", "icon": "💬", "tag": ""},
                        {"id": 9, "name": "USB 2 Audio", "desc": "Secundario / Smartphone", "icon": "📱", "tag": ""},
                        {"id": 10, "name": "Bluetooth Stereo", "desc": "A2DP y llamadas de voz", "icon": "📶", "tag": ""},
                        {"id": 11, "name": "SMART Pads Audio", "desc": "Reproductor interno", "icon": "🎛️", "tag": ""},
                        {"id": 4, "name": "Headset TRRS", "desc": "Micrófono de auriculares", "icon": "🎧", "tag": ""}
                    ]

                    Rectangle {
                        Layout.fillWidth: true
                        height: 54
                        radius: 8
                        color: srcArea.containsMouse ? "#2A2A30" : "#212125"
                        border.color: srcArea.containsMouse ? "#CBA158" : "#303036"
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 10

                            Text { text: modelData.icon; font.pixelSize: 18 }
                            ColumnLayout {
                                spacing: 2
                                Text { text: modelData.name; font.pixelSize: 12; font.bold: true; color: "#FFFFFF" }
                                Text { text: modelData.desc; font.pixelSize: 10; color: "#8E8E93" }
                            }
                            Item { Layout.fillWidth: true }
                            Rectangle {
                                visible: modelData.tag.length > 0
                                width: 32; height: 18; radius: 4; color: "#2E2E34"
                                Text { anchors.centerIn: parent; text: modelData.tag; font.pixelSize: 9; font.bold: true; color: "#FF9F0A" }
                            }
                        }

                        MouseArea {
                            id: srcArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (stateManager) {
                                    stateManager.assignChannelInputSource(root.selectedChannelIndex, modelData.id);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

