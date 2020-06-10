import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

Window {
    title: qsTr("DigiKey Viewer")
    visible: true

    width: 1920
    height: 1080
    minimumWidth: 1280
    minimumHeight: 720

    TabBar {
        id: tabBar
        width: parent.width

        TabButton {
            text: qsTr("Demo")
        }

        TabButton {
            text: qsTr("Distance")
        }

        TabButton {
            text: qsTr("CAN Data")
        }

        TabButton {
            text: qsTr("CIR 1")
        }

        TabButton {
            text: qsTr("CIR 2")
        }
    }

    StackLayout {
        property int margin: 6

        anchors.fill: parent
        anchors.margins: margin
        anchors.topMargin: tabBar.height + margin

        currentIndex: tabBar.currentIndex

        DemoTab {
            id: demoTab
        }

        DistanceTab {
            id: distanceTab
        }
    }
    /*
    Component.onCompleted: {
        console.log("DigiKey", DigiKey)
    }
    */
}
