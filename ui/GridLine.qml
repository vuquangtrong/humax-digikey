import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import QtQuick.Shapes 1.12

Shape {
    id: grid
    property int lineSpace: 100 // px 
    property string lineColor: "red"
    property double lineWidthFactor: 1.0

    // Shape does not accept Item
    // while Repeater does not accept Path
    Repeater {
        model: (grid.width / lineSpace) + 1
        Item {
            property ShapePath line: ShapePath {
                strokeWidth: 1.0 / lineWidthFactor
                strokeColor: lineColor
                startX: 0; startY: lineSpace * index
                PathLine { x: grid.width; y: lineSpace * index } 
            }

            Component.onCompleted: {
                grid.data.push(line)
            }
        }
    }

    Repeater {
        model: (grid.width / lineSpace) + 1
        Item {
            property ShapePath line: ShapePath {
                strokeWidth: 1.0 / lineWidthFactor
                strokeColor: lineColor
                startX: lineSpace * index; startY: 0
                PathLine { x: lineSpace * index; y: grid.height } 
            }

            Component.onCompleted: {
                grid.data.push(line)
            }
        }
    }
}