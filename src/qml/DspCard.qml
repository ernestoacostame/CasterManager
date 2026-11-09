import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

// Card container for one DSP processor (icon, title, description, ON/OFF switch).
Rectangle {
    id: card

    property string icon: ""
    property string title: ""
    property string description: ""
    property string onProp: ""          // bool DSP property toggled by the switch ("" = no switch)
    property bool focused: false
    default property alias content: body.data

    readonly property bool isOn: {
        if (onProp === "") return true;
        let d = (stateManager && stateManager.currentDsp) ? stateManager.currentDsp : null;
        return (d && d[onProp] !== undefined) ? Boolean(d[onProp]) : true;
    }

    Layout.fillWidth: true
    implicitHeight: col.implicitHeight + 32
    radius: 12
    color: "#18181C"
    border.color: card.focused ? "#FFFFFF" : "#282830"
    border.width: card.focused ? 2 : 1

    ColumnLayout {
        id: col
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 16
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Text { text: card.icon; font.pixelSize: 16 }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Text { text: card.title; font.pixelSize: 13; font.bold: true; color: "#FFFFFF" }
                Text {
                    text: card.description
                    font.pixelSize: 10
                    color: "#8E8E93"
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
            Switch {
                visible: card.onProp !== ""
                checked: card.isOn
                onToggled: if (stateManager) stateManager.setDspParameter(card.onProp, checked)
            }
        }

        ColumnLayout {
            id: body
            Layout.fillWidth: true
            spacing: 10
            opacity: card.isOn ? 1.0 : 0.45
            enabled: card.isOn
        }
    }
}

