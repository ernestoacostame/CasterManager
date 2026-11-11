import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Dialogs
import QtMultimedia

Item {
    id: root

    property int selectedIndex: 0
    property var recordingsList: (stateManager && stateManager.recordings) ? stateManager.recordings : []
    property var activeRecording: (recordingsList.length > selectedIndex && selectedIndex >= 0) ? recordingsList[selectedIndex] : null

    // Playback state
    property bool isPlaying: false
    property real playbackPos: 0.15 // Progress fraction 0.0 - 1.0
    property real currentSeconds: 4.0
    property real totalSeconds: (activeRecording && activeRecording.duration_seconds) ? activeRecording.duration_seconds : 24.0

    // Zoom level for waveform
    property real zoomFactor: 1.0

    // Waveform data
    property var waveformPeaks: (stateManager && activeRecording) 
        ? stateManager.getWaveformPeaks(activeRecording.stereo_wav || "", 90) 
        : []

    // Media Player for real audio playback
    MediaPlayer {
        id: player
        audioOutput: AudioOutput { id: audioOut }
        // Released while leaving transfer mode: an open WAV keeps the card busy and the
        // console refuses to leave transfer mode until it is closed.
        source: (root.activeRecording && root.activeRecording.stereo_wav
                 && !(stateManager && stateManager.transferExiting))
                ? ("file://" + root.activeRecording.stereo_wav)
                : ""
        onPositionChanged: {
            if (player.duration > 0) {
                root.playbackPos = player.position / player.duration;
                root.currentSeconds = player.position / 1000.0;
            }
        }
        onPlaybackStateChanged: {
            root.isPlaying = (player.playbackState === MediaPlayer.PlayingState);
        }
    }

    // Playback simulation timer when actual file is missing or in mock mode
    Timer {
        id: simTimer
        interval: 100
        running: root.isPlaying && (!player.source || player.duration <= 0)
        repeat: true
        onTriggered: {
            root.currentSeconds += 0.1;
            if (root.currentSeconds >= root.totalSeconds) {
                root.currentSeconds = 0.0;
                root.isPlaying = false;
            }
            root.playbackPos = root.totalSeconds > 0 ? (root.currentSeconds / root.totalSeconds) : 0;
            waveCanvas.requestPaint();
        }
    }

    // Export file dialog
    FileDialog {
        id: exportTakeDialog
        title: stateManager ? stateManager.strings.export_take : "Exportar Grabación"
        fileMode: FileDialog.SaveFile
        defaultSuffix: formatCombo.currentText.toLowerCase()
        nameFilters: [
            (stateManager && stateManager.language === "en" ? "Audio Files (*." : "Archivos de Audio (*.") + formatCombo.currentText.toLowerCase() + ")",
            (stateManager && stateManager.language === "en" ? "All Files (*)" : "Todos los archivos (*)")
        ]
        onAccepted: {
            if (stateManager && root.activeRecording && selectedFile) {
                stateManager.exportRecording(
                    root.activeRecording.stereo_wav || root.activeRecording.path || "",
                    selectedFile.toString(),
                    formatCombo.currentText,
                    sampleRateCombo.currentText,
                    bitRateCombo.currentText,
                    loudnessCombo.currentText
                );
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12
        visible: Boolean(root.recordingsList && root.recordingsList.length > 0)

        // ==========================================
        // TOP SECTION: WAVEFORM AUDIO PLAYER
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 180
            radius: 8
            color: "#0F0F12"
            border.color: "#24242A"
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // Mini Scrubber & Zoom Controls Header
                Rectangle {
                    Layout.fillWidth: true
                    height: 24
                    color: "#141418"
                    radius: 8

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12

                        // Mini progress dots
                        Row {
                            spacing: 4
                            Layout.fillWidth: true
                            Repeater {
                                model: 50
                                Rectangle {
                                    width: 3
                                    height: 3
                                    radius: 1.5
                                    color: (index / 50.0 <= root.playbackPos) ? "#CBA158" : "#33333A"
                                }
                            }
                        }

                        // Zoom buttons
                        Row {
                            spacing: 8
                            Text {
                                text: "🔍 -"
                                font.pixelSize: 10
                                color: "#8E8E93"
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.zoomFactor = Math.max(0.6, root.zoomFactor - 0.2)
                                }
                            }
                            Text {
                                text: "🔍 +"
                                font.pixelSize: 10
                                color: "#8E8E93"
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.zoomFactor = Math.min(2.0, root.zoomFactor + 0.2)
                                }
                            }
                        }
                    }
                }

                // Interactive Waveform Area
                Item {
                    id: waveArea
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Canvas {
                        id: waveCanvas
                        anchors.fill: parent
                        anchors.margins: 8
                        onWidthChanged: requestPaint()
                        onHeightChanged: requestPaint()
                        Component.onCompleted: requestPaint()

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);

                            var peaks = root.waveformPeaks;
                            if (!peaks || peaks.length === 0) {
                                // Default wave shape if peaks empty
                                peaks = [];
                                for (var k = 0; k < 90; k++) {
                                    peaks.push(0.12 + 0.38 * Math.abs(Math.sin(k * 0.14)) + 0.35 * Math.abs(Math.cos(k * 0.28)));
                                }
                            }

                            var count = peaks.length;
                            var barW = Math.max(2, (width / count) * 0.65);
                            var gap = Math.max(1, (width / count) * 0.35);
                            var midY = height * 0.42;

                            for (var i = 0; i < count; i++) {
                                var x = i * (barW + gap) + gap / 2;
                                var p = peaks[i];
                                var h = Math.max(4, p * (height * 0.65));

                                // Draw waveform bar with smooth pill shape
                                ctx.fillStyle = (x <= root.playbackPos * width) ? "#FFFFFF" : "#72727C";
                                ctx.beginPath();
                                var r = Math.min(barW / 2, 2.5);
                                var topY = midY - h / 2;
                                ctx.rect(x, topY, barW, h);
                                ctx.fill();
                            }

                            // Draw Playhead line
                            var playheadX = root.playbackPos * width;
                            ctx.fillStyle = "#3B82F6";
                            ctx.fillRect(playheadX - 1, 2, 2, height - 16);

                            // Playhead top marker
                            ctx.beginPath();
                            ctx.moveTo(playheadX - 5, 2);
                            ctx.lineTo(playheadX + 5, 2);
                            ctx.lineTo(playheadX, 9);
                            ctx.closePath();
                            ctx.fill();
                        }

                        Connections {
                            target: root
                            function onPlaybackPosChanged() { waveCanvas.requestPaint(); }
                            function onWaveformPeaksChanged() { waveCanvas.requestPaint(); }
                        }
                    }

                    // Seek click area
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: (mouse) => {
                            var frac = Math.max(0.0, Math.min(1.0, mouse.x / width));
                            root.playbackPos = frac;
                            root.currentSeconds = frac * root.totalSeconds;
                            if (player.duration > 0) {
                                player.position = frac * player.duration;
                            }
                            waveCanvas.requestPaint();
                        }
                    }

                    // Timeline ruler at bottom
                    Row {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        height: 28

                        Repeater {
                            model: 9
                            Item {
                                width: (waveArea.width - 20) / 9
                                height: 28

                                Column {
                                    anchors.left: parent.left
                                    spacing: 2

                                    Rectangle { width: 1; height: 5; color: "#44444C" }

                                    Text {
                                        text: "00:0" + index
                                        font.pixelSize: 9
                                        color: "#7E7E86"
                                    }
                                    Text {
                                        text: "17:08:" + (12 + index)
                                        font.pixelSize: 8
                                        color: "#55555C"
                                    }
                                }
                            }
                        }
                    }
                }

                // Transport Playback Controls
                Rectangle {
                    Layout.fillWidth: true
                    height: 48
                    color: "#0B0B0D"

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 24

                        // Prev / Start button
                        Text {
                            text: "⏮"
                            font.pixelSize: 14
                            color: "#8E8E93"
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.playbackPos = 0.0;
                                    root.currentSeconds = 0.0;
                                    if (player.duration > 0) player.position = 0;
                                }
                            }
                        }

                        // Replay 15s
                        Rectangle {
                            width: 28
                            height: 28
                            radius: 14
                            color: "#18181C"
                            border.color: "#2C2C32"
                            Text {
                                anchors.centerIn: parent
                                text: "↺15"
                                font.pixelSize: 9
                                font.bold: true
                                color: "#8E8E93"
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.currentSeconds = Math.max(0.0, root.currentSeconds - 15.0);
                                    root.playbackPos = root.totalSeconds > 0 ? (root.currentSeconds / root.totalSeconds) : 0;
                                    if (player.duration > 0) player.position = root.playbackPos * player.duration;
                                }
                            }
                        }

                        // Main Big Play / Pause button (matches Rode style)
                        Rectangle {
                            width: 36
                            height: 36
                            radius: 18
                            color: "#FFFFFF"

                            Text {
                                anchors.centerIn: parent
                                text: root.isPlaying ? "❚❚" : "▶"
                                font.pixelSize: 13
                                color: "#000000"
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.isPlaying = !root.isPlaying;
                                    if (player.source) {
                                        if (root.isPlaying) player.play();
                                        else player.pause();
                                    }
                                }
                            }
                        }

                        // Forward 30s
                        Rectangle {
                            width: 28
                            height: 28
                            radius: 14
                            color: "#18181C"
                            border.color: "#2C2C32"
                            Text {
                                anchors.centerIn: parent
                                text: "30↻"
                                font.pixelSize: 9
                                font.bold: true
                                color: "#8E8E93"
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.currentSeconds = Math.min(root.totalSeconds, root.currentSeconds + 30.0);
                                    root.playbackPos = root.totalSeconds > 0 ? (root.currentSeconds / root.totalSeconds) : 0;
                                    if (player.duration > 0) player.position = root.playbackPos * player.duration;
                                }
                            }
                        }

                        // Next / End button
                        Text {
                            text: "⏭"
                            font.pixelSize: 14
                            color: "#8E8E93"
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.playbackPos = 1.0;
                                    root.currentSeconds = root.totalSeconds;
                                    if (player.duration > 0) player.position = player.duration;
                                }
                            }
                        }
                    }
                }
            }
        }

        // ==========================================
        // BOTTOM SECTION: SPLIT LIST & DETAILS
        // ==========================================
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 14

            // ------------------------------------------
            // LEFT COLUMN: RECORDINGS LIST
            // ------------------------------------------
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 340
                spacing: 8

                // Top filter pill buttons: New (3) | All | None
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Rectangle {
                        height: 28
                        radius: 4
                        width: 80
                        color: "#107C41"
                        Text {
                            anchors.centerIn: parent
                            text: (stateManager ? stateManager.strings.new_takes : "New") + " (" + root.recordingsList.length + ")"
                            font.pixelSize: 11
                            font.bold: true
                            color: "#FFFFFF"
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                        }
                    }

                    Rectangle {
                        height: 28
                        radius: 4
                        width: 60
                        color: "#2C2C32"
                        Text {
                            anchors.centerIn: parent
                            text: stateManager ? stateManager.strings.all : "All"
                            font.pixelSize: 11
                            color: "#FFFFFF"
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                        }
                    }

                    Rectangle {
                        height: 28
                        radius: 4
                        width: 60
                        color: "#2C2C32"
                        Text {
                            anchors.centerIn: parent
                            text: stateManager ? stateManager.strings.none : "None"
                            font.pixelSize: 11
                            color: "#FFFFFF"
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                        }
                    }

                    Item { Layout.fillWidth: true }
                }

                // Sort and Channel Filter dropdowns
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    ComboBox {
                        id: sortCombo
                        Layout.fillWidth: true
                        model: [stateManager ? stateManager.strings.latest : "Latest", stateManager ? stateManager.strings.oldest : "Oldest"]
                        background: Rectangle {
                            implicitHeight: 28
                            radius: 14
                            color: "#202026"
                            border.color: "#35353E"
                        }
                        contentItem: Text {
                            text: sortCombo.displayText
                            font.pixelSize: 11
                            color: "#FFFFFF"
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: 10
                        }
                    }

                    ComboBox {
                        id: typeCombo
                        Layout.fillWidth: true
                        model: [stateManager ? stateManager.strings.all : "All", stateManager ? stateManager.strings.multitrack : "Multitrack", stateManager ? stateManager.strings.stereo : "Stereo"]
                        background: Rectangle {
                            implicitHeight: 28
                            radius: 14
                            color: "#202026"
                            border.color: "#35353E"
                        }
                        contentItem: Text {
                            text: typeCombo.displayText
                            font.pixelSize: 11
                            color: "#FFFFFF"
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: 10
                        }
                    }
                }

                // Scrollable List of Takes
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 8
                    color: "#161619"
                    border.color: "#26262C"
                    clip: true

                    ScrollView {
                        anchors.fill: parent
                        anchors.margins: 4

                        ListView {
                            id: takesList
                            width: parent.width
                            model: root.recordingsList
                            spacing: 2

                            delegate: Rectangle {
                                width: takesList.width
                                height: 50
                                radius: 4
                                color: (index === root.selectedIndex) 
                                       ? "#2558B5" 
                                       : (itemArea.containsMouse ? "#202026" : "transparent")

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 10

                                    // Selection Checkbox
                                    Rectangle {
                                        width: 14
                                        height: 14
                                        radius: 3
                                        color: (index === root.selectedIndex) ? "#FFFFFF" : "#282830"
                                        border.color: "#4A4A52"
                                        Text {
                                            anchors.centerIn: parent
                                            text: (index === root.selectedIndex) ? "✓" : ""
                                            font.pixelSize: 10
                                            font.bold: true
                                            color: "#2558B5"
                                        }
                                    }

                                    ColumnLayout {
                                        spacing: 2
                                        Layout.fillWidth: true

                                        Text {
                                            text: modelData.name || modelData.folder || ("Recording " + (index + 1))
                                            font.pixelSize: 12
                                            font.bold: true
                                            color: "#FFFFFF"
                                        }

                                        Text {
                                            text: modelData.date || "TODAY, 17:08"
                                            font.pixelSize: 10
                                            color: (index === root.selectedIndex) ? "#D0E0FF" : "#8E8E93"
                                        }
                                    }

                                    // Multitrack dot & indicator
                                    Row {
                                        spacing: 4
                                        Layout.alignment: Qt.AlignVCenter

                                        Rectangle {
                                            width: 6
                                            height: 6
                                            radius: 3
                                            color: "#FF3B30"
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Column {
                                            spacing: 1
                                            Text {
                                                text: modelData.multitrack ? (stateManager ? stateManager.strings.multitrack : "Multitrack") : (stateManager ? stateManager.strings.stereo : "Stereo")
                                                font.pixelSize: 9
                                                color: (index === root.selectedIndex) ? "#FFFFFF" : "#9A9A9E"
                                            }
                                            Text {
                                                text: modelData.duration || "00:24"
                                                font.pixelSize: 10
                                                font.bold: true
                                                color: (index === root.selectedIndex) ? "#FFFFFF" : "#CBA158"
                                                horizontalAlignment: Text.AlignRight
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    id: itemArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.selectedIndex = index;
                                        root.currentSeconds = 0;
                                        root.playbackPos = 0;
                                        if (root.isPlaying) {
                                            player.stop();
                                            root.isPlaying = false;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ------------------------------------------
            // RIGHT COLUMN: TAKE DETAILS & EXPORT
            // ------------------------------------------
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 380
                radius: 8
                color: "#161619"
                border.color: "#26262C"
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 12

                    // Title Header with edit pencil
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        TextField {
                            id: titleInput
                            Layout.fillWidth: true
                            text: root.activeRecording ? (root.activeRecording.name || "Recording 2") : "Recording 2"
                            font.pixelSize: 16
                            font.bold: true
                            color: "#FFFFFF"
                            background: Rectangle {
                                color: titleInput.activeFocus ? "#222228" : "transparent"
                                radius: 4
                                border.color: titleInput.activeFocus ? "#CBA158" : "transparent"
                            }
                            onEditingFinished: {
                                if (stateManager) {
                                    stateManager.renameRecording(root.selectedIndex, text.trim());
                                }
                            }
                        }

                        Text {
                            text: "✏️"
                            font.pixelSize: 14
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: titleInput.forceActiveFocus()
                            }
                        }
                    }

                    // Color Gradient Slider
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 14

                        Text {
                            text: stateManager ? stateManager.strings.color : "Color"
                            font.pixelSize: 12
                            color: "#8E8E93"
                            Layout.preferredWidth: 110
                        }

                        // Gradient bar
                        Rectangle {
                            Layout.fillWidth: true
                            height: 6
                            radius: 3
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: "#FF3B30" }
                                GradientStop { position: 0.2; color: "#FF9500" }
                                GradientStop { position: 0.4; color: "#FFCC00" }
                                GradientStop { position: 0.6; color: "#34C759" }
                                GradientStop { position: 0.8; color: "#007AFF" }
                                GradientStop { position: 1.0; color: "#AF52DE" }
                            }

                            // Slider handle
                            Rectangle {
                                width: 14
                                height: 14
                                radius: 7
                                color: "#FF3B30"
                                border.color: "#FFFFFF"
                                border.width: 2
                                anchors.verticalCenter: parent.verticalCenter
                                x: Math.max(0, Math.min(parent.width - width, parent.width * 0.15))
                            }
                        }
                    }

                    // Preset
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 14
                        Text {
                            text: "Preset"
                            font.pixelSize: 12
                            color: "#8E8E93"
                            Layout.preferredWidth: 110
                        }
                        ComboBox {
                            id: presetCombo
                            Layout.fillWidth: true
                            model: ["Custom", "Podcast", "Broadcast", "Streaming", "Voice"]
                            background: Rectangle {
                                implicitHeight: 32
                                radius: 6
                                color: "#222228"
                                border.color: "#383842"
                            }
                            contentItem: Text {
                                text: presetCombo.displayText
                                font.pixelSize: 11
                                color: "#FFFFFF"
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: 10
                            }
                        }
                    }

                    // Format
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 14
                        Text {
                            text: stateManager ? stateManager.strings.format : "Format"
                            font.pixelSize: 12
                            color: "#8E8E93"
                            Layout.preferredWidth: 110
                        }
                        ComboBox {
                            id: formatCombo
                            Layout.fillWidth: true
                            model: ["WAV", "MP3", "FLAC"]
                            background: Rectangle {
                                implicitHeight: 32
                                radius: 6
                                color: "#222228"
                                border.color: "#383842"
                            }
                            contentItem: Text {
                                text: formatCombo.displayText
                                font.pixelSize: 11
                                color: "#FFFFFF"
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: 10
                            }
                        }
                    }

                    // Sample Rate
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 14
                        Text {
                            text: stateManager ? stateManager.strings.sample_rate : "Sample Rate"
                            font.pixelSize: 12
                            color: "#8E8E93"
                            Layout.preferredWidth: 110
                        }
                        ComboBox {
                            id: sampleRateCombo
                            Layout.fillWidth: true
                            model: ["48 kHz", "44.1 kHz", "96 kHz"]
                            background: Rectangle {
                                implicitHeight: 32
                                radius: 6
                                color: "#222228"
                                border.color: "#383842"
                            }
                            contentItem: Text {
                                text: sampleRateCombo.displayText
                                font.pixelSize: 11
                                color: "#FFFFFF"
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: 10
                            }
                        }
                    }

                    // Bit Rate
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 14
                        Text {
                            text: stateManager ? stateManager.strings.bit_rate : "Bit Rate"
                            font.pixelSize: 12
                            color: "#8E8E93"
                            Layout.preferredWidth: 110
                        }
                        ComboBox {
                            id: bitRateCombo
                            Layout.fillWidth: true
                            model: ["24 bits pcm", "16 bits pcm", "320 kbps"]
                            background: Rectangle {
                                implicitHeight: 32
                                radius: 6
                                color: "#222228"
                                border.color: "#383842"
                            }
                            contentItem: Text {
                                text: bitRateCombo.displayText
                                font.pixelSize: 11
                                color: "#FFFFFF"
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: 10
                            }
                        }
                    }

                    // Loudness
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 14
                        Text {
                            text: stateManager ? stateManager.strings.loudness : "Loudness"
                            font.pixelSize: 12
                            color: "#8E8E93"
                            Layout.preferredWidth: 110
                        }
                        ComboBox {
                            id: loudnessCombo
                            Layout.fillWidth: true
                            model: ["Off", "-14 LUFS (Spotify/YouTube)", "-16 LUFS (Apple)", "-19 LUFS (Voice)"]
                            background: Rectangle {
                                implicitHeight: 32
                                radius: 6
                                color: "#222228"
                                border.color: "#383842"
                            }
                            contentItem: Text {
                                text: loudnessCombo.displayText
                                font.pixelSize: 11
                                color: "#FFFFFF"
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: 10
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    // Action Buttons (Delete & Export)
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        // Delete button
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 36
                            radius: 6
                            color: delMouse.down ? "#661414" : (delMouse.containsMouse ? "#8F1D1D" : "#7E1919")

                            Text {
                                anchors.centerIn: parent
                                text: stateManager ? stateManager.strings.delete_take : "Delete"
                                font.pixelSize: 12
                                font.bold: true
                                color: "#FFFFFF"
                            }

                            MouseArea {
                                id: delMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (stateManager) {
                                        stateManager.deleteRecording(root.selectedIndex);
                                        root.selectedIndex = Math.max(0, root.selectedIndex - 1);
                                    }
                                }
                            }
                        }

                        // Export button
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 36
                            radius: 6
                            color: expMouse.down ? "#146332" : (expMouse.containsMouse ? "#21994B" : "#1B803E")

                            Text {
                                anchors.centerIn: parent
                                text: stateManager ? stateManager.strings.export_take : "Export"
                                font.pixelSize: 12
                                font.bold: true
                                color: "#FFFFFF"
                            }

                            MouseArea {
                                id: expMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var safeName = (titleInput.text.trim() || "Recording").replace(/[^a-zA-Z0-9_\-]/g, "_");
                                    var ext = formatCombo.currentText.toLowerCase();
                                    exportTakeDialog.currentFile = "file://" + safeName + "." + ext;
                                    exportTakeDialog.open();
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ==========================================
    // EMPTY STATE: WHEN NO RECORDINGS OR NO MICROSD
    // ==========================================
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 28
        spacing: 20
        visible: Boolean(!root.recordingsList || root.recordingsList.length === 0)

        // Storage Bar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 74
            radius: 10
            color: "#18181C"
            border.color: "#28282E"
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 14

                Text { text: "💾"; font.pixelSize: 22 }

                ColumnLayout {
                    spacing: 4
                    Layout.fillWidth: true

                    RowLayout {
                        Text {
                            text: (stateManager ? (stateManager.storageLabel || "Almacenamiento") : "Almacenamiento")
                            font.pixelSize: 13
                            font.bold: true
                            color: "#FFFFFF"
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: (stateManager ? stateManager.sdCardUsed : "0 GB") + " / " + (stateManager ? stateManager.sdCardTotal : "5 GB")
                            font.pixelSize: 12
                            color: "#CBA158"
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 6
                        radius: 3
                        color: "#282830"
                        Rectangle {
                            width: Math.max(4, parent.width * ((stateManager ? stateManager.sdCardPercent : 0) / 100.0))
                            height: parent.height
                            radius: 3
                            color: "#CBA158"
                        }
                    }
                }
            }
        }

        // Center Empty State Box
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 12
            color: "#141417"
            border.color: "#24242A"
            border.width: 1

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 14
                width: Math.min(460, parent.width - 40)

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 64
                    height: 64
                    radius: 32
                    color: "#1C1C22"
                    border.color: "#353540"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: (stateManager && stateManager.hasMicroSD) ? "🎙️" : "💾"
                        font.pixelSize: 28
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: (stateManager && stateManager.hasMicroSD)
                          ? (stateManager.transferModeActive 
                             ? (stateManager.strings ? stateManager.strings.no_recordings_title : "No hay grabaciones en la tarjeta")
                             : "Modo Transferencia Desactivado")
                          : (stateManager && stateManager.strings ? stateManager.strings.no_microsd_title : "No hay tarjeta MicroSD instalada")
                    font.pixelSize: 16
                    font.bold: true
                    color: "#FFFFFF"
                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    text: (stateManager && stateManager.hasMicroSD)
                          ? (stateManager.transferModeActive 
                             ? (stateManager.strings ? stateManager.strings.no_recordings_desc : "Las grabaciones realizadas con el botón REC en tu RØDECaster aparecerán aquí.")
                             : (stateManager && stateManager.language === "en" ? "Enable transfer mode so your system mounts the MicroSD card to explore your takes." : "Activa el modo de transferencia para que tu sistema monte la tarjeta MicroSD y puedas explorar tus tomas."))
                          : (stateManager && stateManager.strings ? stateManager.strings.no_microsd_desc : "La ranura de tarjeta MicroSD de tu RØDECaster está vacía. Inserta una tarjeta MicroSD para grabar tomas y transferirlas a tu PC.")
                    font.pixelSize: 12
                    color: "#8E8E93"
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }

                Item { height: 6 }

                Text {
                    visible: Boolean(stateManager && stateManager.transferModeActive && stateManager.transferStatusText)
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    text: stateManager ? stateManager.transferStatusText : ""
                    font.pixelSize: 11
                    color: "#CBA158"
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }

                // Leave transfer mode (also reachable from ⏏ in the sidebar)
                Rectangle {
                    visible: Boolean(stateManager && stateManager.transferModeActive)
                    Layout.alignment: Qt.AlignHCenter
                    width: exitTLabel.implicitWidth + 36
                    height: 38
                    radius: 8
                    color: exitTMouse.containsMouse ? "#3A3A44" : "#2A2A32"
                    border.color: "#4A4A55"
                    opacity: (stateManager && stateManager.transferExiting) ? 0.5 : 1.0

                    Text {
                        id: exitTLabel
                        anchors.centerIn: parent
                        text: "⏏  " + (stateManager && stateManager.strings ? stateManager.strings.transfer_mode_exit : "Salir del Modo Transferencia")
                        font.pixelSize: 12
                        font.bold: true
                        color: "#FFFFFF"
                    }

                    MouseArea {
                        id: exitTMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: !(stateManager && stateManager.transferExiting)
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (stateManager) stateManager.exitTransferMode()
                    }
                }

                // Action button if microSD is present to activate transfer
                Rectangle {
                    visible: Boolean(stateManager && stateManager.hasMicroSD && !stateManager.transferModeActive)
                    Layout.alignment: Qt.AlignHCenter
                    width: 200
                    height: 38
                    radius: 8
                    color: tBtnMouse.containsMouse ? "#DFB666" : "#CBA158"

                    Text {
                        anchors.centerIn: parent
                        text: stateManager && stateManager.language === "en" ? "Enable USB Transfer" : "Activar Transferencia USB"
                        font.pixelSize: 12
                        font.bold: true
                        color: "#121214"
                    }

                    MouseArea {
                        id: tBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (stateManager) stateManager.enterTransferMode();
                        }
                    }
                }
            }
        }
    }
}
