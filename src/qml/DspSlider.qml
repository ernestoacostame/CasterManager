import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

// Reusable labelled slider bound to a DSP parameter of the active channel.
ColumnLayout {
    id: ds

    property string label: ""
    property string prop: ""
    property real defVal: 0.5
    property real from: 0.0
    property real to: 1.0
    property real stepSize: 0.01
    property color accent: "#CBA158"
    property bool compact: false
    // Formatter for the value badge
    property var format: function(v) { return Math.round(v * 100) + "%"; }

    readonly property real boundValue: {
        let d = (stateManager && stateManager.currentDsp) ? stateManager.currentDsp : null;
        return (d && d[ds.prop] !== undefined && d[ds.prop] !== null) ? d[ds.prop] : ds.defVal;
    }

    Layout.fillWidth: true
    spacing: 4

    RowLayout {
        Layout.fillWidth: true
        Text {
            text: ds.label
            font.pixelSize: ds.compact ? 10 : 11
            color: ds.compact ? "#8E8E93" : "#AAAAAA"
        }
        Item { Layout.fillWidth: true }
        Text {
            text: ds.format(slider.value)
            font.pixelSize: ds.compact ? 11 : 12
            font.bold: true
            color: ds.accent
        }
    }

    Slider {
        id: slider
        Layout.fillWidth: true
        from: ds.from
        to: ds.to
        stepSize: ds.stepSize
        value: ds.boundValue
        onMoved: if (stateManager) stateManager.setDspParameter(ds.prop, value)
    }
}
