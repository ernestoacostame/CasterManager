import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Dialogs

Item {
    id: root

    property var selectedPad: stateManager ? stateManager.selectedPad : ({})

    FileDialog {
        id: fileDialog
        title: stateManager ? stateManager.strings.sound_dialog_title : "Seleccionar archivo de sonido para el Pad"
        nameFilters: [stateManager ? stateManager.strings.audio_files_filter : "Archivos de audio (*.wav *.mp3 *.ogg *.flac *.aac)", stateManager ? stateManager.strings.all_files_filter : "Todos los archivos (*)"]
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

            // Main Editor Body
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 34
                    width: Math.min(520, parent.width - 40)

                    // Three Main Sound Actions Box
                    Rectangle {
                        Layout.fillWidth: true
                        height: 120
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
                                        implicitWidth: 28
                                        implicitHeight: 28
                                        color: actArea1.containsMouse ? "#CBA158" : "#C8C8CC"
                                    }
                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: stateManager ? stateManager.strings.choose_file : "Elegir Archivo"
                                        font.pixelSize: 12
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

                            Rectangle { width: 1; height: 70; color: "#2E2E33"; Layout.alignment: Qt.AlignVCenter }

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
                                        implicitWidth: 28
                                        implicitHeight: 28
                                        color: dropArea.containsDrag ? "#CBA158" : "#C8C8CC"
                                    }
                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: stateManager ? stateManager.strings.drag_drop : "Arrastrar y Soltar"
                                        font.pixelSize: 12
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

                            Rectangle { width: 1; height: 70; color: "#2E2E33"; Layout.alignment: Qt.AlignVCenter }

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
                                        implicitWidth: 28
                                        implicitHeight: 28
                                        color: parent.parent.hasAudio ? (actArea3.containsMouse ? "#CBA158" : "#C8C8CC") : "#55555A"
                                    }
                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: stateManager ? stateManager.strings.export_audio : "Exportar Audio"
                                        font.pixelSize: 12
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

                    // Playback options (Toggle, Loop, Replay) - FLAT MINIMALIST STYLE
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 48

                        // Mode (Toggle / One Shot / Hold)
                        ColumnLayout {
                            spacing: 8
                            Layout.alignment: Qt.AlignHCenter

                            Rectangle {
                                width: 50
                                height: 50
                                radius: 25
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
                                    implicitWidth: 22
                                    implicitHeight: 22
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
                                font.pixelSize: 12
                                font.weight: Font.Medium
                                color: "#FFFFFF"
                            }
                        }

                        // Loop (Loop Off / On)
                        ColumnLayout {
                            spacing: 8
                            Layout.alignment: Qt.AlignHCenter

                            Rectangle {
                                width: 50
                                height: 50
                                radius: 25
                                color: root.selectedPad && root.selectedPad.loop ? "#2C271E" : (loopArea.containsMouse ? "#2C2C32" : "#222226")
                                border.color: root.selectedPad && root.selectedPad.loop ? "#CBA158" : (loopArea.containsMouse ? "#44444D" : "#323238")
                                border.width: 1
                                Layout.alignment: Qt.AlignHCenter

                                FlatIcon {
                                    anchors.centerIn: parent
                                    name: root.selectedPad && root.selectedPad.loop ? "loop_on" : "loop_off"
                                    implicitWidth: 22
                                    implicitHeight: 22
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
                                font.pixelSize: 12
                                font.weight: Font.Medium
                                color: root.selectedPad && root.selectedPad.loop ? "#CBA158" : "#8E8E93"
                            }
                        }

                        // Replay
                        ColumnLayout {
                            spacing: 8
                            Layout.alignment: Qt.AlignHCenter

                            Rectangle {
                                width: 50
                                height: 50
                                radius: 25
                                color: root.selectedPad && root.selectedPad.replay ? "#2C271E" : (replayArea.containsMouse ? "#2C2C32" : "#222226")
                                border.color: root.selectedPad && root.selectedPad.replay ? "#CBA158" : (replayArea.containsMouse ? "#44444D" : "#323238")
                                border.width: 1
                                Layout.alignment: Qt.AlignHCenter

                                FlatIcon {
                                    anchors.centerIn: parent
                                    name: "replay"
                                    implicitWidth: 22
                                    implicitHeight: 22
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
                                font.pixelSize: 12
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

                // The Pad Matrix (Duo 2x3, Pro II 2x4)
                PadGrid {
                    Layout.alignment: Qt.AlignHCenter
                }

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

                // Bank Navigation (< 4 >)
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 18

                    Rectangle {
                        width: 32
                        height: 32
                        radius: 16
                        color: prevArea.containsMouse ? "#2E2E34" : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "‹"
                            font.pixelSize: 26
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
                        font.pixelSize: 13
                        font.bold: true
                        color: "#E0E0E0"
                    }

                    Rectangle {
                        width: 32
                        height: 32
                        radius: 16
                        color: nextArea.containsMouse ? "#2E2E34" : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "›"
                            font.pixelSize: 26
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
            }
        }
    }
}
