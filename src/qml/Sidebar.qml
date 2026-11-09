import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {
    id: root
    width: 250
    color: "#18181A"

    // Right divider line
    Rectangle {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: 1
        color: "#252528"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 20

        // Device List Section (Supports Single or Multiple Devices)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 10

            // Header when multiple devices are connected
            RowLayout {
                visible: Boolean(stateManager && stateManager.connectedDevices && stateManager.connectedDevices.length > 1)
                Layout.fillWidth: true

                Text {
                    text: (stateManager && stateManager.language === "es" ? "Dispositivos RØDE (" : "RØDE Devices (") + (stateManager && stateManager.connectedDevices ? stateManager.connectedDevices.length : 0) + ")"
                    font.pixelSize: 11
                    font.bold: true
                    color: "#A0A0A5"
                }
            }

            // Multiple Devices Repeater
            Repeater {
                model: (stateManager && stateManager.connectedDevices && stateManager.connectedDevices.length > 0) 
                       ? stateManager.connectedDevices 
                       : [null]

                // Device Card Item
                Rectangle {
                    id: devCard
                    readonly property bool hasRealDevice: modelData !== null
                    readonly property bool isSelectedDevice: hasRealDevice && (index === (stateManager ? stateManager.selectedDeviceIndex : 0))

                    Layout.fillWidth: true
                    Layout.preferredHeight: (!hasRealDevice || isSelectedDevice) ? 140 : 74
                    radius: 10
                    color: isSelectedDevice ? "#212124" : (devArea.containsMouse ? "#27272C" : "#1B1B1E")
                    border.color: isSelectedDevice ? "#CBA158" : (devArea.containsMouse ? "#44444C" : "#2C2C30")
                    border.width: isSelectedDevice ? 1.5 : 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10

                        // Device Header Row (Icon + Name + Status + Switch Badge)
                        RowLayout {
                            spacing: 10

                            // Device Hardware Icon
                            Rectangle {
                                width: 40
                                height: 40
                                radius: 8
                                color: "#161618"
                                border.color: isSelectedDevice ? "#CBA158" : "#2C2C30"
                                border.width: 1
                                clip: true

                                Image {
                                    anchors.centerIn: parent
                                    width: 32
                                    height: 32
                                    source: "../../assets/rodecaster.svg"
                                    fillMode: Image.PreserveAspectFit
                                    mipmap: true
                                    smooth: true
                                    sourceSize.width: 64
                                    sourceSize.height: 64
                                }
                            }

                            ColumnLayout {
                                spacing: 4
                                Layout.fillWidth: true

                                Text {
                                    text: devCard.hasRealDevice ? modelData.display_name : (stateManager ? stateManager.modelName : "RØDECaster")
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: "#FFFFFF"
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    Row {
                                        spacing: 5
                                        Layout.alignment: Qt.AlignVCenter
                                        Rectangle {
                                            width: 6
                                            height: 6
                                            radius: 3
                                            anchors.verticalCenter: parent.verticalCenter
                                            color: (stateManager && stateManager.connected && devCard.hasRealDevice) ? "#34C759" : "#FF3B30"
                                        }
                                        Text {
                                            text: (stateManager && stateManager.connected && devCard.hasRealDevice)
                                                  ? (devCard.isSelectedDevice 
                                                     ? (stateManager ? stateManager.strings.connected : "Conectada") 
                                                     : (stateManager && stateManager.language === "es" ? "Disponible" : "Available"))
                                                  : (stateManager ? stateManager.strings.disconnected : "Desconectada")
                                            font.pixelSize: 10
                                            color: (stateManager && stateManager.connected && devCard.hasRealDevice) ? "#34C759" : "#FF453A"
                                        }
                                    }

                                    Item { Layout.fillWidth: true }

                                    // Active / Switch Badge
                                    Rectangle {
                                        visible: Boolean(stateManager && stateManager.connectedDevices && stateManager.connectedDevices.length > 1)
                                        width: devCard.isSelectedDevice ? 46 : 54
                                        height: 16
                                        radius: 4
                                        color: devCard.isSelectedDevice ? "#3A2E16" : "#25252A"
                                        border.color: devCard.isSelectedDevice ? "#CBA158" : "#3E3E48"
                                        border.width: 1

                                        Text {
                                            anchors.centerIn: parent
                                            text: devCard.isSelectedDevice 
                                                  ? (stateManager && stateManager.language === "es" ? "ACTIVA" : "ACTIVE")
                                                  : (stateManager && stateManager.language === "es" ? "CAMBIAR" : "SWITCH")
                                            font.pixelSize: 8
                                            font.bold: true
                                            color: devCard.isSelectedDevice ? "#CBA158" : "#A0A0A5"
                                        }
                                    }
                                }

                                Text {
                                    visible: devCard.isSelectedDevice || !devCard.hasRealDevice
                                    text: (stateManager ? stateManager.strings.firmware : "Firmware") + " " + (stateManager ? stateManager.firmwareVersion : "1.7.7")
                                    font.pixelSize: 10
                                    color: "#8E8E93"
                                }
                            }
                        }

                        // SD Card Storage Meter (Shown for active device)
                        ColumnLayout {
                            visible: devCard.isSelectedDevice || !devCard.hasRealDevice
                            Layout.fillWidth: true
                            spacing: 6

                            RowLayout {
                                Text {
                                    text: "💾 " + (stateManager ? (stateManager.storageLabel || stateManager.strings.microsd) : "MicroSD")
                                    font.pixelSize: 11
                                    color: "#9A9A9E"
                                }

                                // Eject / Unmount Button when Transfer Mode is active
                                Rectangle {
                                    visible: Boolean(stateManager && stateManager.transferModeActive && devCard.isSelectedDevice)
                                    width: 20
                                    height: 20
                                    radius: 4
                                    color: ejectArea.containsMouse ? "#442A2A" : "#282830"
                                    border.color: "#CBA158"
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: "⏏"
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: "#CBA158"
                                    }

                                    MouseArea {
                                        id: ejectArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (stateManager) stateManager.exitTransferMode();
                                        }
                                    }
                                }

                                Item { Layout.fillWidth: true }
                                Text {
                                    text: (stateManager ? stateManager.sdCardUsed : "0 GB") + " / " + (stateManager ? stateManager.sdCardTotal : "119 GB")
                                    font.pixelSize: 10
                                    color: "#8E8E93"
                                }
                            }

                            // Progress Bar
                            Rectangle {
                                Layout.fillWidth: true
                                height: 4
                                radius: 2
                                color: "#323236"

                                Rectangle {
                                    width: Math.max(4, parent.width * ((stateManager ? stateManager.sdCardPercent : 0) / 100.0))
                                    height: parent.height
                                    radius: 2
                                    color: "#CBA158"
                                }
                            }
                        }
                    }

                    // Click area to switch active device if not already selected
                    MouseArea {
                        id: devArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: (!devCard.isSelectedDevice && devCard.hasRealDevice) ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            if (!devCard.isSelectedDevice && devCard.hasRealDevice && stateManager) {
                                stateManager.selectDevice(index);
                            }
                        }
                    }
                }
            }

            // MicroSD Removable Storage Card (matches RØDECaster App - shown when card is present)
            Rectangle {
                id: sdCardEntry
                visible: Boolean(!stateManager || stateManager.hasMicroSD)
                readonly property bool isSelectedView: (stateManager && stateManager.currentView === "recordings")
                Layout.fillWidth: true
                height: 58
                radius: 8
                color: isSelectedView ? "#24242A" : (sdHover.containsMouse ? "#202024" : "#19191C")
                border.color: isSelectedView ? "#CBA158" : (sdHover.containsMouse ? "#3A3A42" : "#28282E")
                border.width: isSelectedView ? 1.5 : 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    // MicroSD black badge with white RØDE text
                    Rectangle {
                        width: 36
                        height: 36
                        radius: 6
                        color: "#0D0D0F"
                        border.color: "#35353C"
                        border.width: 1

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 1
                            Text {
                                text: "RØDE"
                                font.pixelSize: 8
                                font.bold: true
                                color: "#FFFFFF"
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: "SD"
                                font.pixelSize: 7
                                font.bold: true
                                color: "#CBA158"
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }

                    ColumnLayout {
                        spacing: 2
                        Layout.fillWidth: true

                        Text {
                            text: "microSD"
                            font.pixelSize: 12
                            font.bold: true
                            color: sdCardEntry.isSelectedView ? "#CBA158" : "#FFFFFF"
                        }

                        Text {
                            text: stateManager ? stateManager.strings.removable_storage : "Removable Storage"
                            font.pixelSize: 10
                            color: "#8E8E93"
                        }
                    }

                    // Eject / Mount indicator
                    Rectangle {
                        visible: Boolean(stateManager && stateManager.isMicroSDMounted)
                        width: 18
                        height: 18
                        radius: 3
                        color: "#282830"
                        border.color: "#CBA158"
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "⏏"
                            font.pixelSize: 10
                            font.bold: true
                            color: "#CBA158"
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (stateManager) stateManager.exitTransferMode();
                            }
                        }
                    }
                }

                MouseArea {
                    id: sdHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (stateManager) {
                            stateManager.currentView = "recordings";
                        }
                    }
                }
            }
        }

        // Permission warning banner if permission is not set
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 110
            radius: 8
            color: "#2C1B1B"
            border.color: "#8A3030"
            visible: stateManager && stateManager.permissionError

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6

                Text {
                    text: stateManager ? stateManager.strings.usb_permission_required : "⚠️ Permiso USB requerido"
                    font.pixelSize: 12
                    font.bold: true
                    color: "#FFA2A2"
                }

                Text {
                    text: stateManager ? stateManager.strings.usb_permission_hint : "Para interactuar con el dispositivo, ejecuta:\n./install.sh en la carpeta del programa"
                    font.pixelSize: 10
                    color: "#D0D0D0"
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
            }
        }

        Item { Layout.fillHeight: true }

        // Bottom quick info
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#252528"
            }

            RowLayout {
                Text {
                    text: "CasterManager"
                    font.pixelSize: 11
                    font.bold: true
                    color: "#777777"
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: "v1.2 Linux"
                    font.pixelSize: 10
                    color: "#555555"
                }
            }
        }
    }
}

