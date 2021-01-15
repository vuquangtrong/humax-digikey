import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

Window {
    title: qsTr("DigiKey Viewer")
    visible: true

    width: 1920
    height: 1080

    //visibility: Window.FullScreen

    TabBar {
        id: tabBar
        width: parent.width

        Repeater {
            model: [
                qsTr("Map Viewer"),
                qsTr("Distance History"),
            ]
            TabButton {
                text: modelData
                font.pointSize: 12
            }
        }
    }

    StackLayout {
        property int margin: 6

        anchors.fill: parent
        anchors.margins: margin
        anchors.topMargin: tabBar.height + margin

        currentIndex: tabBar.currentIndex

        DemoTab {
        }

        DistanceTab {
        }
    }
}
