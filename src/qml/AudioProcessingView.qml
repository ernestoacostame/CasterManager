import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: root

    readonly property var dsp: (stateManager && stateManager.currentDsp) ? stateManager.currentDsp : ({})

    function getVal(prop, defVal) {
        if (root.dsp && root.dsp[prop] !== undefined && root.dsp[prop] !== null) {
            return root.dsp[prop];
        }
        return defVal;
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 28
        spacing: 20

        // Header Title & Channel Tabs Row
        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            ColumnLayout {
                spacing: 3
                Text {
                    text: stateManager ? stateManager.strings.audio_processing_title : "Procesamiento de Audio en Vivo"
                    font.pixelSize: 22
                    font.bold: true
                    color: "#FFFFFF"
                }
                Text {
                    text: "APHEX®, Procesamiento Dinámico, Filtros y Ecualización por Canal"
                    font.pixelSize: 12
                    color: "#8E8E93"
                }
            }

            Item { Layout.fillWidth: true }

            // Channel Selector Segmented Bar
            Rectangle {
                height: 38
                radius: 19
                color: "#16161A"
                border.color: "#2C2C32"
                border.width: 1
                implicitWidth: channelRow.implicitWidth + 8

                RowLayout {
                    id: channelRow
                    anchors.centerIn: parent
                    spacing: 4

                    Repeater {
                        model: stateManager ? stateManager.dspChannels : []

                        Rectangle {
                            height: 30
                            radius: 15
                            implicitWidth: Math.max(90, chText.implicitWidth + 24)
                            color: (stateManager && stateManager.activeDspChannel === modelData.id) ? "#CBA158" : "transparent"

                            Text {
                                id: chText
                                anchors.centerIn: parent
                                text: modelData.name
                                font.pixelSize: 12
                                font.bold: (stateManager && stateManager.activeDspChannel === modelData.id)
                                color: (stateManager && stateManager.activeDspChannel === modelData.id) ? "#121214" : "#AAAAAA"
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (stateManager) stateManager.setActiveDspChannel(modelData.id);
                                }
                            }
                        }
                    }
                }
            }
        }

        // Preamplifier / Input Gain Top Strip
        Rectangle {
            Layout.fillWidth: true
            height: 72
            radius: 12
            color: "#18181C"
            border.color: "#282830"
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                spacing: 20

                // Preamp Icon Badge
                Rectangle {
                    width: 40
                    height: 40
                    radius: 8
                    color: "#24242C"
                    border.color: "#353540"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "🎙️"
                        font.pixelSize: 18
                    }
                }

                // Preamp Label
                ColumnLayout {
                    spacing: 2
                    Text {
                        text: stateManager ? stateManager.strings.preamp : "Preamplificador / Entrada"
                        font.pixelSize: 13
                        font.bold: true
                        color: "#FFFFFF"
                    }
                    Text {
                        text: "Revolution Preamp™ Ultra-bajo ruido"
                        font.pixelSize: 11
                        color: "#8E8E93"
                    }
                }

                // Gain Slider
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Text {
                        text: stateManager ? stateManager.strings.preamp_gain : "Ganancia"
                        font.pixelSize: 12
                        color: "#AAAAAA"
                    }

                    Slider {
                        id: preampGainSlider
                        Layout.fillWidth: true
                        from: 0
                        to: 76
                        stepSize: 1
                        value: root.getVal("preamp_gain", 45)
                        onMoved: {
                            if (stateManager) stateManager.setDspParameter("preamp_gain", Math.round(value));
                        }
                    }

                    Rectangle {
                        width: 60
                        height: 28
                        radius: 6
                        color: "#24242C"
                        border.color: "#383844"
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "+" + Math.round(preampGainSlider.value) + " dB"
                            font.pixelSize: 12
                            font.bold: true
                            color: "#CBA158"
                        }
                    }
                }

                Rectangle { width: 1; height: 36; color: "#2E2E36" }

                // Phantom Power (+48V) Button
                Rectangle {
                    width: 72
                    height: 32
                    radius: 6
                    color: root.getVal("phantom_power", false) ? "#3D2418" : (p48Area.containsMouse ? "#2A2A32" : "#202026")
                    border.color: root.getVal("phantom_power", false) ? "#FF9500" : "#32323C"
                    border.width: root.getVal("phantom_power", false) ? 1.5 : 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                            text: "+48V"
                            font.pixelSize: 12
                            font.bold: true
                            color: root.getVal("phantom_power", false) ? "#FF9500" : "#8E8E93"
                        }
                    }

                    MouseArea {
                        id: p48Area
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (stateManager) {
                                let cur = Boolean(root.getVal("phantom_power", false));
                                stateManager.setDspParameter("phantom_power", !cur);
                            }
                        }
                    }
                }

                // Phase Invert (Ø) Button
                Rectangle {
                    width: 44
                    height: 32
                    radius: 6
                    color: root.getVal("phase_flip", false) ? "#2C2618" : (phaseArea.containsMouse ? "#2A2A32" : "#202026")
                    border.color: root.getVal("phase_flip", false) ? "#CBA158" : "#32323C"
                    border.width: root.getVal("phase_flip", false) ? 1.5 : 1

                    Text {
                        anchors.centerIn: parent
                        text: "Ø"
                        font.pixelSize: 14
                        font.bold: true
                        color: root.getVal("phase_flip", false) ? "#CBA158" : "#8E8E93"
                    }

                    MouseArea {
                        id: phaseArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (stateManager) {
                                let cur = Boolean(root.getVal("phase_flip", false));
                                stateManager.setDspParameter("phase_flip", !cur);
                            }
                        }
                    }
                }
            }
        }

        // Main Scroll Area for Processing Cards
        ScrollView {
            id: procScroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: availableWidth
            clip: true
            ScrollBar.vertical.policy: ScrollBar.AsNeeded

            ColumnLayout {
                width: procScroll.availableWidth
                spacing: 16

                // Row 1: APHEX® & Noise Gate Cards
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16

                    // CARD 1: APHEX® PROCESSING
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 330
                        radius: 14
                        color: "#18181C"
                        border.color: root.getVal("aphex_on", true) ? "#4A3B18" : "#282830"
                        border.width: 1

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 18
                            spacing: 12

                            // Card Header
                            RowLayout {
                                Layout.fillWidth: true

                                RowLayout {
                                    spacing: 8
                                    Text {
                                        text: "✨"
                                        font.pixelSize: 16
                                    }
                                    Text {
                                        text: "APHEX® Processing"
                                        font.pixelSize: 16
                                        font.bold: true
                                        color: root.getVal("aphex_on", true) ? "#CBA158" : "#FFFFFF"
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Switch {
                                    checked: root.getVal("aphex_on", true)
                                    onToggled: {
                                        if (stateManager) stateManager.setDspParameter("aphex_on", checked);
                                    }
                                }
                            }

                            Rectangle { Layout.fillWidth: true; height: 1; color: "#25252D" }

                            // Sliders Body (dimmed if bypassed)
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 14
                                opacity: root.getVal("aphex_on", true) ? 1.0 : 0.4
                                enabled: root.getVal("aphex_on", true)

                                // Section 1: Aural Exciter™
                                Text {
                                    text: "Aural Exciter™ (Brillo y Armónicos)"
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: "#E0E0E0"
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 12
                                    Text { text: "Mix:"; font.pixelSize: 12; color: "#8E8E93"; Layout.preferredWidth: 40 }
                                    Slider {
                                        id: aeMixSlider
                                        Layout.fillWidth: true
                                        from: 0.0; to: 1.0; stepSize: 0.01
                                        value: root.getVal("aphex_ae_mix", 0.5)
                                        onMoved: if (stateManager) stateManager.setDspParameter("aphex_ae_mix", value)
                                    }
                                    Text { text: Math.round(aeMixSlider.value * 100) + "%"; font.pixelSize: 12; font.bold: true; color: "#CBA158"; Layout.preferredWidth: 40 }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 12
                                    Text { text: "Tune:"; font.pixelSize: 12; color: "#8E8E93"; Layout.preferredWidth: 40 }
                                    Slider {
                                        id: aeTuneSlider
                                        Layout.fillWidth: true
                                        from: 0.0; to: 1.0; stepSize: 0.01
                                        value: root.getVal("aphex_ae_tune", 0.5)
                                        onMoved: if (stateManager) stateManager.setDspParameter("aphex_ae_tune", value)
                                    }
                                    Text { text: Math.round(aeTuneSlider.value * 100) + "%"; font.pixelSize: 12; font.bold: true; color: "#CBA158"; Layout.preferredWidth: 40 }
                                }

                                Rectangle { Layout.fillWidth: true; height: 1; color: "#25252D" }

                                // Section 2: Big Bottom™
                                Text {
                                    text: "Big Bottom™ (Graves y Resonancia Profunda)"
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: "#E0E0E0"
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 12
                                    Text { text: "Drive:"; font.pixelSize: 12; color: "#8E8E93"; Layout.preferredWidth: 40 }
                                    Slider {
                                        id: bbDriveSlider
                                        Layout.fillWidth: true
                                        from: 0.0; to: 1.0; stepSize: 0.01
                                        value: root.getVal("aphex_bb_drive", 0.5)
                                        onMoved: if (stateManager) stateManager.setDspParameter("aphex_bb_drive", value)
                                    }
                                    Text { text: Math.round(bbDriveSlider.value * 100) + "%"; font.pixelSize: 12; font.bold: true; color: "#CBA158"; Layout.preferredWidth: 40 }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 12
                                    Text { text: "Tune:"; font.pixelSize: 12; color: "#8E8E93"; Layout.preferredWidth: 40 }
                                    Slider {
                                        id: bbTuneSlider
                                        Layout.fillWidth: true
                                        from: 0.0; to: 1.0; stepSize: 0.01
                                        value: root.getVal("aphex_bb_tune", 0.35)
                                        onMoved: if (stateManager) stateManager.setDspParameter("aphex_bb_tune", value)
                                    }
                                    Text { text: Math.round(bbTuneSlider.value * 100) + "%"; font.pixelSize: 12; font.bold: true; color: "#CBA158"; Layout.preferredWidth: 40 }
                                }
                            }
                        }
                    }

                    // CARD 2: NOISE GATE
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 330
                        radius: 14
                        color: "#18181C"
                        border.color: root.getVal("noise_gate_on", true) ? "#4A3B18" : "#282830"
                        border.width: 1

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 18
                            spacing: 12

                            // Card Header
                            RowLayout {
                                Layout.fillWidth: true

                                RowLayout {
                                    spacing: 8
                                    Text { text: "🚪"; font.pixelSize: 16 }
                                    Text {
                                        text: stateManager ? stateManager.strings.noise_gate : "Puerta de Ruido"
                                        font.pixelSize: 16
                                        font.bold: true
                                        color: root.getVal("noise_gate_on", true) ? "#CBA158" : "#FFFFFF"
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Switch {
                                    checked: root.getVal("noise_gate_on", true)
                                    onToggled: {
                                        if (stateManager) stateManager.setDspParameter("noise_gate_on", checked);
                                    }
                                }
                            }

                            Rectangle { Layout.fillWidth: true; height: 1; color: "#25252D" }

                            // Sliders Body
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 14
                                opacity: root.getVal("noise_gate_on", true) ? 1.0 : 0.4
                                enabled: root.getVal("noise_gate_on", true)

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 12
                                    Text { text: stateManager ? stateManager.strings.threshold : "Umbral:"; font.pixelSize: 12; color: "#8E8E93"; Layout.preferredWidth: 80 }
                                    Slider {
                                        id: ngThreshSlider
                                        Layout.fillWidth: true
                                        from: 0.0; to: 1.0; stepSize: 0.01
                                        value: root.getVal("noise_gate_threshold", 0.28)
                                        onMoved: if (stateManager) stateManager.setDspParameter("noise_gate_threshold", value)
                                    }
                                    Text { text: Math.round(ngThreshSlider.value * 100) + "%"; font.pixelSize: 12; font.bold: true; color: "#CBA158"; Layout.preferredWidth: 40 }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 12
                                    Text { text: stateManager ? stateManager.strings.range : "Rango:"; font.pixelSize: 12; color: "#8E8E93"; Layout.preferredWidth: 80 }
                                    Slider {
                                        id: ngRangeSlider
                                        Layout.fillWidth: true
                                        from: 0.0; to: 1.0; stepSize: 0.01
                                        value: root.getVal("noise_gate_range", 0.7)
                                        onMoved: if (stateManager) stateManager.setDspParameter("noise_gate_range", value)
                                    }
                                    Text { text: Math.round(ngRangeSlider.value * 100) + "%"; font.pixelSize: 12; font.bold: true; color: "#CBA158"; Layout.preferredWidth: 40 }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 12
                                    Text { text: stateManager ? stateManager.strings.attack : "Ataque:"; font.pixelSize: 12; color: "#8E8E93"; Layout.preferredWidth: 80 }
                                    Slider {
                                        id: ngAttackSlider
                                        Layout.fillWidth: true
                                        from: 0.0; to: 1.0; stepSize: 0.01
                                        value: root.getVal("noise_gate_attack", 0.5)
                                        onMoved: if (stateManager) stateManager.setDspParameter("noise_gate_attack", value)
                                    }
                                    Text { text: Math.round(ngAttackSlider.value * 100) + "%"; font.pixelSize: 12; font.bold: true; color: "#CBA158"; Layout.preferredWidth: 40 }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 12
                                    Text { text: stateManager ? stateManager.strings.release : "Liberación:"; font.pixelSize: 12; color: "#8E8E93"; Layout.preferredWidth: 80 }
                                    Slider {
                                        id: ngReleaseSlider
                                        Layout.fillWidth: true
                                        from: 0.0; to: 1.0; stepSize: 0.01
                                        value: root.getVal("noise_gate_release", 0.4)
                                        onMoved: if (stateManager) stateManager.setDspParameter("noise_gate_release", value)
                                    }
                                    Text { text: Math.round(ngReleaseSlider.value * 100) + "%"; font.pixelSize: 12; font.bold: true; color: "#CBA158"; Layout.preferredWidth: 40 }
                                }
                            }
                        }
                    }
                }

                // Row 2: Compressor & (HPF + De-Esser) Cards
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16

                    // CARD 3: COMPRESSOR
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 340
                        radius: 14
                        color: "#18181C"
                        border.color: root.getVal("compressor_on", true) ? "#4A3B18" : "#282830"
                        border.width: 1

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 18
                            spacing: 12

                            // Card Header
                            RowLayout {
                                Layout.fillWidth: true

                                RowLayout {
                                    spacing: 8
                                    Text { text: "🎛️"; font.pixelSize: 16 }
                                    Text {
                                        text: stateManager ? stateManager.strings.compressor : "Compresor"
                                        font.pixelSize: 16
                                        font.bold: true
                                        color: root.getVal("compressor_on", true) ? "#CBA158" : "#FFFFFF"
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Switch {
                                    checked: root.getVal("compressor_on", true)
                                    onToggled: {
                                        if (stateManager) stateManager.setDspParameter("compressor_on", checked);
                                    }
                                }
                            }

                            Rectangle { Layout.fillWidth: true; height: 1; color: "#25252D" }

                            // Sliders Body
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 14
                                opacity: root.getVal("compressor_on", true) ? 1.0 : 0.4
                                enabled: root.getVal("compressor_on", true)

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 12
                                    Text { text: stateManager ? stateManager.strings.threshold : "Umbral:"; font.pixelSize: 12; color: "#8E8E93"; Layout.preferredWidth: 80 }
                                    Slider {
                                        id: compThreshSlider
                                        Layout.fillWidth: true
                                        from: 0.0; to: 1.0; stepSize: 0.01
                                        value: root.getVal("compressor_threshold", 0.65)
                                        onMoved: if (stateManager) stateManager.setDspParameter("compressor_threshold", value)
                                    }
                                    Text { text: Math.round(compThreshSlider.value * 100) + "%"; font.pixelSize: 12; font.bold: true; color: "#CBA158"; Layout.preferredWidth: 40 }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 12
                                    Text { text: stateManager ? stateManager.strings.ratio : "Relación:"; font.pixelSize: 12; color: "#8E8E93"; Layout.preferredWidth: 80 }
                                    Slider {
                                        id: compRatioSlider
                                        Layout.fillWidth: true
                                        from: 0.0; to: 1.0; stepSize: 0.01
                                        value: root.getVal("compressor_ratio", 0.4)
                                        onMoved: if (stateManager) stateManager.setDspParameter("compressor_ratio", value)
                                    }
                                    Text { text: (1.0 + compRatioSlider.value * 7.0).toFixed(1) + ":1"; font.pixelSize: 12; font.bold: true; color: "#CBA158"; Layout.preferredWidth: 40 }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 12
                                    Text { text: stateManager ? stateManager.strings.makeup_gain : "Ganancia:"; font.pixelSize: 12; color: "#8E8E93"; Layout.preferredWidth: 80 }
                                    Slider {
                                        id: compGainSlider
                                        Layout.fillWidth: true
                                        from: 0.0; to: 1.0; stepSize: 0.01
                                        value: root.getVal("compressor_gain", 0.2)
                                        onMoved: if (stateManager) stateManager.setDspParameter("compressor_gain", value)
                                    }
                                    Text { text: "+" + Math.round(compGainSlider.value * 24) + " dB"; font.pixelSize: 12; font.bold: true; color: "#CBA158"; Layout.preferredWidth: 40 }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 12
                                    Text { text: stateManager ? stateManager.strings.attack : "Ataque:"; font.pixelSize: 12; color: "#8E8E93"; Layout.preferredWidth: 80 }
                                    Slider {
                                        id: compAttackSlider
                                        Layout.fillWidth: true
                                        from: 0.0; to: 1.0; stepSize: 0.01
                                        value: root.getVal("compressor_attack", 0.4)
                                        onMoved: if (stateManager) stateManager.setDspParameter("compressor_attack", value)
                                    }
                                    Text { text: Math.round(compAttackSlider.value * 100) + "%"; font.pixelSize: 12; font.bold: true; color: "#CBA158"; Layout.preferredWidth: 40 }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 12
                                    Text { text: stateManager ? stateManager.strings.release : "Liberación:"; font.pixelSize: 12; color: "#8E8E93"; Layout.preferredWidth: 80 }
                                    Slider {
                                        id: compReleaseSlider
                                        Layout.fillWidth: true
                                        from: 0.0; to: 1.0; stepSize: 0.01
                                        value: root.getVal("compressor_release", 0.4)
                                        onMoved: if (stateManager) stateManager.setDspParameter("compressor_release", value)
                                    }
                                    Text { text: Math.round(compReleaseSlider.value * 100) + "%"; font.pixelSize: 12; font.bold: true; color: "#CBA158"; Layout.preferredWidth: 40 }
                                }
                            }
                        }
                    }

                    // CARD 4: HPF (HIGH PASS FILTER) & DE-ESSER
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 340
                        radius: 14
                        color: "#18181C"
                        border.color: (root.getVal("hpf_on", true) || root.getVal("deesser_on", true)) ? "#4A3B18" : "#282830"
                        border.width: 1

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 18
                            spacing: 14

                            // Section 1: HPF (High Pass Filter)
                            RowLayout {
                                Layout.fillWidth: true
                                RowLayout {
                                    spacing: 8
                                    Text { text: "📈"; font.pixelSize: 16 }
                                    Text {
                                        text: stateManager ? stateManager.strings.hpf : "Filtro Paso Alto (HPF)"
                                        font.pixelSize: 15
                                        font.bold: true
                                        color: root.getVal("hpf_on", true) ? "#CBA158" : "#FFFFFF"
                                    }
                                }
                                Item { Layout.fillWidth: true }
                                Switch {
                                    checked: root.getVal("hpf_on", true)
                                    onToggled: {
                                        if (stateManager) stateManager.setDspParameter("hpf_on", checked);
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                opacity: root.getVal("hpf_on", true) ? 1.0 : 0.4
                                enabled: root.getVal("hpf_on", true)

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 12
                                    Text { text: stateManager ? stateManager.strings.frequency : "Frecuencia:"; font.pixelSize: 12; color: "#8E8E93"; Layout.preferredWidth: 80 }
                                    Slider {
                                        id: hpfFreqSlider
                                        Layout.fillWidth: true
                                        from: 0.0; to: 1.0; stepSize: 0.01
                                        value: root.getVal("hpf_frequency", 0.5)
                                        onMoved: if (stateManager) stateManager.setDspParameter("hpf_frequency", value)
                                    }
                                    Text { text: Math.round(20 + hpfFreqSlider.value * 180) + " Hz"; font.pixelSize: 12; font.bold: true; color: "#CBA158"; Layout.preferredWidth: 60 }
                                }
                            }

                            Rectangle { Layout.fillWidth: true; height: 1; color: "#25252D" }

                            // Section 2: De-Esser
                            RowLayout {
                                Layout.fillWidth: true
                                RowLayout {
                                    spacing: 8
                                    Text { text: "🎯"; font.pixelSize: 16 }
                                    Text {
                                        text: stateManager ? stateManager.strings.deesser : "De-Esser (Atenuar 'S')"
                                        font.pixelSize: 15
                                        font.bold: true
                                        color: root.getVal("deesser_on", true) ? "#CBA158" : "#FFFFFF"
                                    }
                                }
                                Item { Layout.fillWidth: true }
                                Switch {
                                    checked: root.getVal("deesser_on", true)
                                    onToggled: {
                                        if (stateManager) stateManager.setDspParameter("deesser_on", checked);
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 10
                                opacity: root.getVal("deesser_on", true) ? 1.0 : 0.4
                                enabled: root.getVal("deesser_on", true)

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 12
                                    Text { text: stateManager ? stateManager.strings.threshold : "Umbral:"; font.pixelSize: 12; color: "#8E8E93"; Layout.preferredWidth: 80 }
                                    Slider {
                                        id: deessThreshSlider
                                        Layout.fillWidth: true
                                        from: 0.0; to: 1.0; stepSize: 0.01
                                        value: root.getVal("deesser_threshold", 0.65)
                                        onMoved: if (stateManager) stateManager.setDspParameter("deesser_threshold", value)
                                    }
                                    Text { text: Math.round(deessThreshSlider.value * 100) + "%"; font.pixelSize: 12; font.bold: true; color: "#CBA158"; Layout.preferredWidth: 60 }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 12
                                    Text { text: stateManager ? stateManager.strings.ratio : "Relación:"; font.pixelSize: 12; color: "#8E8E93"; Layout.preferredWidth: 80 }
                                    Slider {
                                        id: deessRatioSlider
                                        Layout.fillWidth: true
                                        from: 0.0; to: 1.0; stepSize: 0.01
                                        value: root.getVal("deesser_ratio", 0.5)
                                        onMoved: if (stateManager) stateManager.setDspParameter("deesser_ratio", value)
                                    }
                                    Text { text: Math.round(deessRatioSlider.value * 100) + "%"; font.pixelSize: 12; font.bold: true; color: "#CBA158"; Layout.preferredWidth: 60 }
                                }
                            }
                        }
                    }
                }

                // Row 3: 3-Band Parametric Equalizer (EQ) Card
                Rectangle {
                    Layout.fillWidth: true
                    height: 180
                    radius: 14
                    color: "#18181C"
                    border.color: root.getVal("eq_on", true) ? "#4A3B18" : "#282830"
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 14

                        // Card Header
                        RowLayout {
                            Layout.fillWidth: true

                            RowLayout {
                                spacing: 8
                                Text { text: "🎚️"; font.pixelSize: 16 }
                                Text {
                                    text: stateManager ? stateManager.strings.equalizer : "Ecualizador (EQ 3 Bandas)"
                                    font.pixelSize: 16
                                    font.bold: true
                                    color: root.getVal("eq_on", true) ? "#CBA158" : "#FFFFFF"
                                }
                            }

                            Item { Layout.fillWidth: true }

                            Switch {
                                checked: root.getVal("eq_on", true)
                                onToggled: {
                                    if (stateManager) stateManager.setDspParameter("eq_on", checked);
                                }
                            }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: "#25252D" }

                        // 3 EQ Sliders in a Horizontal Row
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 24
                            opacity: root.getVal("eq_on", true) ? 1.0 : 0.4
                            enabled: root.getVal("eq_on", true)

                            // Low Band (Graves)
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: stateManager ? stateManager.strings.low : "Graves (Low)"; font.pixelSize: 12; font.bold: true; color: "#E0E0E0" }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        property real db: (eqLowSlider.value - 0.5) * 24.0
                                        text: (db > 0 ? "+" : "") + db.toFixed(1) + " dB"
                                        font.pixelSize: 12; font.bold: true; color: "#CBA158"
                                    }
                                }
                                Slider {
                                    id: eqLowSlider
                                    Layout.fillWidth: true
                                    from: 0.0; to: 1.0; stepSize: 0.02
                                    value: root.getVal("eq_low", 0.5)
                                    onMoved: if (stateManager) stateManager.setDspParameter("eq_low", value)
                                }
                            }

                            // Mid Band (Medios)
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: stateManager ? stateManager.strings.mid : "Medios (Mid)"; font.pixelSize: 12; font.bold: true; color: "#E0E0E0" }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        property real db: (eqMidSlider.value - 0.5) * 24.0
                                        text: (db > 0 ? "+" : "") + db.toFixed(1) + " dB"
                                        font.pixelSize: 12; font.bold: true; color: "#CBA158"
                                    }
                                }
                                Slider {
                                    id: eqMidSlider
                                    Layout.fillWidth: true
                                    from: 0.0; to: 1.0; stepSize: 0.02
                                    value: root.getVal("eq_mid", 0.5)
                                    onMoved: if (stateManager) stateManager.setDspParameter("eq_mid", value)
                                }
                            }

                            // High Band (Agudos)
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: stateManager ? stateManager.strings.high : "Agudos (High)"; font.pixelSize: 12; font.bold: true; color: "#E0E0E0" }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        property real db: (eqHighSlider.value - 0.5) * 24.0
                                        text: (db > 0 ? "+" : "") + db.toFixed(1) + " dB"
                                        font.pixelSize: 12; font.bold: true; color: "#CBA158"
                                    }
                                }
                                Slider {
                                    id: eqHighSlider
                                    Layout.fillWidth: true
                                    from: 0.0; to: 1.0; stepSize: 0.02
                                    value: root.getVal("eq_high", 0.5)
                                    onMoved: if (stateManager) stateManager.setDspParameter("eq_high", value)
                                }
                            }
                        }
                    }
                }

                Item { height: 20 }
            }
        }
    }
}
