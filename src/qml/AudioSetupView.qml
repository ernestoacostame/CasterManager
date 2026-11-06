import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: root

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
                            color: "#222226"
                            border.color: modelData.mute ? "#FF3B30" : (modelData.listen ? "#34C759" : "#303036")
                            border.width: modelData.mute || modelData.listen ? 1.5 : 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 10

                                // Channel Label & Color Pill
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
                                        color: "#FFFFFF"
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
                                                height: faderSlider.visualPosition * parent.height
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

            Text {
                text: stateManager ? stateManager.strings.input_sources_pool : "Fuentes de Entrada Disponibles"
                font.pixelSize: 14
                font.bold: true
                color: "#FFFFFF"
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 4
                rowSpacing: 12
                columnSpacing: 12

                // Source Item 1: Combo XLR 1
                Rectangle {
                    Layout.fillWidth: true
                    height: 54
                    radius: 8
                    color: "#212125"
                    border.color: "#303036"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10

                        Text { text: "🎙️"; font.pixelSize: 18 }
                        ColumnLayout {
                            spacing: 2
                            Text { text: "Input 1 (Mic / Inst)"; font.pixelSize: 12; font.bold: true; color: "#FFFFFF" }
                            Text { text: "Neutrik Combo XLR"; font.pixelSize: 10; color: "#8E8E93" }
                        }
                        Item { Layout.fillWidth: true }
                        Rectangle {
                            width: 32; height: 18; radius: 4; color: "#2E2E34"
                            Text { anchors.centerIn: parent; text: "+48V"; font.pixelSize: 9; font.bold: true; color: "#FF9F0A" }
                        }
                    }
                }

                // Source Item 2: Combo XLR 2
                Rectangle {
                    Layout.fillWidth: true
                    height: 54
                    radius: 8
                    color: "#212125"
                    border.color: "#303036"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10

                        Text { text: "🎙️"; font.pixelSize: 18 }
                        ColumnLayout {
                            spacing: 2
                            Text { text: "Input 2 (Mic / Inst)"; font.pixelSize: 12; font.bold: true; color: "#FFFFFF" }
                            Text { text: "Neutrik Combo XLR"; font.pixelSize: 10; color: "#8E8E93" }
                        }
                        Item { Layout.fillWidth: true }
                        Rectangle {
                            width: 32; height: 18; radius: 4; color: "#2E2E34"
                            Text { anchors.centerIn: parent; text: "+48V"; font.pixelSize: 9; font.bold: true; color: "#FF9F0A" }
                        }
                    }
                }

                // Source Item 3: Wireless Receiver
                Rectangle {
                    Layout.fillWidth: true
                    height: 54
                    radius: 8
                    color: "#212125"
                    border.color: "#303036"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10

                        Text { text: "📡"; font.pixelSize: 18 }
                        ColumnLayout {
                            spacing: 2
                            Text { text: "Wireless Series IV"; font.pixelSize: 12; font.bold: true; color: "#FFFFFF" }
                            Text { text: "Receptor 2.4 GHz dual"; font.pixelSize: 10; color: "#8E8E93" }
                        }
                    }
                }

                // Source Item 4: USB 1 Audio
                Rectangle {
                    Layout.fillWidth: true
                    height: 54
                    radius: 8
                    color: "#212125"
                    border.color: "#303036"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10

                        Text { text: "💻"; font.pixelSize: 18 }
                        ColumnLayout {
                            spacing: 2
                            Text { text: "USB 1 Audio (Main)"; font.pixelSize: 12; font.bold: true; color: "#FFFFFF" }
                            Text { text: "Multicanal 24-bit / 48kHz"; font.pixelSize: 10; color: "#8E8E93" }
                        }
                    }
                }

                // Source Item 5: USB 2 Audio (Chat)
                Rectangle {
                    Layout.fillWidth: true
                    height: 54
                    radius: 8
                    color: "#212125"
                    border.color: "#303036"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10

                        Text { text: "💬"; font.pixelSize: 18 }
                        ColumnLayout {
                            spacing: 2
                            Text { text: "USB 2 Audio (Chat)"; font.pixelSize: 12; font.bold: true; color: "#FFFFFF" }
                            Text { text: "Mix-minus automático"; font.pixelSize: 10; color: "#8E8E93" }
                        }
                    }
                }

                // Source Item 6: Bluetooth Audio
                Rectangle {
                    Layout.fillWidth: true
                    height: 54
                    radius: 8
                    color: "#212125"
                    border.color: "#303036"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10

                        Text { text: "📶"; font.pixelSize: 18 }
                        ColumnLayout {
                            spacing: 2
                            Text { text: "Bluetooth Stereo"; font.pixelSize: 12; font.bold: true; color: "#FFFFFF" }
                            Text { text: "A2DP y llamadas de voz"; font.pixelSize: 10; color: "#8E8E93" }
                        }
                    }
                }

                // Source Item 7: SMART Pads
                Rectangle {
                    Layout.fillWidth: true
                    height: 54
                    radius: 8
                    color: "#212125"
                    border.color: "#303036"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10

                        Text { text: "🎛️"; font.pixelSize: 18 }
                        ColumnLayout {
                            spacing: 2
                            Text { text: "SMART Pads Audio"; font.pixelSize: 12; font.bold: true; color: "#FFFFFF" }
                            Text { text: "Reproductor estéreo interno"; font.pixelSize: 10; color: "#8E8E93" }
                        }
                    }
                }

                // Source Item 8: Master Mix
                Rectangle {
                    Layout.fillWidth: true
                    height: 54
                    radius: 8
                    color: "#212125"
                    border.color: "#303036"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10

                        Text { text: "🎚️"; font.pixelSize: 18 }
                        ColumnLayout {
                            spacing: 2
                            Text { text: "Main Stereo Mix"; font.pixelSize: 12; font.bold: true; color: "#FFFFFF" }
                            Text { text: "APHEX Master Compellor"; font.pixelSize: 10; color: "#8E8E93" }
                        }
                    }
                }
            }
        }
    }
}
