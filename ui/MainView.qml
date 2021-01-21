import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import QtQuick.Shapes 1.12
import Location 1.0
import Anchor 1.0
import BLE 1.0
import Params 1.0
import Performance 1.0

Item {
    id: root
    width: 1920
    height: 1080

    readonly property real transitionDuration: 200 // ms

    RowLayout {
        anchors.fill: parent    
        spacing: 0

        // view
        Item {
            id: view
            Layout.fillWidth: true
            Layout.fillHeight: true

            Item {
                id: canvas 
                property double scaleFactor: canvas_transform.xScale

                /* 1px = 1cm */
                /* input unit is meter */

                /*** TRANSLATE IS USED FOR OBJECTS ***/
                function translateX(obj, ix) {
                    return ix*100 + (canvas.width- obj.width) / 2
                }

                function translateY(obj, iy) {
                    // y is reversed with screen y-axis
                    return -iy*100 + (canvas.height - obj.height) / 2
                }
                
                /*** CONVERT IS USED FOR POINTS IN SHAPE PATH */
                function convertX(ix) {
                    return ix + (canvas.width / 2)
                }

                function convertY(iy) {
                    return iy + (canvas.height / 2)
                }

                /* Encapsulate graph */
                width: 3000 // cm
                height: 3000 // cm

                /* Move "camera" to center */
                x: (-width + view.width) / 2
                y: (-height + view.height) / 2 + 120

                
                Image {
                    id: car
                    property double car_width: 1.8 // cm
                    property double car_height: 4.6 // cm
                    width: car_width*100
                    height: car_height*100
                    x: canvas.translateX(car, car_width/2-0.4)
                    y: canvas.translateY(car, car_height/2-0.4)
                    source: "car.png"
                    opacity: 0.25
                }
                
                GridLine {
                    anchors.fill: parent // must be the same size with canvas
                    opacity: 0.25
                    lineSpace: 100 // cm
                    lineColor: "red"
                    lineWidthFactor: canvas.scaleFactor
                }

                GridLine {
                    anchors.fill: parent // must be the same size with canvas
                    opacity: 0.1
                    lineSpace: 50 // cm 
                    lineColor: "red"
                    lineWidthFactor: canvas.scaleFactor
                    visible: canvas.scaleFactor >= 0.25 && canvas.scaleFactor < 0.5
                }

                GridLine {
                    anchors.fill: parent // must be the same size with canvas
                    opacity: 0.1
                    lineSpace: 20 // cm 
                    lineColor: "blue"
                    lineWidthFactor: canvas.scaleFactor
                    visible: canvas.scaleFactor >= 0.5 && canvas.scaleFactor < 2
                }

                GridLine {
                    anchors.fill: parent // must be the same size with canvas
                    opacity: 0.1
                    lineSpace: 10 // cm 
                    lineColor: "blue"
                    lineWidthFactor: canvas.scaleFactor
                    visible: canvas.scaleFactor >= 2
                }

                // Reference points
                Repeater {
                    property var refer_points: []

                    model: refer_points

                    Rectangle {
                        id: refer_point
                        opacity: 0.25
                        width: 6 / canvas.scaleFactor
                        height: 6 / canvas.scaleFactor
                        radius: 3 / canvas.scaleFactor
                        color: "purple"
                        x: canvas.translateX(refer_point, modelData.px)
                        y: canvas.translateY(refer_point, modelData.py)

                        Text {
                            id: refer_point_name
                            x: parent.width
                            y: parent.height
                            color: "purple"
                            text: "" + modelData.px + "," + modelData.py
                        }
                    }

                    Component.onCompleted: {
                        for(var u=-15; u<=15; u+=5) {
                            for(var v=-15; v<=15; v+=5) {
                                refer_points.push({
                                    px: u,
                                    py: v
                                })
                            }
                        }
                        // notify
                        refer_pointsChanged()
                    }
                }

                // Anchors
                Repeater {
                    model: DigiKeyFromLog.anchors.length

                    Rectangle {
                        id: anchor
                        width: 10 / canvas.scaleFactor
                        height: 10 / canvas.scaleFactor
                        radius: 5 / canvas.scaleFactor
                        color: DigiKeyFromLog.currentLocation.activatedAnchors[index] ? "red" : "black"
                        x: canvas.translateX(anchor, DigiKeyFromLog.anchors[index].coordinate[0])
                        y: canvas.translateY(anchor, DigiKeyFromLog.anchors[index].coordinate[1])
                        visible: DigiKeyFromLog.anchors[index].isWorking
                        
                        Text {
                            id: anchor_name
                            x: parent.width
                            y: parent.height
                            color: DigiKeyFromLog.currentLocation.activatedAnchors[index] ? "red" : "black"
                            text: "A" + (index+1)

                            Text {
                                id: anchor_info
                                x: 0
                                y: parent.height
                                text: DigiKeyFromLog.anchors[index].coordinate[0].toFixed(2) + "," + 
                                      DigiKeyFromLog.anchors[index].coordinate[1].toFixed(2)
                                visible: false
                            }

                            MouseArea {
                                anchors.fill: parent
                                
                                onClicked: {
                                    anchor_info.visible = !anchor_info.visible
                                }
                            }
                        }
                    }
                }


                Item {
                    id: zones
                    anchors.fill: parent
                    
                    property int offsetX: 40 // cm
                    property int offsetY: 40 // cm
                    property int distanceNear: 120 // cm
                    property int distanceFar: 300 // cm

                    property var anchorA: [car.x + zones.offsetX, car.y + zones.offsetY]
                    property var anchorB: [car.x + car.width - zones.offsetX, car.y + zones.offsetY]
                    property var anchorC: [car.x + zones.offsetX, car.y + car.height - zones.offsetY]
                    property var anchorD: [car.x + car.width - zones.offsetX, car.y + car.height - zones.offsetY]

                    Shape {
                        opacity: 0.4
                        
                        ShapePath {
                            id: zone_0_center

                            /*  
                                there is an issue that does not trigger binding if using transparent color in expression ???
                                use "#01000000" for transparent
                            */
                            fillColor: DigiKeyFromLog.currentLocation.zone == 0 ? "blue" : "#01000000"
                            strokeColor: "transparent"
                            startX: zones.anchorA[0]
                            startY: zones.anchorA[1]

                            PathLine {
                                x: zones.anchorB[0]
                                y: zones.anchorB[1]
                            }

                            PathLine {
                                x: zones.anchorD[0]
                                y: zones.anchorD[1]
                            }

                            PathLine {
                                x: zones.anchorC[0]
                                y: zones.anchorC[1]
                            }
                        }

                        Zone {
                            id: zone_1_front_near
                            //fillColor: DigiKeyFromLog.currentLocation.zone == 1 ? "green" : "#01000000"
                            fillGradient: LinearGradient {
                                x1: zones.anchorA[0]
                                y1: zones.anchorA[1]
                                x2: zones.anchorA[0]
                                y2: zones.anchorA[1] - zones.distanceNear
                                GradientStop { position: 0; color: DigiKeyFromLog.currentLocation.zone == 1 ? "green" : "transparent" }
                                GradientStop { position: 1; color: "transparent" }
                            }
                            strokeColor: "transparent"
                            pointA: zones.anchorA
                            pointB: zones.anchorB
                            arcA: [-45, -45]
                            arcB: [-90, -45]
                            arcR: zones.distanceNear
                        }

                        Zone {
                            id: zone_2_front_far
                            //fillColor: DigiKeyFromLog.currentLocation.zone == 2 ? "yellow" : "#01000000"
                            fillGradient: LinearGradient {
                                x1: zones.anchorA[0]
                                y1: zones.anchorA[1]
                                x2: zones.anchorA[0]
                                y2: zones.anchorA[1] - zones.distanceFar
                                GradientStop { position: 0; color: DigiKeyFromLog.currentLocation.zone == 2 ? "yellow" : "transparent" }
                                GradientStop { position: 1; color: "transparent" }
                            }
                            strokeColor: "transparent"
                            pointA: zones.anchorA
                            pointB: zones.anchorB
                            arcA: [-45, -45]
                            arcB: [-90, -45]
                            arcR: zones.distanceFar
                        }

                        Zone {
                            id: zone_3_left_near
                            //fillColor: DigiKeyFromLog.currentLocation.zone == 3 ? "green" : "#01000000"
                            fillGradient: LinearGradient {
                                x1: zones.anchorA[0]
                                y1: zones.anchorA[1]
                                x2: zones.anchorA[0] - zones.distanceNear
                                y2: zones.anchorA[1]
                                GradientStop { position: 0; color: DigiKeyFromLog.currentLocation.zone == 3 ? "green" : "transparent"}
                                GradientStop { position: 1; color: "transparent" }
                            }
                            strokeColor: "transparent"
                            pointA: zones.anchorA
                            pointB: zones.anchorC
                            arcA: [135, 45]
                            arcB: [180, 45]
                            arcR: zones.distanceNear
                        }

                        Zone {
                            id: zone_4_left_far
                            //fillColor: DigiKeyFromLog.currentLocation.zone == 4 ? "yellow" : "#01000000"
                            fillGradient: LinearGradient {
                                x1: zones.anchorA[0]
                                y1: zones.anchorA[1]
                                x2: zones.anchorA[0] - zones.distanceFar
                                y2: zones.anchorA[1]
                                GradientStop { position: 0; color: DigiKeyFromLog.currentLocation.zone == 4 ? "yellow" : "transparent"}
                                GradientStop { position: 1; color: "transparent" }
                            }
                            strokeColor: "transparent"
                            pointA: zones.anchorA
                            pointB: zones.anchorC
                            arcA: [135, 45]
                            arcB: [180, 45]
                            arcR: zones.distanceFar
                        }

                        Zone {
                            id: zone_5_rear_near
                            //fillColor: DigiKeyFromLog.currentLocation.zone == 5 ? "green" : "#01000000"
                            fillGradient: LinearGradient {
                                x1: zones.anchorC[0]
                                y1: zones.anchorC[1]
                                x2: zones.anchorC[0]
                                y2: zones.anchorC[1] + zones.distanceNear
                                GradientStop { position: 0; color: DigiKeyFromLog.currentLocation.zone == 5 ? "green" : "transparent" }
                                GradientStop { position: 1; color: "transparent" }
                            }
                            strokeColor: "transparent"
                            pointA: zones.anchorC
                            pointB: zones.anchorD
                            arcA: [45, 45]
                            arcB: [90, 45]
                            arcR: zones.distanceNear
                        }

                        Zone {
                            id: zone_6_rear_far
                            //fillColor: DigiKeyFromLog.currentLocation.zone == 6 ? "yellow" : "#01000000"
                            fillGradient: LinearGradient {
                                x1: zones.anchorC[0]
                                y1: zones.anchorC[1]
                                x2: zones.anchorC[0]
                                y2: zones.anchorC[1] + zones.distanceFar
                                GradientStop { position: 0; color: DigiKeyFromLog.currentLocation.zone == 6 ? "yellow" : "transparent"}
                                GradientStop { position: 1; color: "transparent" }
                            }
                            strokeColor: "transparent"
                            pointA: zones.anchorC
                            pointB: zones.anchorD
                            arcA: [45, 45]
                            arcB: [90, 45]
                            arcR: zones.distanceFar
                        }

                        Zone {
                            id: zone_7_left_near
                            //fillColor: DigiKeyFromLog.currentLocation.zone == 7 ? "green" : "#01000000"
                            fillGradient: LinearGradient {
                                x1: zones.anchorB[0]
                                y1: zones.anchorB[1]
                                x2: zones.anchorB[0] + zones.distanceNear
                                y2: zones.anchorB[1]
                                GradientStop { position: 0; color: DigiKeyFromLog.currentLocation.zone == 7 ? "green" : "transparent"}
                                GradientStop { position: 1; color: "transparent" }
                            }
                            strokeColor: "transparent"
                            pointA: zones.anchorB
                            pointB: zones.anchorD
                            arcA: [45, -45]
                            arcB: [0, -45]
                            arcR: zones.distanceNear
                        }

                        Zone {
                            id: zone_8_left_far
                            //fillColor: DigiKeyFromLog.currentLocation.zone == 8 ? "yellow" : "#01000000"
                            fillGradient: LinearGradient {
                                x1: zones.anchorB[0]
                                y1: zones.anchorB[1]
                                x2: zones.anchorB[0] + zones.distanceFar
                                y2: zones.anchorB[1]
                                GradientStop { position: 0; color: DigiKeyFromLog.currentLocation.zone == 8 ? "yellow" : "transparent"}
                                GradientStop { position: 1; color: "transparent" }
                            }
                            strokeColor: "transparent"
                            pointA: zones.anchorB
                            pointB: zones.anchorD
                            arcA: [45, -45]
                            arcB: [0, -45]
                            arcR: zones.distanceFar
                        }
                    }
                }

                // Current location 
                Rectangle {
                    id: current_location
                    width: 10 / canvas.scaleFactor
                    height: 10 / canvas.scaleFactor
                    radius: 5 / canvas.scaleFactor
                    color: "red"
                    x: canvas.translateX(current_location, DigiKeyFromLog.currentLocation.coordinate[0])
                    y: canvas.translateY(current_location, DigiKeyFromLog.currentLocation.coordinate[1])

                    Text {
                        id: anchor_name
                        x: parent.width
                        y: parent.height
                        color: "red"
                        font.pointSize: canvas.scaleFactor >= 1 ? 12 : 12 / canvas.scaleFactor
                        text: "#" + (DigiKeyFromLog.currentLocationIndex)

                        Text {
                            x: 0
                            y: parent.height
                            color: "red"
                            font.pointSize: canvas.scaleFactor >= 1 ? 12 : 12 / canvas.scaleFactor
                            text: DigiKeyFromLog.currentLocation.coordinate[0].toFixed(2) + "," +
                                  DigiKeyFromLog.currentLocation.coordinate[1].toFixed(2)
                        }
                    }
                }

                // Current location uncertanty circles
                Rectangle {
                    id: current_location_around_10
                    width: 20
                    height: 20
                    radius: 10
                    color: "transparent"
                    border.color: "blue"
                    border.width: 1.0
                    x: canvas.translateX(current_location_around_10, DigiKeyFromLog.currentLocation.coordinate[0])
                    y: canvas.translateY(current_location_around_10, DigiKeyFromLog.currentLocation.coordinate[1])
                    opacity: 0.5
                    visible: canvas.scaleFactor >= 1
                }

                MouseArea {
                    anchors.fill: parent
                    propagateComposedEvents: true

                    property double factor: 2

                    onWheel: {
                        // limit zoomable level
                        if ((canvas_transform.xScale > 4  && wheel.angleDelta.y > 0)
                            || (canvas_transform.xScale < 1/4 && wheel.angleDelta.y < 0 )) 
                            return

                        // if zoomable, calculate zoom factor
                        var zoomFactor = wheel.angleDelta.y > 0 ? factor : 1 / factor
                        var realX = wheel.x * canvas_transform.xScale
                        var realY = wheel.y * canvas_transform.yScale
                        canvas.x += (1 - zoomFactor) * realX
                        canvas.y += (1 - zoomFactor) * realY
                        canvas_transform.xScale *= zoomFactor
                        canvas_transform.yScale *= zoomFactor
                    }
                }

                transform: Scale {
                    id: canvas_transform

                    Behavior on xScale { PropertyAnimation { duration: transitionDuration;  easing.type: Easing.InOutCubic } }
                    Behavior on yScale { PropertyAnimation { duration: transitionDuration;  easing.type: Easing.InOutCubic } }
                }

                Behavior on x { PropertyAnimation { duration: transitionDuration; easing.type: Easing.InOutCubic } }
                Behavior on y { PropertyAnimation { duration: transitionDuration; easing.type: Easing.InOutCubic } }

                /* Make canvas draggable */
                MouseArea {
                    drag.target: canvas
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    propagateComposedEvents: true
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 5
                text: "Showing location #" + DigiKeyFromLog.currentLocationIndex + " of " + DigiKeyFromLog.totalLocations
            }

            Row {
                spacing: 10
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 20

                Button {
                    text: DigiKeyFromLog.isAutoplay ? "Manual Navigation" : "Autoplay"
                    
                    onClicked: {
                        DigiKeyFromLog.toggle_autoplay()
                    }
                }

                Button {
                    text: "Previous"
                    visible: !DigiKeyFromLog.isAutoplay
                    
                    onClicked: {
                        DigiKeyFromLog.show_previous_location()
                    }
                }

                Button {
                    text: "Next"
                    visible: ! DigiKeyFromLog.isAutoplay
                    
                    onClicked: {
                        DigiKeyFromLog.show_next_location()
                    }
                }
            }
        }

        // settings
        RowLayout {
            Layout.fillHeight: true
            spacing: 0

            // drawer
            Rectangle {
                Layout.preferredWidth: 20
                Layout.fillHeight: true
                color: "#E6E9ED"
                border.color: "#687D91"

                MouseArea {
                    anchors.fill: parent

                    onClicked: {
                        settings.visible = !settings.visible
                    }

                    onWheel: {}
                }

                Text {
                    anchors.fill: parent
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    rotation: -90
                    text: (settings.visible ? "\u25BC" : "\u25B2") + "Settings & Log" + (settings.visible ? "\u25BC" : "\u25B2")
                    color: "blue"
                }
            }

            Rectangle {
                id: settings
                Layout.preferredWidth: 400
                Layout.fillHeight: true
                border.color: "#687D91"

                MouseArea {
                    anchors.fill: parent
                    
                    onWheel: {}
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 1
                    // Header: Params
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        color: "#E6E9ED"

                        RowLayout {
                            anchors.fill: parent
                            
                            Text {
                                height: parent.height
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: 5
                                color: "blue"
                                font.pointSize: 10
                                text: "Params:"
                            }
                        }
                    }

                    RowLayout {
                        enabled: false

                        Item {
                            Layout.preferredWidth: 20
                            Layout.preferredHeight: 30
                        }

                        Text {
                            Layout.preferredWidth: 30
                            Layout.preferredHeight: 30
                            verticalAlignment: Text.AlignVCenter
                            text: "N"
                        }

                        TextField {
                            Layout.preferredWidth: 100
                            Layout.preferredHeight: 30
                            text: DigiKeyFromLog.params.N
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        Text {
                            Layout.preferredWidth: 30
                            Layout.preferredHeight: 30
                            verticalAlignment: Text.AlignVCenter
                            text: "F"
                        }

                        ComboBox {
                            Layout.preferredWidth: 150
                            Layout.preferredHeight: 30
                            property var items: ["CH5 - 6489600", "CH6 - 6988800", "CH7 - 6489600", "CH8 - 7488000", "CH9 - 7987200"]
                            model: items
                            currentIndex: {
                                var f = "" + DigiKeyFromLog.params.F
                                for (var i=0; i<items.length; i++) {
                                    if (items[i].includes(f)) {
                                        return i
                                    }
                                }
                                return -1
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                        }
                    }

                    RowLayout {
                        enabled: false

                        Item {
                            Layout.preferredWidth: 20
                            Layout.preferredHeight: 30
                        }

                        Text {
                            Layout.preferredWidth: 30
                            Layout.preferredHeight: 30
                            verticalAlignment: Text.AlignVCenter
                            text: "R"
                        }

                        ComboBox {
                            Layout.preferredWidth: 100
                            Layout.preferredHeight: 30
                            property var items: ["0", "1", "2", "3", "4", "5", "6", "7"]
                            model: items
                            currentIndex: {
                                var r = "" + DigiKeyFromLog.params.R
                                for (var i=0; i<items.length; i++) {
                                    if (items[i].includes(r)) {
                                        return i
                                    }
                                }
                                return -1
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        Text {
                            Layout.preferredWidth: 30
                            Layout.preferredHeight: 30
                            verticalAlignment: Text.AlignVCenter
                            text: "P"
                        }

                        ComboBox {
                            Layout.preferredWidth: 150
                            Layout.preferredHeight: 30
                            property var items: ["-12 dBm", "-11 dBm", "-10 dBm", "-9 dBm", "-8 dBm", "-7 dBm", "-6 dBm", "-5 dBm", "-6 dBm", "-5 dBm", "-4 dBm", "-3 dBm", "-2 dBm", "-1 dBm", "0 dBm", "1 dBm", "2 dBm", "3 dBm", "4 dBm", "5 dBm", "6 dBm", "7 dBm", "8 dBm", "9 dBm", "10 dBm", "11 dBm", "12 dBm", "13 dBm", "14 dBm"]
                            model: items
                            currentIndex: {
                                var p = "" + DigiKeyFromLog.params.P + " dBm"
                                for (var i=0; i<items.length; i++) {
                                    if (items[i].includes(p)) {
                                        return i
                                    }
                                }
                                return -1
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                        }
                    }

                    // Header: Anchors
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        color: "#E6E9ED"

                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: 5
                            color: "blue"
                            font.pointSize: 10
                            text: "Anchors"
                        }

                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment:Text.AlignRight
                            rightPadding: 5
                            text: (anchors.visible ? qsTr("Hide \u25B2") : qsTr("Show \u25BC"))
                            color: "darkblue"
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                anchors.visible = !anchors.visible
                            }
                        }
                    }

                    // Anchors
                    GridLayout {
                        id: anchors
                        rows: 4
                        columns: 2
                        enabled: false
                        visible: false

                        Repeater {
                            model: 8
                            RowLayout {
                                spacing: 2

                                CheckBox {
                                    Layout.preferredWidth: 20
                                    Layout.preferredHeight: 30
                                    scale: 0.5
                                    checked: DigiKeyFromLog.anchors[index].isWorking
                                    onClicked: {
                                        DigiKeyFromLog.anchors[index].isWorking = checked
                                    }
                                }

                                Text {
                                    Layout.preferredWidth: 30
                                    Layout.preferredHeight: 30
                                    height: parent.height
                                    verticalAlignment: Text.AlignVCenter
                                    text: "A" + (index + 1)
                                }

                                TextField {
                                    Layout.preferredWidth: 45
                                    Layout.preferredHeight: 30
                                    height: parent.height
                                    verticalAlignment: Text.AlignVCenter
                                    validator: DoubleValidator {bottom: -15.0; top: 15.0}
                                    text: DigiKeyFromLog.anchors[index].coordinate[0].toFixed(2)
                                }

                                TextField {
                                    Layout.preferredWidth: 45
                                    Layout.preferredHeight: 30
                                    height: parent.height
                                    verticalAlignment: Text.AlignVCenter
                                    validator: DoubleValidator {bottom: -15.0; top: 15.0}
                                    text: DigiKeyFromLog.anchors[index].coordinate[1].toFixed(2)
                                }

                                TextField {
                                    Layout.preferredWidth: 45
                                    Layout.preferredHeight: 30
                                    height: parent.height
                                    verticalAlignment: Text.AlignVCenter
                                    validator: DoubleValidator {bottom: -15.0; top: 15.0}
                                    text: DigiKeyFromLog.anchors[index].coordinate[2].toFixed(2)
                                }
                            }
                        }
                    }

                    // Header: Params
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        color: "#E6E9ED"

                        RowLayout {
                            anchors.fill: parent
                            
                            Text {
                                height: parent.height
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: 5
                                color: "blue"
                                font.pointSize: 10
                                text: "Receiver Performance"
                            }

                            Text {
                                height: parent.height
                                verticalAlignment: Text.AlignVCenter
                                text: "at location " + DigiKeyFromLog.currentLocationIndex
                            }

                            Item {
                                Layout.fillWidth: true
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.leftMargin: 15
                        wrapMode: Text.WordWrap
                        text: {
                            var msg = ""
                            for(var i=0; i<8; i++) {
                                if(DigiKeyFromLog.anchors[i].isWorking) {
                                    if (msg != "")
                                        msg += "<br>"
                                    msg += "A" + (i+1) + ": "
                                    msg += "F = <font color='green' size='+1'>" + DigiKeyFromLog.currentLocation.performance[i].RSSI.toFixed(0) + " dBm</font>,  "
                                    msg += "Ei = <font color='green' size='+1'>" + DigiKeyFromLog.currentLocation.performance[i].SNR + "</font>,  "
                                    msg += "Fi = <font color='green' size='+1'>" + DigiKeyFromLog.currentLocation.performance[i].NEV + "</font>,  "
                                    msg += "Mi = <font color='green' size='+1'>" + DigiKeyFromLog.currentLocation.performance[i].NER + "</font>,  "
                                    msg += "T = <font color='green' size='+1'>" + DigiKeyFromLog.currentLocation.performance[i].PER.toFixed(0) + " dBm</font>"
                                }
                            }

                            return msg
                        }
                    }

                    // Header: BLE info
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        color: "#E6E9ED"

                        RowLayout {
                            anchors.fill: parent
                            
                            Text {
                                height: parent.height
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: 5
                                color: "blue"
                                font.pointSize: 10
                                text: "BLE Status:"
                            }

                            Text {
                                height: parent.height
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: 5
                                font.bold: true
                                font.pointSize: 12
                                text: {
                                    var status = DigiKeyFromLog.ble.status
                                    if ( status == 1) {
                                        return "Disconnected"
                                    } else if (status == 2) {
                                        return "Connecting"
                                    } else if (status == 3) {
                                        return "Connected"
                                    } else {
                                        return "Unknown"
                                    }
                                }
                                color: {
                                    var status = DigiKeyFromLog.ble.status
                                    if ( status == 1) {
                                        return "red"
                                    } else if (status == 2) {
                                        return "orange"
                                    } else if (status == 3) {
                                        return "green"
                                    } else {
                                        return "black"
                                    }
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            Text {
                                height: parent.height
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: 5
                                color: "blue"
                                font.pointSize: 10
                                text: "RSSI (dBm):"
                            }

                            Text {
                                height: parent.height
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: 5
                                font.bold: true
                                font.pointSize: 12
                                text: DigiKeyFromLog.ble.rssi
                            }

                            Item {
                                Layout.fillWidth: true
                            }
                        }
                    }

                    // BLE buttons
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30

                        RowLayout {
                            anchors.fill: parent

                            Text {
                                Layout.preferredWidth: 40
                                height: parent.height
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: 5
                                text: "Button count:"
                            }
                            Text {
                                height: parent.height
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: 5
                                text: "Door<br><font color='blue' size='+2'>" + DigiKeyFromLog.ble.doorCount + "</font>"
                            }

                            Text {
                                height: parent.height
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: 5
                                text: "Trunk<br><font color='blue' size='+2'>" + DigiKeyFromLog.ble.trunkCount + "</font>"
                            }

                            Text {
                                height: parent.height
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: 5
                                text: "Engine<br><font color='blue' size='+2'>" + DigiKeyFromLog.ble.engineCount + "</font>"
                            }
                        }
                    }

                    // Header: Position and Distance
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        color: "#E6E9ED"

                        RowLayout {
                            anchors.fill: parent
                            
                            Text {
                                height: parent.height
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: 5
                                color: "blue"
                                font.pointSize: 10
                                text: "Location and Distance:"
                            }

                            Item {
                                Layout.fillWidth: true
                            }
                        }
                    }

                    // Location List
                    ListView {
                        id: location_list
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        ScrollBar.vertical: ScrollBar {}
                        clip: true
                        currentIndex: DigiKeyFromLog.currentLocationIndex - 1 // remove 'loop 0'          
                        model: DigiKeyFromLog.locations
                        delegate: Rectangle {
                            width: location_list.width
                            height: 60
                            color: ListView.isCurrentItem ? "yellow" : "transparent"

                            Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: 5
                                text: {
                                    var msg = "Location <font size='+1'>" + (index + 1) + "</font>: "
                                    msg += "<font color='blue' size='+1'>"
                                    msg += modelData.coordinate[0].toFixed(2) + ", "
                                    msg += modelData.coordinate[1].toFixed(2)
                                    msg += "</font> "
                                    msg += "in zone: <font color='blue' size='+1'>" + modelData.zone + "</font>"
                                    msg += "<br>"
                                    for(var i=0; i<8; i++) {
                                        var d = modelData.distance[i]
                                        msg += "D" + (i+1) + " = " + ((isNaN(d) || d < 0) ? "<font color='gray'>failed" : "<font color='green'>" + d.toFixed(2)) + "</font>, "
                                        if(i==3) msg += "<br>"
                                    }
                                    return msg
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    DigiKeyFromLog.isAutoplay = false
                                    DigiKeyFromLog.currentLocationIndex = index + 1
                                }
                            }
                        }

                        onCountChanged: {
                            positionViewAtEnd()
                        }
                    }

                    // Header: Ranging Engine
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 50
                        color: "#E6E9ED"

                        RowLayout {
                            anchors.fill: parent
                            
                            Text {
                                Layout.preferredWidth: 100
                                height: parent.height
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: 5
                                color: DigiKeyFromLog.isRanging ? "green" : "red"
                                font.pointSize: 10
                                text: "Ranging engine: " + (DigiKeyFromLog.isRanging ? "ON" : "OFF")
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            Button {
                                text: DigiKeyFromLog.isRanging ? "Stop Ranging" : "Start Ranging"
                                palette {
                                    button: "white"
                                }
                                
                                onClicked: {
                                    DigiKeyFromLog.toggle_ranging()
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                            }
                        }
                    }

                    // Header: Read Log
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 50
                        color: "#E6E9ED"

                        RowLayout {
                            anchors.fill: parent
                            
                            Text {
                                Layout.preferredWidth: 100
                                height: parent.height
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: 5
                                color: DigiKeyFromLog.isReadingLog ? "green" : "red"
                                font.pointSize: 10
                                text: "Log reader: " + (DigiKeyFromLog.isReadingLog ? "Reading" : "Paused")
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            Button {
                                height: 30
                                text: DigiKeyFromLog.isReadingLog ? "Pause reading" : "Resume reading"
                                palette {
                                    button: "white"
                                }
                                
                                onClicked: {
                                    DigiKeyFromLog.toggle_reading_log()
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                            }
                        }
                    }
                } 
            }
        }
    }
}