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
                color: (stateManager && stateManager.activeMixTarget === "headphones") ? "#CBA158" : "#FF3B30"
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                text: (stateManager && stateManager.activeMixTarget === "headphones") 
                      ? (stateManager ? stateManager.strings.headphones_submix : "Mis Auriculares (Submezcla)")
                      : (stateManager ? stateManager.strings.faders_title : "Mezclador de Faders en Vivo")
                font.pixelSize: 13
                color: (stateManager && stateManager.activeMixTarget === "headphones") ? "#CBA158" : "#8E8E93"
            }

            Item { Layout.fillWidth: true }

            // Submix Switcher Pill (Stream / Broadcast vs Headphones / Monitor)
            Rectangle {
                visible: true
                height: 36
                width: 360
                radius: 18
                color: "#141416"
                border.color: "#2C2C32"
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 3
                    spacing: 4

                    // Option 1: Main Mix (Live Stream)
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 15
                        color: (!stateManager || stateManager.activeMixTarget === "main") ? "#2A2022" : "transparent"
                        border.color: (!stateManager || stateManager.activeMixTarget === "main") ? "#FF3B30" : "transparent"
                        border.width: (!stateManager || stateManager.activeMixTarget === "main") ? 1 : 0

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            Rectangle {
                                width: 7
                                height: 7
                                radius: 3.5
                                color: "#FF3B30"
                            }

                            Text {
                                text: stateManager ? stateManager.strings.main_mix : "Mezcla Principal (Stream)"
                                font.pixelSize: 11
                                font.bold: !stateManager || stateManager.activeMixTarget === "main"
                                color: (!stateManager || stateManager.activeMixTarget === "main") ? "#FFFFFF" : "#8E8E93"
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (stateManager) stateManager.setActiveMixTarget("main");
                            }
                        }
                    }

                    // Option 2: Headphone Submix (Personal Monitor)
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 15
                        color: (stateManager && stateManager.activeMixTarget === "headphones") ? "#2B2618" : "transparent"
                        border.color: (stateManager && stateManager.activeMixTarget === "headphones") ? "#CBA158" : "transparent"
                        border.width: (stateManager && stateManager.activeMixTarget === "headphones") ? 1 : 0

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: "🎧"
                                font.pixelSize: 11
                            }

                            Text {
                                text: stateManager ? stateManager.strings.headphones_submix : "Mis Auriculares (Submezcla)"
                                font.pixelSize: 11
                                font.bold: stateManager && stateManager.activeMixTarget === "headphones"
                                color: (stateManager && stateManager.activeMixTarget === "headphones") ? "#CBA158" : "#8E8E93"
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (stateManager) stateManager.setActiveMixTarget("headphones");
                            }
                        }
                    }
                }
            }

            // Audio Processing Quick Jump Button
            Rectangle {
                height: 36
                implicitWidth: procRow.implicitWidth + 24
                radius: 18
                color: procArea.containsMouse ? "#2A2A32" : "#1A1A20"
                border.color: procArea.containsMouse ? "#CBA158" : "#2C2C36"
                border.width: 1

                RowLayout {
                    id: procRow
                    anchors.centerIn: parent
                    spacing: 6
                    Text { text: "✨"; font.pixelSize: 12 }
                    Text {
                        text: stateManager ? stateManager.strings.audio_processing : "Procesamiento"
                        font.pixelSize: 11
                        font.bold: true
                        color: procArea.containsMouse ? "#CBA158" : "#E0E0E0"
                    }
                }

                MouseArea {
                    id: procArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (stateManager) stateManager.openAudioProcessing();
                    }
                }
            }
        }

        // Submix Information Banner
        Rectangle {
            visible: !stateManager || !stateManager.isStreamerX
            Layout.fillWidth: true
            height: 38
            radius: 8
            color: (stateManager && stateManager.activeMixTarget === "headphones") ? "#241F14" : "#1C1C20"
            border.color: (stateManager && stateManager.activeMixTarget === "headphones") ? "#5C4818" : "#2C2C32"
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 10

                Text {
                    text: (stateManager && stateManager.activeMixTarget === "headphones")
                          ? (stateManager ? stateManager.strings.submix_banner_hp : "🎧 Submezcla de Auriculares: Ajusta tu volumen personal de monitoreo sin alterar la transmisión en vivo.")
                          : (stateManager ? stateManager.strings.submix_banner_main : "🔴 Mezcla de Transmisión en Vivo: Ajustando el audio que escucha la audiencia y graba el master.")
                    font.pixelSize: 11
                    color: (stateManager && stateManager.activeMixTarget === "headphones") ? "#E5BE6C" : "#A0A0A5"
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                // Headphone output selector (HP1 / HP2 on Duo, HP1-4 on Pro II)
                Row {
                    visible: stateManager && stateManager.activeMixTarget === "headphones" && stateManager.headphoneBusCount > 1
                    spacing: 4

                    Repeater {
                        model: stateManager ? stateManager.headphoneBusCount : 0

                        Rectangle {
                            property bool active: stateManager && stateManager.headphoneBus === index
                            width: 46
                            height: 24
                            radius: 5
                            color: active ? "#CBA158" : "#2E2618"
                            border.color: "#CBA158"
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "🎧 " + (index + 1)
                                font.pixelSize: 10
                                font.bold: true
                                color: parent.active ? "#1A1A1D" : "#CBA158"
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (stateManager) stateManager.setHeadphoneBus(index)
                            }
                        }
                    }
                }

                // Reset Submix button (only visible in headphones mode)
                Rectangle {
                    visible: stateManager && stateManager.activeMixTarget === "headphones"
                    width: 160
                    height: 24
                    radius: 5
                    color: resetSubmixArea.containsMouse ? "#3A301E" : "#2E2618"
                    border.color: "#CBA158"
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 4

                        Text { text: "🔄"; font.pixelSize: 10 }
                        Text {
                            text: stateManager ? stateManager.strings.reset_submix : "Restablecer a Principal"
                            font.pixelSize: 10
                            font.bold: true
                            color: "#CBA158"
                        }
                    }

                    MouseArea {
                        id: resetSubmixArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (stateManager) stateManager.resetSubmix();
                        }
                    }
                }
            }
        }

        // Live Fader Channels Strip (Top Card)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: (stateManager && stateManager.faders.length > 6) ? 415 : 375
            radius: 12
            color: "#1A1A1D"
            border.color: (stateManager && stateManager.activeMixTarget === "headphones") ? "#44381C" : "#2C2C32"
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: (stateManager && stateManager.faders.length > 6) ? 12 : 16
                spacing: 8

                // Row of Fader Channel Strips
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: (stateManager && stateManager.faders.length > 6) ? 8 : 14

                    Repeater {
                        model: stateManager ? stateManager.faders : []

                        // Single Fader Strip
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 10
                            color: root.selectedChannelIndex === modelData.index 
                                   ? ((stateManager && stateManager.activeMixTarget === "headphones") ? "#302B1E" : "#282830")
                                   : "#222226"
                            border.color: modelData.mute ? "#FF3B30" : ((!stateManager || !stateManager.isStreamerX) && modelData.listen ? "#34C759" : (root.selectedChannelIndex === modelData.index ? "#CBA158" : "#303036"))
                            border.width: (root.selectedChannelIndex === modelData.index || modelData.mute || ((!stateManager || !stateManager.isStreamerX) && modelData.listen)) ? 2 : 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: (stateManager && stateManager.faders.length > 6) ? 8 : 10
                                spacing: 6

                                // Channel Label & Color Pill (Clickable to select channel)
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    Rectangle {
                                        width: 8
                                        height: 8
                                        radius: 4
                                        color: modelData.color || "#CBA158"
                                    }

                                    Text {
                                        text: modelData.name || ((stateManager && stateManager.language === "en" ? "Channel " : "Canal ") + (index + 1))
                                        font.pixelSize: (stateManager && stateManager.faders.length > 6) ? 10 : 12
                                        font.bold: true
                                        color: root.selectedChannelIndex === modelData.index ? "#CBA158" : "#FFFFFF"
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }

                                // Level readout (dB / %) & Type Badge (FÍSICO vs VIRTUAL / SUBMIX)
                                RowLayout {
                                    Layout.alignment: Qt.AlignHCenter
                                    spacing: 4

                                    Text {
                                        text: Math.round(modelData.level) + "%"
                                        font.pixelSize: (stateManager && stateManager.faders.length > 6) ? 11 : 12
                                        font.bold: true
                                        color: (stateManager && stateManager.activeMixTarget === "headphones") ? "#E5BE6C" : "#CBA158"
                                    }

                                    Rectangle {
                                        width: modelData.is_virtual ? 38 : 34
                                        height: 14
                                        radius: 3
                                        color: modelData.is_virtual ? "#2D2616" : "#242428"
                                        border.color: modelData.is_virtual ? "#CBA158" : "#44444C"
                                        border.width: 1

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.is_virtual ? "VIRT" : (stateManager && stateManager.language === "en" ? "PHYS" : "FÍS")
                                            font.pixelSize: 8
                                            font.bold: true
                                            color: modelData.is_virtual ? "#CBA158" : "#8E8E93"
                                        }
                                    }
                                }

                                // Interactive Vertical Level Slider
                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    Slider {
                                        id: faderSlider
                                        anchors.centerIn: parent
                                        height: parent.height - 4
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
                                            implicitHeight: 120
                                            width: 6
                                            height: faderSlider.availableHeight
                                            radius: 3
                                            color: "#151517"

                                            Rectangle {
                                                anchors.bottom: parent.bottom
                                                width: parent.width
                                                height: (faderSlider.value / 100.0) * parent.height
                                                color: (stateManager && stateManager.activeMixTarget === "headphones") 
                                                       ? (modelData.submix_linked ? "#CBA158" : "#3C96FF")
                                                       : (modelData.color || "#CBA158")
                                                radius: 3
                                            }
                                        }

                                        handle: Rectangle {
                                            x: faderSlider.leftPadding + faderSlider.availableWidth / 2 - width / 2
                                            y: faderSlider.topPadding + faderSlider.visualPosition * (faderSlider.availableHeight - height)
                                            implicitWidth: (stateManager && stateManager.faders.length > 6) ? 22 : 26
                                            implicitHeight: 14
                                            radius: 3
                                            color: (stateManager && stateManager.activeMixTarget === "headphones") ? "#FFE8B0" : "#E5E5EA"
                                            border.color: (stateManager && stateManager.activeMixTarget === "headphones") ? "#CBA158" : "#8E8E93"
                                            border.width: 1
                                        }
                                    }
                                }

                                // Submix Link status pill (in headphones mode: indicates if linked or custom)
                                Rectangle {
                                    visible: stateManager && stateManager.activeMixTarget === "headphones"
                                    Layout.fillWidth: true
                                    height: 18
                                    radius: 4
                                    color: modelData.submix_linked ? "#1E2A1E" : "#282316"
                                    border.color: modelData.submix_linked ? "#28C850" : "#CBA158"
                                    border.width: 1

                                    RowLayout {
                                        anchors.centerIn: parent
                                        spacing: 2
                                        Text {
                                            text: modelData.submix_linked ? "🔗" : "🔓"
                                            font.pixelSize: 8
                                        }
                                        Text {
                                            text: modelData.submix_linked ? "Stream" : ("Live " + modelData.main_level + "%")
                                            font.pixelSize: 8
                                            font.bold: true
                                            color: modelData.submix_linked ? "#28C850" : "#CBA158"
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (stateManager) stateManager.toggleSubmixLink(modelData.index);
                                        }
                                    }
                                }

                                // Mute & Listen Buttons (Vertical stack for 9 faders, row for 6)
                                ColumnLayout {
                                    visible: stateManager && stateManager.faders.length > 6
                                    Layout.fillWidth: true
                                    spacing: 4

                                    Rectangle {
                                        visible: !stateManager || !stateManager.isStreamerX
                                        Layout.fillWidth: true
                                        height: 22
                                        radius: 5
                                        color: modelData.listen ? "#34C759" : "#26262B"
                                        border.color: modelData.listen ? "#30D158" : "#36363E"
                                        border.width: 1

                                        Text {
                                            anchors.centerIn: parent
                                            text: "LISTEN"
                                            font.pixelSize: 9
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

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 22
                                        radius: 5
                                        color: modelData.mute ? "#FF3B30" : "#26262B"
                                        border.color: modelData.mute ? "#FF453A" : "#36363E"
                                        border.width: 1

                                        Text {
                                            anchors.centerIn: parent
                                            text: "MUTE"
                                            font.pixelSize: 9
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
                                }

                                RowLayout {
                                    visible: !stateManager || stateManager.faders.length <= 6
                                    Layout.fillWidth: true
                                    spacing: 6

                                    Rectangle {
                                        visible: !stateManager || !stateManager.isStreamerX
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
                    visible: !(stateManager && stateManager.isStreamerX)
                    text: (stateManager && stateManager.language === "en" ? "Click a source to assign it to " : "Haz clic en una fuente para asignarla al ") + (stateManager && stateManager.faders[root.selectedChannelIndex] ? stateManager.faders[root.selectedChannelIndex].name : (stateManager && stateManager.language === "en" ? "Channel " : "Canal ") + (root.selectedChannelIndex + 1))
                    font.pixelSize: 11
                    color: "#CBA158"
                }
            }

            // Streamer X: every channel strip is hard-wired to one physical/USB input
            // (Mic, Headset, Wireless, USB 1, USB 2, HDMI, SMART Pads) and the unit has
            // no Bluetooth, so source reassignment does not apply.
            Text {
                visible: Boolean(stateManager && stateManager.isStreamerX)
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                font.pixelSize: 12
                color: "#8E8E93"
                text: stateManager && stateManager.language === "en"
                      ? "On the Streamer X each fader is fixed to its own input (Mic, Headset, USB 1, USB 2 / Chat, SMART Pads and HDMI). The hardware does not allow reassigning sources and it has no Bluetooth."
                      : "En la Streamer X cada fader está fijo a su entrada (Micrófono, Headset, USB 1, USB 2 / Chat, SMART Pads y HDMI). El hardware no permite reasignar fuentes y no tiene Bluetooth."
            }

            GridLayout {
                visible: !(stateManager && stateManager.isStreamerX)
                Layout.fillWidth: true
                columns: 4
                rowSpacing: 10
                columnSpacing: 10

                Repeater {
                    model: [
                        {"id": 0, "name": "Input 1 (Mic / Inst)", "desc": "Neutrik Combo XLR", "icon": "🎙️", "tag": "+48V"},
                        {"id": 1, "name": "Input 2 (Mic / Inst)", "desc": "Neutrik Combo XLR", "icon": "🎙️", "tag": "+48V"},
                        {"id": 2, "name": (stateManager && stateManager.isDuo ? "Wireless 1" : "Input 3 (Mic 3)"), "desc": (stateManager && stateManager.isDuo ? (stateManager.language === "en" ? "Dual 2.4 GHz receiver" : "Receptor 2.4 GHz dual") : "Neutrik Combo XLR"), "icon": (stateManager && stateManager.isDuo ? "📡" : "🎙️"), "tag": (stateManager && stateManager.isDuo ? "" : "+48V")},
                        {"id": 3, "name": (stateManager && stateManager.isDuo ? "Wireless 2" : "Input 4 (Mic 4)"), "desc": (stateManager && stateManager.isDuo ? (stateManager.language === "en" ? "Dual 2.4 GHz receiver" : "Receptor 2.4 GHz dual") : "Neutrik Combo XLR"), "icon": (stateManager && stateManager.isDuo ? "📡" : "🎙️"), "tag": (stateManager && stateManager.isDuo ? "" : "+48V")},
                        {"id": 7, "name": "USB 1 Audio (Main)", "desc": (stateManager && stateManager.language === "en" ? "Multichannel 24-bit / 48kHz" : "Multicanal 24-bit / 48kHz"), "icon": "💻", "tag": ""},
                        {"id": 8, "name": "USB 1 Chat", "desc": (stateManager && stateManager.language === "en" ? "Automatic mix-minus" : "Mix-minus automático"), "icon": "💬", "tag": ""},
                        {"id": 9, "name": "USB 2 Audio", "desc": (stateManager && stateManager.language === "en" ? "Secondary / Smartphone" : "Secundario / Smartphone"), "icon": "📱", "tag": ""},
                        {"id": 10, "name": "Bluetooth Stereo", "desc": (stateManager && stateManager.language === "en" ? "A2DP and voice calls" : "A2DP y llamadas de voz"), "icon": "📶", "tag": ""},
                        {"id": 11, "name": "SMART Pads Audio", "desc": (stateManager && stateManager.language === "en" ? "Internal sound player" : "Reproductor interno"), "icon": "🎛️", "tag": ""},
                        {"id": 4, "name": "Headset TRRS", "desc": (stateManager && stateManager.language === "en" ? "Headset microphone" : "Micrófono de auriculares"), "icon": "🎧", "tag": ""},
                        {"id": 4294967295, "name": (stateManager && stateManager.language === "en" ? "Unassigned" : "Sin asignar"), "desc": (stateManager && stateManager.language === "en" ? "Clear channel assignment" : "Desactivar canal"), "icon": "🚫", "tag": ""}
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

