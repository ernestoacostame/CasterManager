import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: root

    readonly property var dsp: (stateManager && stateManager.currentDsp) ? stateManager.currentDsp : ({})
    property int activeTab: 0            // 0: VoxLab™, 1: Canal Avanzado
    property string focusedEffect: ""

    function getVal(prop, defVal) {
        if (root.dsp && root.dsp[prop] !== undefined && root.dsp[prop] !== null) {
            return root.dsp[prop];
        }
        return defVal;
    }

    function s(key, fallback) {
        return (stateManager && stateManager.strings && stateManager.strings[key]) ? stateManager.strings[key] : fallback;
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 14

        // ───────────── 1. Header + channel selector ─────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            ColumnLayout {
                spacing: 3
                Text {
                    text: root.s("audio_processing_title", "Procesamiento de Audio en Vivo")
                    font.pixelSize: 20
                    font.bold: true
                    color: "#FFFFFF"
                }
                Text {
                    text: root.s("processing_subtitle", "APHEX®, procesamiento dinámico, filtros y VoxLab™ por canal")
                    font.pixelSize: 12
                    color: "#8E8E93"
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                height: 36
                radius: 18
                color: "#16161A"
                border.color: "#2C2C32"
                implicitWidth: channelRow.implicitWidth + 8

                RowLayout {
                    id: channelRow
                    anchors.centerIn: parent
                    spacing: 4

                    Repeater {
                        model: stateManager ? stateManager.dspChannels : []

                        Rectangle {
                            readonly property bool sel: stateManager && stateManager.activeDspChannel === modelData.id
                            height: 28
                            radius: 14
                            implicitWidth: Math.max(86, chText.implicitWidth + 22)
                            color: sel ? "#CBA158" : "transparent"

                            Text {
                                id: chText
                                anchors.centerIn: parent
                                text: modelData.name
                                font.pixelSize: 11
                                font.bold: parent.sel
                                color: parent.sel ? "#121214" : "#AAAAAA"
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (stateManager) stateManager.setActiveDspChannel(modelData.id)
                            }
                        }
                    }
                }
            }
        }

        // ───────────── 2. Signal chain strip ─────────────
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: chainFlow.implicitHeight + 20
            radius: 10
            color: "#18181C"
            border.color: "#282830"

            Flow {
                id: chainFlow
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 4

                Repeater {
                    model: [
                        {"id": "preamp",     "name": "Preamp",     "icon": "🎙️", "active": true},
                        {"id": "hpf",        "name": "HPF",        "icon": "📉", "active": root.getVal("hpf_on", true)},
                        {"id": "gate",       "name": "Gate",       "icon": "🚪", "active": root.getVal("noise_gate_on", true)},
                        {"id": "deesser",    "name": "De-Esser",   "icon": "🔕", "active": root.getVal("deesser_on", true)},
                        {"id": "compressor", "name": root.s("compressor", "Compresor"), "icon": "🗜️", "active": root.getVal("compressor_on", true)},
                        {"id": "eq",         "name": "EQ",         "icon": "🎚️", "active": root.getVal("eq_on", true)},
                        {"id": "exciter",    "name": "Exciter",    "icon": "✨", "active": root.getVal("aphex_on", true) && root.getVal("aphex_ae_mix", 0.5) > 0},
                        {"id": "big_bottom", "name": "Big Bottom", "icon": "🔊", "active": root.getVal("aphex_on", true) && root.getVal("aphex_bb_drive", 0.5) > 0}
                    ]

                    Row {
                        spacing: 4

                        Text {
                            visible: index > 0
                            anchors.verticalCenter: parent.verticalCenter
                            text: "›"
                            font.pixelSize: 16
                            color: "#55555E"
                        }

                        Rectangle {
                            readonly property bool sel: root.focusedEffect === modelData.id && root.activeTab === 1
                            width: blockRow.implicitWidth + 20
                            height: 34
                            radius: 6
                            color: modelData.active
                                ? (cArea.containsMouse ? "#2E2A20" : "#24221C")
                                : (cArea.containsMouse ? "#25252A" : "#1C1C20")
                            border.color: sel ? "#FFFFFF" : (modelData.active ? "#CBA158" : "#2E2E36")
                            border.width: sel ? 2 : 1

                            Row {
                                id: blockRow
                                anchors.centerIn: parent
                                spacing: 5
                                Text { text: modelData.icon; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                                Text {
                                    text: modelData.name
                                    font.pixelSize: 10
                                    font.bold: modelData.active
                                    color: modelData.active ? "#FFFFFF" : "#8E8E93"
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Rectangle {
                                    width: 6; height: 6; radius: 3
                                    color: modelData.active ? "#28C850" : "#55555C"
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                id: cArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.activeTab = 1;
                                    root.focusedEffect = modelData.id;
                                }
                            }
                        }
                    }
                }
            }
        }

        // ───────────── 3. Mode switcher ─────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            Rectangle {
                height: 36
                radius: 8
                color: "#18181C"
                border.color: "#282830"
                implicitWidth: 320

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 3
                    spacing: 3

                    Repeater {
                        model: [
                            {"icon": "⚡", "label": root.s("voxlab_mode", "VoxLab™")},
                            {"icon": "🎛️", "label": root.s("advanced_mode", "Canal Avanzado")}
                        ]
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 5
                            color: root.activeTab === index ? "#CBA158" : "transparent"
                            Row {
                                anchors.centerIn: parent
                                spacing: 6
                                Text { text: modelData.icon; font.pixelSize: 12 }
                                Text {
                                    text: modelData.label
                                    font.pixelSize: 12
                                    font.bold: root.activeTab === index
                                    color: root.activeTab === index ? "#121214" : "#D0D0D0"
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.activeTab = index;
                                    if (index === 0) root.focusedEffect = "";
                                }
                            }
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: root.activeTab === 0
                    ? root.s("voxlab_subtitle", "Controles macro intuitivos y perfiles de voz")
                    : root.s("advanced_subtitle", "Control completo de cada procesador de la cadena")
                font.pixelSize: 11
                color: "#8E8E93"
                elide: Text.ElideRight
            }
        }

        // ───────────── 4. Body ─────────────
        ScrollView {
            id: mainScroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: availableWidth
            clip: true

            ColumnLayout {
                width: mainScroll.availableWidth
                spacing: 16

                // ================= TAB 0: VoxLab™ =================
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 18
                    visible: root.activeTab === 0

                    Text {
                        text: root.s("voice_presets", "Perfiles de Voz")
                        font.pixelSize: 13
                        font.bold: true
                        color: "#FFFFFF"
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: mainScroll.availableWidth > 760 ? 4 : 2
                        rowSpacing: 12
                        columnSpacing: 12

                        Repeater {
                            model: [
                                {"id": "broadcast", "icon": "🎙️", "name": root.s("preset_broadcast", "Broadcast"),          "desc": root.s("preset_broadcast_desc", "")},
                                {"id": "podcast",   "icon": "🎧", "name": root.s("preset_podcast", "Podcast Studio"),      "desc": root.s("preset_podcast_desc", "")},
                                {"id": "gaming",    "icon": "🎮", "name": root.s("preset_gaming", "Streaming / Gaming"),   "desc": root.s("preset_gaming_desc", "")},
                                {"id": "neutral",   "icon": "🎛️", "name": root.s("preset_neutral", "Neutro / Plano"),      "desc": root.s("preset_neutral_desc", "")}
                            ]

                            Rectangle {
                                readonly property bool isSelected: root.getVal("active_preset", "") === modelData.id
                                Layout.fillWidth: true
                                Layout.preferredHeight: 84
                                radius: 10
                                color: isSelected ? "#2E281C" : (pArea.containsMouse ? "#222228" : "#1A1A1E")
                                border.color: isSelected ? "#CBA158" : (pArea.containsMouse ? "#3E3E48" : "#282830")
                                border.width: isSelected ? 2 : 1

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 4

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8
                                        Text { text: modelData.icon; font.pixelSize: 15 }
                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData.name
                                            font.pixelSize: 13
                                            font.bold: true
                                            color: parent.parent.parent.isSelected ? "#CBA158" : "#FFFFFF"
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            visible: parent.parent.parent.isSelected
                                            text: "✓"
                                            font.pixelSize: 13
                                            font.bold: true
                                            color: "#CBA158"
                                        }
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        text: modelData.desc
                                        font.pixelSize: 10
                                        color: "#8E8E93"
                                        wrapMode: Text.WordWrap
                                        elide: Text.ElideRight
                                    }
                                }

                                MouseArea {
                                    id: pArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: if (stateManager) stateManager.applyDspPreset(modelData.id)
                                }
                            }
                        }
                    }

                    Text {
                        text: root.s("voxlab_macros", "Controles Maestros VoxLab™")
                        font.pixelSize: 13
                        font.bold: true
                        color: "#FFFFFF"
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: mainScroll.availableWidth > 760 ? 3 : 1
                        rowSpacing: 14
                        columnSpacing: 14

                        Repeater {
                            model: [
                                {"key": "depth",   "prop": "voxlab_depth",   "icon": "🔊", "accent": "#FF8C28",
                                 "title": root.s("depth", "Depth"),     "desc": root.s("depth_desc", "")},
                                {"key": "sparkle", "prop": "voxlab_sparkle", "icon": "✨", "accent": "#CBA158",
                                 "title": root.s("sparkle", "Sparkle"), "desc": root.s("sparkle_desc", "")},
                                {"key": "punch",   "prop": "voxlab_punch",   "icon": "🗜️", "accent": "#3C96FF",
                                 "title": root.s("punch", "Punch"),     "desc": root.s("punch_desc", "")}
                            ]

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 150
                                radius: 12
                                color: "#18181C"
                                border.color: "#282830"

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 16
                                    spacing: 8

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 10
                                        Text { text: modelData.icon; font.pixelSize: 20 }
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 1
                                            Text { text: modelData.title; font.pixelSize: 14; font.bold: true; color: "#FFFFFF" }
                                            Text {
                                                Layout.fillWidth: true
                                                text: modelData.desc
                                                font.pixelSize: 10
                                                color: "#8E8E93"
                                                wrapMode: Text.WordWrap
                                            }
                                        }
                                        Rectangle {
                                            width: 50; height: 24; radius: 6
                                            color: "#141418"
                                            border.color: modelData.accent
                                            Text {
                                                anchors.centerIn: parent
                                                text: Math.round(macroSlider.value) + "%"
                                                font.pixelSize: 12
                                                font.bold: true
                                                color: modelData.accent
                                            }
                                        }
                                    }

                                    Item { Layout.fillHeight: true }

                                    Slider {
                                        id: macroSlider
                                        Layout.fillWidth: true
                                        from: 0; to: 100; stepSize: 1
                                        value: root.getVal(modelData.prop, 50)
                                        onMoved: if (stateManager) stateManager.setVoxlabMacro(modelData.key, Math.round(value))
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Off"; font.pixelSize: 10; color: "#66666E" }
                                        Item { Layout.fillWidth: true }
                                        Text { text: root.s("macro_studio", "Estudio"); font.pixelSize: 10; color: "#66666E" }
                                        Item { Layout.fillWidth: true }
                                        Text { text: root.s("macro_max", "Máx"); font.pixelSize: 10; color: "#66666E" }
                                    }
                                }
                            }
                        }
                    }
                }

                // ================= TAB 1: Canal Avanzado =================
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 16
                    visible: root.activeTab === 1

                    // Preamp strip
                    DspCard {
                        icon: "🎙️"
                        title: root.s("preamp", "Preamplificador / Entrada")
                        description: "Revolution Preamp™ ultra-bajo ruido"
                        focused: root.focusedEffect === "preamp"

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 16

                            DspSlider {
                                label: root.s("preamp_gain", "Ganancia")
                                prop: "preamp_gain"
                                defVal: 45; from: 0; to: 76; stepSize: 1
                                format: function(v) { return Math.round(v) + " dB"; }
                            }

                            Rectangle {
                                readonly property bool on: root.getVal("phantom_power", false)
                                width: 72; height: 32; radius: 6
                                color: on ? "#3D2418" : (p48Area.containsMouse ? "#2A2A32" : "#202026")
                                border.color: on ? "#FF9500" : "#32323C"
                                Text {
                                    anchors.centerIn: parent
                                    text: "+48V"
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: parent.on ? "#FF9500" : "#8E8E93"
                                }
                                MouseArea {
                                    id: p48Area
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: if (stateManager) stateManager.setDspParameter("phantom_power", !parent.on)
                                }
                            }

                            Rectangle {
                                readonly property bool on: root.getVal("phase_flip", false)
                                width: 44; height: 32; radius: 6
                                color: on ? "#2C2618" : (phaseArea.containsMouse ? "#2A2A32" : "#202026")
                                border.color: on ? "#CBA158" : "#32323C"
                                Text {
                                    anchors.centerIn: parent
                                    text: "Ø"
                                    font.pixelSize: 14
                                    font.bold: true
                                    color: parent.on ? "#CBA158" : "#8E8E93"
                                }
                                MouseArea {
                                    id: phaseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: if (stateManager) stateManager.setDspParameter("phase_flip", !parent.on)
                                }
                            }
                        }
                    }

                    // Processors in signal-chain order (2 columns)
                    GridLayout {
                        Layout.fillWidth: true
                        columns: mainScroll.availableWidth > 760 ? 2 : 1
                        rowSpacing: 16
                        columnSpacing: 16

                        DspCard {
                            Layout.alignment: Qt.AlignTop
                            icon: "📉"
                            title: root.s("hpf", "Filtro Paso Alto (HPF)")
                            description: root.s("hpf_desc", "")
                            onProp: "hpf_on"
                            focused: root.focusedEffect === "hpf"

                            DspSlider {
                                label: root.s("frequency", "Frecuencia")
                                prop: "hpf_frequency"
                                format: function(v) { return Math.round(20 + v * 180) + " Hz"; }
                            }
                        }

                        DspCard {
                            Layout.alignment: Qt.AlignTop
                            icon: "🚪"
                            title: root.s("noise_gate", "Puerta de Ruido")
                            description: root.s("noise_gate_desc", "")
                            onProp: "noise_gate_on"
                            focused: root.focusedEffect === "gate"

                            DspSlider {
                                label: root.s("threshold", "Umbral")
                                prop: "noise_gate_threshold"; defVal: 0.28
                                format: function(v) { return (-60 + v * 50).toFixed(1) + " dB"; }
                            }
                            DspSlider {
                                label: root.s("range", "Rango")
                                prop: "noise_gate_range"; defVal: 0.7
                                format: function(v) { return (-80 + v * 60).toFixed(1) + " dB"; }
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12
                                DspSlider { compact: true; label: root.s("attack", "Ataque");      prop: "noise_gate_attack";  defVal: 0.5 }
                                DspSlider { compact: true; label: root.s("release", "Liberación"); prop: "noise_gate_release"; defVal: 0.4 }
                            }
                        }

                        DspCard {
                            Layout.alignment: Qt.AlignTop
                            icon: "🔕"
                            title: root.s("deesser", "De-Esser")
                            description: root.s("deesser_desc", "")
                            onProp: "deesser_on"
                            focused: root.focusedEffect === "deesser"

                            DspSlider {
                                label: root.s("threshold", "Umbral")
                                prop: "deesser_threshold"; defVal: 0.65
                                format: function(v) { return (-50 + v * 40).toFixed(1) + " dB"; }
                            }
                            DspSlider {
                                label: root.s("ratio", "Intensidad")
                                prop: "deesser_ratio"; defVal: 0.5
                            }
                        }

                        DspCard {
                            Layout.alignment: Qt.AlignTop
                            icon: "🗜️"
                            title: root.s("compressor", "Compresor")
                            description: root.s("compressor_desc", "")
                            onProp: "compressor_on"
                            focused: root.focusedEffect === "compressor"

                            DspSlider {
                                label: root.s("threshold", "Umbral")
                                prop: "compressor_threshold"; defVal: 0.65
                                format: function(v) { return (-40 + v * 40).toFixed(1) + " dB"; }
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12
                                DspSlider {
                                    compact: true; label: root.s("ratio", "Ratio")
                                    prop: "compressor_ratio"; defVal: 0.4; stepSize: 0.05
                                    format: function(v) { return (1.0 + v * 7.0).toFixed(1) + ":1"; }
                                }
                                DspSlider {
                                    compact: true; label: root.s("makeup_gain", "Ganancia")
                                    prop: "compressor_gain"; defVal: 0.2
                                    format: function(v) { return "+" + (v * 24.0).toFixed(1) + " dB"; }
                                }
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12
                                DspSlider { compact: true; label: root.s("attack", "Ataque");      prop: "compressor_attack";  defVal: 0.4 }
                                DspSlider { compact: true; label: root.s("release", "Liberación"); prop: "compressor_release"; defVal: 0.4 }
                            }
                        }

                        DspCard {
                            Layout.alignment: Qt.AlignTop
                            icon: "🎚️"
                            title: root.s("equalizer", "Ecualizador (EQ)")
                            description: root.s("equalizer_desc", "")
                            onProp: "eq_on"
                            focused: root.focusedEffect === "eq"

                            Repeater {
                                model: [
                                    {"prop": "eq_low",  "label": root.s("low", "Graves")},
                                    {"prop": "eq_mid",  "label": root.s("mid", "Medios")},
                                    {"prop": "eq_high", "label": root.s("high", "Agudos")}
                                ]
                                DspSlider {
                                    label: modelData.label
                                    prop: modelData.prop
                                    stepSize: 0.02
                                    format: function(v) { let db = (v - 0.5) * 24.0; return (db > 0 ? "+" : "") + db.toFixed(1) + " dB"; }
                                }
                            }
                        }

                        DspCard {
                            Layout.alignment: Qt.AlignTop
                            icon: "✨"
                            title: root.s("aphex_title", "Procesamiento APHEX®")
                            description: root.s("aphex_desc", "")
                            onProp: "aphex_on"
                            focused: root.focusedEffect === "exciter" || root.focusedEffect === "big_bottom"

                            Text { text: root.s("aural_exciter", "Aural Exciter™"); font.pixelSize: 11; font.bold: true; color: "#E0E0E0" }
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12
                                DspSlider { compact: true; label: "Mix";  prop: "aphex_ae_mix";  defVal: 0.5 }
                                DspSlider { compact: true; label: "Tune"; prop: "aphex_ae_tune"; defVal: 0.5 }
                            }
                            Text { text: root.s("big_bottom", "Big Bottom™"); font.pixelSize: 11; font.bold: true; color: "#E0E0E0" }
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12
                                DspSlider { compact: true; accent: "#FF8C28"; label: "Drive"; prop: "aphex_bb_drive"; defVal: 0.5 }
                                DspSlider { compact: true; accent: "#FF8C28"; label: "Tune";  prop: "aphex_bb_tune";  defVal: 0.35 }
                            }
                        }
                    }
                }

                Item { height: 16 }
            }
        }
    }
}
