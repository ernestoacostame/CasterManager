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
                    toast.showMessage("Inicio");
                }
                onSettingsClicked: {
                    toast.showMessage("Configuración del dispositivo");
                }
                onEditProfileClicked: {
                    profileModalOverlay.open();
                }
            }

            // Body: SmartPadsView when connected, DisconnectedView otherwise
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                SmartPadsView {
                    anchors.fill: parent
                    visible: stateManager && stateManager.connected
                }

                DisconnectedView {
                    anchors.fill: parent
                    visible: !stateManager || !stateManager.connected
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
                    text: "Editar Perfil del Show"
                    font.pixelSize: 16
                    font.bold: true
                    color: "#FFFFFF"
                }

                TextField {
                    id: showNameInput
                    Layout.fillWidth: true
                    font.pixelSize: 14
                    color: "#FFFFFF"
                    placeholderText: "Nombre del show..."

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
                        text: "Color / Icono:"
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
                        text: "Cancelar"
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                        onClicked: profileModalOverlay.visible = false
                    }

                    Button {
                        text: "Guardar"
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
}

