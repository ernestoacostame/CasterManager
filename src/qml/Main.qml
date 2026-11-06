import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: window
    visible: true
    width: 1180
    height: 740
    minimumWidth: 980
    minimumHeight: 620
    title: "CasterManager"
    color: "#121214"

    // Toast Notification Banner
    Rectangle {
        id: toast
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 30
        width: toastText.implicitWidth + 40
        height: 38
        radius: 19
        color: "#2C2C30"
        border.color: "#CBA158"
        border.width: 1
        z: 1000
        opacity: 0.0
        visible: opacity > 0

        Text {
            id: toastText
            anchors.centerIn: parent
            text: ""
            font.pixelSize: 12
            font.weight: Font.Medium
            color: "#FFFFFF"
        }

        Timer {
            id: toastTimer
            interval: 2200
            onTriggered: {
                toastAnimOut.start();
            }
        }

        NumberAnimation {
            id: toastAnimIn
            target: toast
            property: "opacity"
            from: 0.0
            to: 1.0
            duration: 180
        }

        NumberAnimation {
            id: toastAnimOut
            target: toast
            property: "opacity"
            from: 1.0
            to: 0.0
            duration: 250
        }

        function showMessage(msg) {
            toastText.text = msg;
            toastAnimIn.start();
            toastTimer.restart();
        }
    }

    Connections {
        target: stateManager
        function onToastMessage(msg) {
            toast.showMessage(msg);
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // Sidebar (Device Info, Firmware, SD Card)
        Sidebar {
            Layout.fillHeight: true
        }

        // Main Content Area
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // Header (CasterManager brand, Profile, Back button)
            Header {
                Layout.fillWidth: true
                onBackClicked: {
                    toast.showMessage(stateManager ? stateManager.strings.home : "Inicio");
                }
                onSettingsClicked: {
                    settingsModalOverlay.open();
                }
                onEditProfileClicked: {
                    profileModalOverlay.open();
                }
            }

            // Body: Router across views when connected, DisconnectedView otherwise
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // 1. Disconnected view
                DisconnectedView {
                    anchors.fill: parent
                    visible: !stateManager || !stateManager.connected
                }

                // 2. Home Hub View (4 cards)
                HomeHubView {
                    anchors.fill: parent
                    visible: stateManager && stateManager.connected && stateManager.currentView === "home"
                }

                // 3. Audio Setup View (Live Faders, Channel Strips, Input pool)
                AudioSetupView {
                    anchors.fill: parent
                    visible: stateManager && stateManager.connected && stateManager.currentView === "audio_setup"
                }

                // 4. Device Config View (Outputs, Display & Brightness, System & MIDI)
                DeviceConfigView {
                    anchors.fill: parent
                    visible: stateManager && stateManager.connected && stateManager.currentView === "device_config"
                }

                // 5. SMART Pads View (Sound, FX Effects, Mixer, MIDI)
                SmartPadsView {
                    anchors.fill: parent
                    visible: stateManager && stateManager.connected && stateManager.currentView === "smartpads"
                }

                // 6. Recordings View (MicroSD storage, Mass storage transfer, Live REC)
                RecordingsView {
                    anchors.fill: parent
                    visible: stateManager && stateManager.connected && stateManager.currentView === "recordings"
                }
            }
        }
    }

    // Show Profile Edit Modal Overlay (Centered, Full Window, Non-Clipped)
    Rectangle {
        id: profileModalOverlay
        objectName: "profileModalOverlay"
        anchors.fill: parent
        color: "#99000000"
        z: 9999
        visible: false

        // Clicking the darkened backdrop dismisses the modal
        MouseArea {
            anchors.fill: parent
            onClicked: profileModalOverlay.visible = false
        }

        Rectangle {
            id: profileModalBox
            anchors.centerIn: parent
            width: 380
            height: 250
            radius: 12
            color: "#222226"
            border.color: "#3D3D45"
            border.width: 1

            // Absorb clicks inside the dialog so it doesn't dismiss
            MouseArea {
                anchors.fill: parent
                onClicked: {}
            }

            property int selectedIconIdx: stateManager ? stateManager.showIcon : 0
            readonly property var iconColors: ["#CBA158", "#FF3C3C", "#28C850", "#3C96FF", "#A050E6", "#FF8C28"]

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 16

                Text {
                    text: stateManager ? stateManager.strings.edit_profile : "Editar Perfil del Show"
                    font.pixelSize: 16
                    font.bold: true
                    color: "#FFFFFF"
                }

                TextField {
                    id: showNameInput
                    Layout.fillWidth: true
                    font.pixelSize: 14
                    color: "#FFFFFF"
                    placeholderText: stateManager ? stateManager.strings.show_placeholder : "Nombre del show..."

                    background: Rectangle {
                        color: "#2C2C32"
                        radius: 6
                        border.color: showNameInput.activeFocus ? "#CBA158" : "#3D3D45"
                    }
                }

                // Avatar Color Selection
                RowLayout {
                    spacing: 12
                    Text {
                        text: stateManager ? stateManager.strings.avatar_color : "Color / Icono:"
                        font.pixelSize: 12
                        color: "#8E8E93"
                    }
                    Row {
                        spacing: 8
                        Repeater {
                            model: profileModalBox.iconColors
                            Rectangle {
                                width: 28
                                height: 28
                                radius: 14
                                color: modelData
                                border.color: profileModalBox.selectedIconIdx === index ? "#FFFFFF" : "#444444"
                                border.width: profileModalBox.selectedIconIdx === index ? 2.5 : 1

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        profileModalBox.selectedIconIdx = index;
                                    }
                                }
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                RowLayout {
                    Layout.alignment: Qt.AlignRight
                    spacing: 12

                    Button {
                        text: stateManager ? stateManager.strings.cancel : "Cancelar"
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                        onClicked: profileModalOverlay.visible = false
                    }

                    Button {
                        text: stateManager ? stateManager.strings.save : "Guardar"
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                        contentItem: Text {
                            text: parent.text
                            font.bold: true
                            color: "#FFFFFF"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            implicitWidth: 90
                            implicitHeight: 34
                            radius: 6
                            color: parent.down ? "#A6823C" : (parent.hovered ? "#DAB265" : "#CBA158")
                        }
                        onClicked: {
                            if (stateManager) {
                                if (showNameInput.text.trim()) {
                                    stateManager.updateShowName(showNameInput.text.trim());
                                }
                                stateManager.updateShowIcon(profileModalBox.selectedIconIdx);
                            }
                            profileModalOverlay.visible = false;
                        }
                    }
                }
            }
        }

        function open() {
            showNameInput.text = stateManager ? stateManager.showName : "";
            profileModalBox.selectedIconIdx = stateManager ? stateManager.showIcon : 0;
            profileModalOverlay.visible = true;
            showNameInput.forceActiveFocus();
        }
    }

    // Application Settings Modal Overlay (Language & Preferences)
    Rectangle {
        id: settingsModalOverlay
        objectName: "settingsModalOverlay"
        anchors.fill: parent
        color: "#99000000"
        z: 9999
        visible: false

        function open() {
            visible = true;
        }

        function close() {
            visible = false;
        }

        MouseArea {
            anchors.fill: parent
            onClicked: settingsModalOverlay.close()
        }

        Rectangle {
            id: settingsModalBox
            anchors.centerIn: parent
            width: 440
            height: 300
            radius: 12
            color: "#222226"
            border.color: "#3D3D45"
            border.width: 1

            MouseArea {
                anchors.fill: parent
                onClicked: {}
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 16

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: stateManager ? stateManager.strings.settings : "Configuración"
                        font.pixelSize: 18
                        font.bold: true
                        color: "#FFFFFF"
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        width: 28
                        height: 28
                        radius: 14
                        color: closeHover.containsMouse ? "#333338" : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            font.pixelSize: 14
                            color: closeHover.containsMouse ? "#FFFFFF" : "#8E8E93"
                        }

                        MouseArea {
                            id: closeHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: settingsModalOverlay.close()
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: "#333338"
                }

                // Language selection section
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: stateManager ? stateManager.strings.app_language : "Idioma de la aplicación"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: "#CBA158"
                    }

                    Text {
                        text: stateManager ? stateManager.strings.language_desc : "Selecciona el idioma de la interfaz:"
                        font.pixelSize: 12
                        color: "#8E8E93"
                    }

                    RowLayout {
                        spacing: 16
                        Layout.fillWidth: true

                        // Spanish button
                        Rectangle {
                            Layout.fillWidth: true
                            height: 52
                            radius: 8
                            color: (stateManager && stateManager.language === "es") ? "#2C271E" : (esHover.containsMouse ? "#2C2C32" : "#1A1A1D")
                            border.color: (stateManager && stateManager.language === "es") ? "#CBA158" : "#323238"
                            border.width: (stateManager && stateManager.language === "es") ? 2 : 1

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 10

                                Text {
                                    text: "🇪🇸"
                                    font.pixelSize: 20
                                }

                                Text {
                                    text: "Español"
                                    font.pixelSize: 13
                                    font.weight: (stateManager && stateManager.language === "es") ? Font.Bold : Font.Normal
                                    color: (stateManager && stateManager.language === "es") ? "#FFFFFF" : "#C8C8CC"
                                }
                            }

                            MouseArea {
                                id: esHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (stateManager) stateManager.setLanguage("es");
                                }
                            }
                        }

                        // English button
                        Rectangle {
                            Layout.fillWidth: true
                            height: 52
                            radius: 8
                            color: (stateManager && stateManager.language === "en") ? "#2C271E" : (enHover.containsMouse ? "#2C2C32" : "#1A1A1D")
                            border.color: (stateManager && stateManager.language === "en") ? "#CBA158" : "#323238"
                            border.width: (stateManager && stateManager.language === "en") ? 2 : 1

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 10

                                Text {
                                    text: "🇬🇧"
                                    font.pixelSize: 20
                                }

                                Text {
                                    text: "English"
                                    font.pixelSize: 13
                                    font.weight: (stateManager && stateManager.language === "en") ? Font.Bold : Font.Normal
                                    color: (stateManager && stateManager.language === "en") ? "#FFFFFF" : "#C8C8CC"
                                }
                            }

                            MouseArea {
                                id: enHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (stateManager) stateManager.setLanguage("en");
                                }
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                // Footer button
                Button {
                    Layout.alignment: Qt.AlignRight
                    text: stateManager ? stateManager.strings.close : "Cerrar"
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                    contentItem: Text {
                        text: parent.text
                        color: "#FFFFFF"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        implicitWidth: 90
                        implicitHeight: 34
                        radius: 6
                        color: parent.down ? "#A6823C" : (parent.hovered ? "#DAB265" : "#CBA158")
                    }
                    onClicked: settingsModalOverlay.close()
                }
            }
        }
    }
}

