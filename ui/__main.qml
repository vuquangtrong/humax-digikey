
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

Window {
    title: qsTr("DigiKey Viewer")
    visible: true

    width: 1920
    height: 1080

    TabBar {
        id: tabBar
        width: parent.width

        Repeater {
            model: [
                qsTr("Map Viewer"),
            ]
            TabButton {
                text: modelData
            }
        }
    }

    StackLayout {
        id: tabContent
        anchors.fill: parent
        anchors.margins: 6
        anchors.topMargin: tabBar.height
        currentIndex: tabBar.currentIndex
        clip: true

        MainView {
        }
    }
}