import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property int cols: stateManager ? stateManager.padCols : 2
    property int rows: stateManager ? stateManager.padRows : 3
    property var padsData: stateManager ? stateManager.currentPads : []
    property int selectedIndex: stateManager ? stateManager.selectedPadIndex : 0

    implicitWidth: grid.width
    implicitHeight: grid.height

    Grid {
        id: grid
        columns: root.cols
        spacing: 12

        Repeater {
            model: root.padsData

            PadButton {
                padIndex: index
                padData: modelData
                isSelected: root.selectedIndex === index

                onClicked: {
                    stateManager.selectPad(index);
                }

                onTriggered: {
                    stateManager.triggerPad(index);
                }
            }
        }
    }
}

