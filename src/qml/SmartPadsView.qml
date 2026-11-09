import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Dialogs

Item {
    id: root

    property var selectedPad: stateManager ? stateManager.selectedPad : ({})
    property int activeCategory: (root.selectedPad && root.selectedPad.type === "fx") ? 1 : ((root.selectedPad && root.selectedPad.type === "mixer") ? 2 : ((root.selectedPad && root.selectedPad.type === "midi") ? 3 : 0))
    property int fxTargetChannel: (root.selectedPad && root.selectedPad.fx_channel !== undefined) ? root.selectedPad.fx_channel : 0
    property int fxTriggerMode: (root.selectedPad && root.selectedPad.fx_mode !== undefined) ? root.selectedPad.fx_mode : 1

    FileDialog {
        id: fileDialog
        title: stateManager ? stateManager.strings.sound_dialog_title : "Seleccionar archivo de sonido para el Pad"
        nameFilters: (stateManager && stateManager.isStreamerX)
            ? ["Archivos de audio Streamer X (*.wav *.mp3)", "Todos los archivos (*)"]
            : [stateManager ? stateManager.strings.audio_files_filter : "Archivos de audio (*.wav *.mp3 *.ogg *.flac *.aac)", stateManager ? stateManager.strings.all_files_filter : "Todos los archivos (*)"]
        onAccepted: {
            if (stateManager && selectedFile) {
                stateManager.uploadSoundFile(selectedFile.toString(), "");
            }
        }
    }

    FileDialog {
        id: exportFileDialog
        title: stateManager ? stateManager.strings.export_dialog_title : "Guardar Audio Exportado"
        fileMode: FileDialog.SaveFile
        defaultSuffix: (root.selectedPad && root.selectedPad.file && root.selectedPad.file.endsWith(".mp3")) ? "mp3" : "wav"
        nameFilters: [stateManager ? stateManager.strings.audio_files_filter : "Archivos de audio (*.wav *.mp3)", stateManager ? stateManager.strings.all_files_filter : "Todos los archivos (*)"]
        onAccepted: {
            if (stateManager && selectedFile) {
                stateManager.exportCurrentPad(selectedFile.toString());
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // LEFT / CENTER AREA: Pad Configuration and Controls
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // Header Section
            Rectangle {
                Layout.fillWidth: true
                height: 52
                color: "#18181A"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 24
                    anchors.rightMargin: 24

                    Row {
                        spacing: 10
                        Layout.alignment: Qt.AlignVCenter

                        FlatIcon {
                            name: "sound_wave"
                            implicitWidth: 20
                            implicitHeight: 20
                            color: "#CBA158"
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: stateManager ? stateManager.strings.customize_smart_pads : "Personalizar SMART Pads"
                            font.pixelSize: 14
                            font.bold: true
                            color: "#FFFFFF"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Pad Identifier Badge
                    Rectangle {
                        height: 26
                        width: padLabel.implicitWidth + 20
                        radius: 13
                        color: "#28282D"
                        border.color: root.selectedPad && root.selectedPad.color_hex ? root.selectedPad.color_hex : "#CBA158"
                        border.width: 1

                        Text {
                            id: padLabel
                            anchors.centerIn: parent
                            text: (stateManager ? stateManager.strings.pad : "Pad") + " " + (stateManager ? (stateManager.selectedPadIndex + 1) : 1) + " (" + (stateManager ? stateManager.strings.bank : "Banco") + " " + (stateManager ? stateManager.currentBankDisplay : 1) + ")"
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            color: "#FFFFFF"
                        }
                    }
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: "#252528"
                }
            }

            // Category Tab Strip (Sound | FX Effects | Mixer | MIDI)
            Rectangle {
                Layout.fillWidth: true
                height: 44
                color: "#151518"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 24
                    anchors.rightMargin: 24
                    spacing: 8

                    Row {
                        spacing: 6
                        Repeater {
                            model: [
                                {"id": "sound", "name": stateManager ? stateManager.strings.tab_sound : "Sonido", "icon": "tab_sound"},
                                {"id": "fx", "name": stateManager ? stateManager.strings.tab_fx : "Efectos FX", "icon": "tab_fx"},
                                {"id": "mixer", "name": stateManager ? stateManager.strings.tab_mixer : "Mezclador", "icon": "tab_mixer"},
                                {"id": "midi", "name": stateManager ? stateManager.strings.tab_midi : "MIDI", "icon": "tab_midi"}
                            ]

                            Rectangle {
                                width: 114
                                height: 32
                                radius: 6
                                color: root.activeCategory === index ? "#CBA158" : (catArea.containsMouse ? "#26262C" : "transparent")
                                border.color: root.activeCategory === index ? "#CBA158" : (catArea.containsMouse ? "#363640" : "transparent")
                                border.width: 1

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 7
                                    FlatIcon {
                                        anchors.verticalCenter: parent.verticalCenter
                                        name: modelData.icon
                                        implicitWidth: 14
                                        implicitHeight: 14
                                        strokeWidth: 2.0
                                        color: root.activeCategory === index ? "#121214" : (catArea.containsMouse ? "#FFFFFF" : "#B0B0B5")
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.name
                                        font.pixelSize: 11
                                        font.bold: root.activeCategory === index
                                        color: root.activeCategory === index ? "#121214" : (catArea.containsMouse ? "#FFFFFF" : "#B0B0B5")
                                    }
                                }

                                MouseArea {
                                    id: catArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.activeCategory = index;
                                        if (stateManager) stateManager.updatePadType(modelData.id);
                                    }
                                }
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: "#222226"
                }
            }

            // Main Editor Body (Flickable ScrollView for responsive sizing)
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                topPadding: 32
                bottomPadding: 24

                // TAB 0: SOUND
                ColumnLayout {
                    width: root.width - 320 - 48
                    anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
                    spacing: 20
                    visible: root.activeCategory === 0

                    // Three Main Sound Actions Box
                    Rectangle {
                        Layout.fillWidth: true
                        height: 110
                        radius: 10
                        color: "#202023"
                        border.color: "#2E2E33"

                        RowLayout {
                            anchors.fill: parent
                            spacing: 0

                            // 1. Choose File
                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 8

                                    FlatIcon {
                                        Layout.alignment: Qt.AlignHCenter
                                        name: "folder"
                                        implicitWidth: 26
                                        implicitHeight: 26
                                        color: actArea1.containsMouse ? "#CBA158" : "#C8C8CC"
                                    }
                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: stateManager ? stateManager.strings.choose_file : "Elegir Archivo"
                                        font.pixelSize: 11
                                        font.weight: Font.Medium
                                        color: actArea1.containsMouse ? "#FFFFFF" : "#C8C8CC"
                                    }
                                }

                                MouseArea {
                                    id: actArea1
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: fileDialog.open()
                                }
                            }

                            Rectangle { width: 1; height: 60; color: "#2E2E33"; Layout.alignment: Qt.AlignVCenter }

                            // 2. Drag & Drop
                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 8

                                    FlatIcon {
                                        Layout.alignment: Qt.AlignHCenter
                                        name: "drag_drop"
                                        implicitWidth: 26
                                        implicitHeight: 26
                                        color: dropArea.containsDrag ? "#CBA158" : "#C8C8CC"
                                    }
                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: stateManager ? stateManager.strings.drag_drop : "Arrastrar y Soltar"
                                        font.pixelSize: 11
                                        font.weight: Font.Medium
                                        color: dropArea.containsDrag ? "#CBA158" : "#C8C8CC"
                                    }
                                }

                                DropArea {
                                    id: dropArea
                                    anchors.fill: parent
                                    onDropped: (drop) => {
                                        if (drop.hasUrls && drop.urls.length > 0) {
                                            stateManager.uploadSoundFile(drop.urls[0].toString(), "");
                                        }
                                    }
                                }
                            }

                            Rectangle { width: 1; height: 60; color: "#2E2E33"; Layout.alignment: Qt.AlignVCenter }

                            // 3. Export
                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                readonly property bool hasAudio: Boolean(root.selectedPad && root.selectedPad.file && root.selectedPad.type !== "empty")

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 8

                                    FlatIcon {
                                        Layout.alignment: Qt.AlignHCenter
                                        name: "export"
                                        implicitWidth: 26
                                        implicitHeight: 26
                                        color: parent.parent.hasAudio ? (actArea3.containsMouse ? "#CBA158" : "#C8C8CC") : "#55555A"
                                    }
                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: stateManager ? stateManager.strings.export_audio : "Exportar Audio"
                                        font.pixelSize: 11
                                        font.weight: Font.Medium
                                        color: parent.parent.hasAudio ? (actArea3.containsMouse ? "#FFFFFF" : "#C8C8CC") : "#55555A"
                                    }
                                }

                                MouseArea {
                                    id: actArea3
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: parent.hasAudio ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onClicked: {
                                        if (!parent.hasAudio) {
                                            if (stateManager) stateManager.toastMessage(stateManager.strings.no_audio_export);
                                            return;
                                        }
                                        let padName = (root.selectedPad && root.selectedPad.name) ? root.selectedPad.name.replace(/[^a-zA-Z0-9_-]/g, "_") : "pad_audio";
                                        let ext = (root.selectedPad && root.selectedPad.file && root.selectedPad.file.endsWith(".mp3")) ? ".mp3" : ".wav";
                                        exportFileDialog.currentFile = "file://" + padName + ext;
                                        exportFileDialog.open();
                                    }
                                }
                            }
                        }
                    }

                    // Official RØDE Factory Sounds Picker
                    Rectangle {
                        Layout.fillWidth: true
                        height: factoryCol.height + 24
                        radius: 10
                        color: "#1C1C1F"
                        border.color: "#2C2C32"
                        border.width: 1

                        ColumnLayout {
                            id: factoryCol
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 14
                            spacing: 10

                            RowLayout {
                                spacing: 8
                                FlatIcon {
                                    name: "speaker"
                                    implicitWidth: 14
                                    implicitHeight: 14
                                    color: "#CBA158"
                                }
                                Text {
                                    text: stateManager ? stateManager.strings.factory_sounds : "Sonidos de Fábrica"
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: "#FFFFFF"
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: stateManager ? stateManager.strings.load_factory_sound : "Cargar sonido oficial RØDE"
                                    font.pixelSize: 10
                                    color: "#8E8E93"
                                }
                            }

                            GridLayout {
                                Layout.fillWidth: true
                                columns: 4
                                rowSpacing: 6
                                columnSpacing: 6

                                Repeater {
                                    model: stateManager ? stateManager.factorySounds : []

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 30
                                        radius: 6
                                        color: factArea.containsMouse ? "#32323A" : "#242428"
                                        border.color: factArea.containsMouse ? "#CBA158" : "#323238"
                                        border.width: 1

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.name
                                            font.pixelSize: 10
                                            font.weight: Font.Medium
                                            color: factArea.containsMouse ? "#FFFFFF" : "#D0D0D5"
                                        }

                                        MouseArea {
                                            id: factArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (stateManager) stateManager.loadFactorySound(modelData.id);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Playback options (Toggle, Loop, Replay)
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 40

                        // Mode (Toggle / One Shot / Hold)
                        ColumnLayout {
                            spacing: 6
                            Layout.alignment: Qt.AlignHCenter

                            Rectangle {
                                width: 44
                                height: 44
                                radius: 22
                                color: modeArea.containsMouse ? "#2C2C32" : "#222226"
                                border.color: modeArea.containsMouse ? "#44444D" : "#323238"
                                border.width: 1
                                Layout.alignment: Qt.AlignHCenter

                                FlatIcon {
                                    anchors.centerIn: parent
                                    name: {
                                        let m = (root.selectedPad && root.selectedPad.mode !== undefined) ? root.selectedPad.mode : "toggle";
                                        return (m === "oneshot") ? "oneshot" : ((m === "hold") ? "hold" : "toggle");
                                    }
                                    implicitWidth: 20
                                    implicitHeight: 20
                                    color: "#FFFFFF"
                                }

                                MouseArea {
                                    id: modeArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        let current = (root.selectedPad && root.selectedPad.mode !== undefined) ? root.selectedPad.mode : "toggle";
                                        let next = (current === "toggle") ? "oneshot" : ((current === "oneshot") ? "hold" : "toggle");
                                        stateManager.updatePadPlayMode(next);
                                    }
                                }
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: {
                                    let m = (root.selectedPad && root.selectedPad.mode !== undefined) ? root.selectedPad.mode : "toggle";
                                    return (m === "oneshot") ? (stateManager ? stateManager.strings.mode_oneshot : "One Shot") : ((m === "hold") ? (stateManager ? stateManager.strings.mode_hold : "Hold") : (stateManager ? stateManager.strings.mode_toggle : "Toggle"));
                                }
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                color: "#FFFFFF"
                            }
                        }

                        // Loop (Loop Off / On)
                        ColumnLayout {
                            spacing: 6
                            Layout.alignment: Qt.AlignHCenter

                            Rectangle {
                                width: 44
                                height: 44
                                radius: 22
                                color: root.selectedPad && root.selectedPad.loop ? "#2C271E" : (loopArea.containsMouse ? "#2C2C32" : "#222226")
                                border.color: root.selectedPad && root.selectedPad.loop ? "#CBA158" : (loopArea.containsMouse ? "#44444D" : "#323238")
                                border.width: 1
                                Layout.alignment: Qt.AlignHCenter

                                FlatIcon {
                                    anchors.centerIn: parent
                                    name: root.selectedPad && root.selectedPad.loop ? "loop_on" : "loop_off"
                                    implicitWidth: 20
                                    implicitHeight: 20
                                    color: root.selectedPad && root.selectedPad.loop ? "#CBA158" : "#8E8E93"
                                }

                                MouseArea {
                                    id: loopArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        let current = (root.selectedPad && root.selectedPad.loop !== undefined) ? root.selectedPad.loop : false;
                                        stateManager.updatePadLoop(!current);
                                    }
                                }
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: root.selectedPad && root.selectedPad.loop ? (stateManager ? stateManager.strings.loop_on : "Loop On") : (stateManager ? stateManager.strings.loop_off : "Loop Off")
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                color: root.selectedPad && root.selectedPad.loop ? "#CBA158" : "#8E8E93"
                            }
                        }

                        // Replay
                        ColumnLayout {
                            spacing: 6
                            Layout.alignment: Qt.AlignHCenter

                            Rectangle {
                                width: 44
                                height: 44
                                radius: 22
                                color: root.selectedPad && root.selectedPad.replay ? "#2C271E" : (replayArea.containsMouse ? "#2C2C32" : "#222226")
                                border.color: root.selectedPad && root.selectedPad.replay ? "#CBA158" : (replayArea.containsMouse ? "#44444D" : "#323238")
                                border.width: 1
                                Layout.alignment: Qt.AlignHCenter

                                FlatIcon {
                                    anchors.centerIn: parent
                                    name: "replay"
                                    implicitWidth: 20
                                    implicitHeight: 20
                                    color: root.selectedPad && root.selectedPad.replay ? "#CBA158" : "#8E8E93"
                                }

                                MouseArea {
                                    id: replayArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        let current = (root.selectedPad && root.selectedPad.replay !== undefined) ? root.selectedPad.replay : false;
                                        stateManager.updatePadReplay(!current);
                                    }
                                }
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: stateManager ? stateManager.strings.replay : "Replay"
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                color: root.selectedPad && root.selectedPad.replay ? "#CBA158" : "#8E8E93"
                            }
                        }
                    }

                    // Gain Level Slider
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 14

                        Text {
                            text: stateManager ? stateManager.strings.gain : "Ganancia:"
                            font.pixelSize: 12
                            color: "#8E8E93"
                        }

                        Slider {
                            id: gainSlider
                            from: -12.0
                            to: 12.0
                            stepSize: 0.5
                            value: (root.selectedPad && root.selectedPad.gain !== undefined) ? root.selectedPad.gain : 0.0

                            onMoved: {
                                stateManager.updatePadGain(value);
                            }
                        }

                        Text {
                            text: (gainSlider.value > 0 ? "+" : "") + gainSlider.value.toFixed(1) + " dB"
                            font.pixelSize: 12
                            font.bold: true
                            color: "#CBA158"
                        }
                    }
                }

                // TAB 1: FX EFFECTS
                ColumnLayout {
                    width: root.width - 320 - 48
                    anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
                    spacing: 16
                    visible: root.activeCategory === 1

                    // Target Channel & Trigger Mode Selectors
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: controlsLayout.implicitHeight + 24
                        radius: 8
                        color: "#1C1C1F"
                        border.color: "#2C2C32"

                        Flow {
                            id: controlsLayout
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 12
                            spacing: 24

                            // Target Channel Card / Selector
                            RowLayout {
                                spacing: 10

                                Text {
                                    text: "Canal Destino:"
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: "#FFFFFF"
                                }

                                Rectangle {
                                    height: 32
                                    radius: 6
                                    color: "#26262C"
                                    implicitWidth: (stateManager && stateManager.isStreamerX) ? 96 : 140

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 3
                                        spacing: 3

                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            radius: 4
                                            color: root.fxTargetChannel === 0 ? "#CBA158" : "transparent"
                                            Text {
                                                anchors.centerIn: parent
                                                text: (stateManager && stateManager.isStreamerX) ? "Micrófono" : "Mic 1"
                                                font.pixelSize: 11
                                                font.bold: root.fxTargetChannel === 0
                                                color: root.fxTargetChannel === 0 ? "#121214" : "#D0D0D0"
                                            }
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.fxTargetChannel = 0
                                            }
                                        }

                                        Rectangle {
                                            visible: !(stateManager && stateManager.isStreamerX)
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            radius: 4
                                            color: root.fxTargetChannel === 1 ? "#CBA158" : "transparent"
                                            Text {
                                                anchors.centerIn: parent
                                                text: "Mic 2"
                                                font.pixelSize: 11
                                                font.bold: root.fxTargetChannel === 1
                                                color: root.fxTargetChannel === 1 ? "#121214" : "#D0D0D0"
                                            }
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.fxTargetChannel = 1
                                            }
                                        }
                                    }
                                }
                            }

                            // Trigger Mode (Latch vs Hold)
                            RowLayout {
                                spacing: 10

                                Text {
                                    text: "Comportamiento:"
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: "#FFFFFF"
                                }

                                Rectangle {
                                    height: 32
                                    radius: 6
                                    color: "#26262C"
                                    implicitWidth: 140

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 3
                                        spacing: 3

                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            radius: 4
                                            color: root.fxTriggerMode === 1 ? "#CBA158" : "transparent"
                                            Text {
                                                anchors.centerIn: parent
                                                text: "Latch"
                                                font.pixelSize: 11
                                                font.bold: root.fxTriggerMode === 1
                                                color: root.fxTriggerMode === 1 ? "#121214" : "#D0D0D0"
                                            }
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.fxTriggerMode = 1
                                            }
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            radius: 4
                                            color: root.fxTriggerMode === 0 ? "#CBA158" : "transparent"
                                            Text {
                                                anchors.centerIn: parent
                                                text: "Hold"
                                                font.pixelSize: 11
                                                font.bold: root.fxTriggerMode === 0
                                                color: root.fxTriggerMode === 0 ? "#121214" : "#D0D0D0"
                                            }
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.fxTriggerMode = 0
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // FX Grid Cards (Native RØDECaster Voice FX Presets)
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        rowSpacing: 10
                        columnSpacing: 10

                        Repeater {
                            model: [
                                {"id": 8, "name": "Voice Disguise", "desc": "Tono anónimo profundo / Pitch bajo", "icon": "🎭"},
                                {"id": 9, "name": "Megaphone", "desc": "Filtro paso banda radio / megáfono", "icon": "📢"},
                                {"id": 10, "name": "Large Robot", "desc": "Sintetizador vocoder robótico", "icon": "🤖"},
                                {"id": 12, "name": "Pitch Shift", "desc": "Transporte tonal agudo (Pitch Up)", "icon": "🎼"},
                                {"id": 13, "name": "Monster", "desc": "Voz gutural oscura y pesada", "icon": "👹"},
                                {"id": 14, "name": "Small Robot", "desc": "Vocoder electrónico sintetizado", "icon": "🦾"}
                            ]

                            Rectangle {
                                Layout.fillWidth: true
                                height: 68
                                radius: 8
                                color: fxCardArea.containsMouse ? "#2A2A30" : ((root.selectedPad && root.selectedPad.fx_id === modelData.id && root.selectedPad.type === "fx") ? "#2D2820" : "#202024")
                                border.color: (root.selectedPad && root.selectedPad.fx_id === modelData.id && root.selectedPad.type === "fx") ? "#CBA158" : (fxCardArea.containsMouse ? "#CBA158" : "#2E2E36")
                                border.width: (root.selectedPad && root.selectedPad.fx_id === modelData.id && root.selectedPad.type === "fx") ? 2 : 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 12

                                    Text { text: modelData.icon; font.pixelSize: 22 }
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text { text: modelData.name; font.pixelSize: 13; font.bold: true; color: "#FFFFFF" }
                                        Text {
                                            text: modelData.desc
                                            font.pixelSize: 10
                                            color: "#8E8E93"
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                    }
                                    Rectangle {
                                        visible: root.selectedPad && root.selectedPad.fx_id === modelData.id && root.selectedPad.type === "fx"
                                        implicitWidth: asigText.implicitWidth + 12
                                        implicitHeight: 22
                                        radius: 4
                                        color: "#352A18"
                                        border.color: "#CBA158"
                                        border.width: 1

                                        Text {
                                            id: asigText
                                            anchors.centerIn: parent
                                            text: "✓ Asignado"
                                            font.pixelSize: 10
                                            font.bold: true
                                            color: "#CBA158"
                                        }
                                    }
                                }

                                MouseArea {
                                    id: fxCardArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (stateManager) {
                                            stateManager.assignPadEffect(modelData.id, modelData.name, root.fxTargetChannel, root.fxTriggerMode);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // TAB 2: MIXER
                ColumnLayout {
                    width: root.width - 320 - 48
                    anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
                    spacing: 16
                    visible: root.activeCategory === 2

                    Repeater {
                        model: [
                            {"name": "Censor Bleep", "desc": "Emite un pitido de censura de 1 kHz y silencia los micrófonos seleccionados", "icon": "🔇"},
                            {"name": "Trash Talk", "desc": "Silencia los micrófonos hacia los oyentes pero los mantiene en los auriculares", "icon": "🗣️"},
                            {"name": "Ducking", "desc": "Atenúa la música de fondo automáticamente mientras este pad está pulsado", "icon": "📉"}
                        ]

                        Rectangle {
                            Layout.fillWidth: true
                            height: 76
                            radius: 10
                            color: mixCardArea.containsMouse ? "#2A2A30" : "#202024"
                            border.color: mixCardArea.containsMouse ? "#CBA158" : "#2E2E36"
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 14

                                Text { text: modelData.icon; font.pixelSize: 26 }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4
                                    Text { text: modelData.name; font.pixelSize: 14; font.bold: true; color: "#FFFFFF" }
                                    Text { text: modelData.desc; font.pixelSize: 11; color: "#9A9A9E"; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                                }
                            }

                            MouseArea {
                                id: mixCardArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (stateManager) stateManager.updatePadName(modelData.name);
                                }
                            }
                        }
                    }
                }

                // TAB 3: MIDI
                ColumnLayout {
                    width: root.width - 320 - 48
                    anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
                    spacing: 16
                    visible: root.activeCategory === 3

                    Rectangle {
                        Layout.fillWidth: true
                        height: midiCol.height + 28
                        radius: 10
                        color: "#202024"
                        border.color: "#2E2E36"
                        border.width: 1

                        ColumnLayout {
                            id: midiCol
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 14
                            spacing: 14

                            Text { text: "Comando MIDI USB"; font.pixelSize: 14; font.bold: true; color: "#FFFFFF" }

                            RowLayout {
                                Text { text: "Tipo de Mensaje:"; font.pixelSize: 12; color: "#8E8E93"; Layout.preferredWidth: 140 }
                                Row {
                                    spacing: 8
                                    Rectangle { width: 90; height: 30; radius: 6; color: "#CBA158"; Text { anchors.centerIn: parent; text: "Control (CC)"; font.pixelSize: 11; font.bold: true; color: "#121214" } }
                                    Rectangle { width: 90; height: 30; radius: 6; color: "#28282E"; Text { anchors.centerIn: parent; text: "Nota (Note)"; font.pixelSize: 11; color: "#D0D0D0" } }
                                }
                            }

                            RowLayout {
                                Text { text: "Canal MIDI (1-16):"; font.pixelSize: 12; color: "#8E8E93"; Layout.preferredWidth: 140 }
                                Text { text: "Canal 1"; font.pixelSize: 12; font.bold: true; color: "#FFFFFF" }
                            }

                            RowLayout {
                                Text { text: "Control / Nota:"; font.pixelSize: 12; color: "#8E8E93"; Layout.preferredWidth: 140 }
                                Text { text: "#" + (stateManager ? (stateManager.selectedPadIndex + 1) : 1); font.pixelSize: 12; font.bold: true; color: "#CBA158" }
                            }
                        }
                    }
                }
            }
        }

        // RIGHT PANEL: Pad Matrix & Quick Adjustments
        Rectangle {
            Layout.preferredWidth: 320
            Layout.fillHeight: true
            color: "#18181A"

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 1
                color: "#252528"
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16

                // Pad Name Header & Edit Icon
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    TextField {
                        id: nameField
                        Layout.fillWidth: true
                        text: (root.selectedPad && root.selectedPad.name !== undefined) ? root.selectedPad.name : ""
                        font.pixelSize: 16
                        font.bold: true
                        color: "#FFFFFF"
                        placeholderText: stateManager ? stateManager.strings.pad_placeholder : "Nombre del Pad..."

                        background: Rectangle {
                            color: nameField.activeFocus ? "#28282D" : "transparent"
                            radius: 4
                            border.color: nameField.activeFocus ? "#CBA158" : "transparent"
                        }

                        onEditingFinished: {
                            stateManager.updatePadName(text);
                        }
                    }

                    FlatIcon {
                        name: "pencil"
                        implicitWidth: 16
                        implicitHeight: 16
                        color: "#8E8E93"
                    }
                }

                // Color Slider & Eraser
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    ColorSlider {
                        Layout.fillWidth: true
                        selectedIndex: (root.selectedPad && root.selectedPad.color_idx !== undefined) ? root.selectedPad.color_idx : 0
                        onColorSelected: (idx) => {
                            stateManager.updatePadColor(idx);
                        }
                    }

                    // Clear pad icon
                    Rectangle {
                        width: 30
                        height: 30
                        radius: 6
                        color: clearArea.containsMouse ? "#3A2A2A" : "transparent"

                        FlatIcon {
                            anchors.centerIn: parent
                            name: "eraser"
                            implicitWidth: 18
                            implicitHeight: 18
                            color: clearArea.containsMouse ? "#FF6666" : "#8E8E93"
                        }

                        MouseArea {
                            id: clearArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: stateManager.clearCurrentPad()
                        }
                    }
                }

                Item { height: 6 }

                // The Pad Matrix (Duo 2x3, Pro II 2x4, Streamer X 2x2)
                PadGrid {
                    Layout.alignment: Qt.AlignHCenter
                }

                // Bank Navigation (< Banco 4 de 8 >) grouped directly below pads
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 16

                    Rectangle {
                        width: 28
                        height: 28
                        radius: 14
                        color: prevArea.containsMouse ? "#2E2E34" : "#202024"
                        border.color: "#303038"
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "‹"
                            font.pixelSize: 22
                            font.bold: true
                            color: prevArea.containsMouse ? "#FFFFFF" : "#8E8E93"
                        }

                        MouseArea {
                            id: prevArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: stateManager.prevBank()
                        }
                    }

                    Text {
                        text: (stateManager ? stateManager.strings.bank : "Banco") + " " + (stateManager ? stateManager.currentBankDisplay : 1) + " " + (stateManager ? stateManager.strings.of : "de") + " 8"
                        font.pixelSize: 12
                        font.bold: true
                        color: "#E0E0E0"
                    }

                    Rectangle {
                        width: 28
                        height: 28
                        radius: 14
                        color: nextArea.containsMouse ? "#2E2E34" : "#202024"
                        border.color: "#303038"
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "›"
                            font.pixelSize: 22
                            font.bold: true
                            color: nextArea.containsMouse ? "#FFFFFF" : "#8E8E93"
                        }

                        MouseArea {
                            id: nextArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: stateManager.nextBank()
                        }
                    }
                }

                Item { height: 4 }

                // Test / Trigger Button
                Button {
                    Layout.alignment: Qt.AlignHCenter
                    text: stateManager ? stateManager.strings.trigger_selected : "▶ Disparar Pad Seleccionado"
                    HoverHandler { cursorShape: Qt.PointingHandCursor }

                    contentItem: Text {
                        text: parent.text
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: "#FFFFFF"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        implicitWidth: 230
                        implicitHeight: 34
                        radius: 6
                        color: parent.down ? "#1E6B38" : (parent.hovered ? "#2D8A4E" : "#24733F")
                    }

                    onClicked: {
                        if (stateManager) stateManager.triggerPad(stateManager.selectedPadIndex);
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }
    }
}
