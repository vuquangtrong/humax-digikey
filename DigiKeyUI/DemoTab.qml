import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import Position 1.0

RowLayout {

    width: 1280
    height: 720

    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        Rectangle {
            id: calcKey
            width: 8
            height: 8
            radius: 4
            color: "blue"

            x: DigiKey.position.coordinate[0]
            y: DigiKey.position.coordinate[1]
        }
    }

    Item {
        Layout.preferredWidth: 420
        Layout.fillHeight: true

        ColumnLayout {
            anchors.fill: parent

            Text {
                text: qsTr("Params")
                font.pointSize: 10
                color: "blue"
            }

            RowLayout {
                Text {
                    text: "N"
                    horizontalAlignment: Text.AlignRight
                    Layout.preferredWidth: 30
                }

                NumberInput {
                    id: param_n
                    Layout.preferredHeight: 30
                    Layout.preferredWidth: 50
                    text: "10"
                    ToolTip.visible: hovered
                    ToolTip.text: qsTr("Number of ranging cycles")
                }

                Text {
                    text: "F"
                    horizontalAlignment: Text.AlignRight
                    Layout.preferredWidth: 20
                }

                ComboBox {
                    id: param_f
                    Layout.preferredHeight: 30
                    Layout.preferredWidth: 80
                    model: ["CH5", "CH6"]
                    ToolTip.visible: hovered
                    ToolTip.text: qsTr("Carrier Frequency")
                }

                Text {
                    text: "R"
                    horizontalAlignment: Text.AlignRight
                    Layout.preferredWidth: 30
                }

                ComboBox {
                    id: param_r
                    Layout.preferredHeight: 30
                    Layout.preferredWidth: 60
                    model: ["0", "1", "2", "3", "4", "5", "6", "7"]
                    currentIndex: 3
                    ToolTip.visible: hovered
                    ToolTip.text: qsTr("RX index for Radio Setting")
                }

                Text {
                    text: "P"
                    horizontalAlignment: Text.AlignRight
                    Layout.preferredWidth: 30
                }

                ComboBox {
                    id: param_p
                    Layout.preferredHeight: 30
                    Layout.preferredWidth: 85

                    ToolTip.visible: hovered
                    ToolTip.text: qsTr("Transmission Power in dBm")

                    Component.onCompleted: {
                        var power_items = []
                        for (var i = -12; i <= 14; i++) {
                            power_items.push("" + i + " dBm")
                        }
                        model = power_items
                        currentIndex = 12 /* 0 dBm */
                    }
                }
            }

            Text {
                Layout.topMargin: 6
                text: qsTr("Anchors")
                font.pointSize: 10
                color: "blue"
            }

            ColumnLayout {
                RowLayout {
                    PositionInput {
                        id: anchor1
                        name: "A1"
                        px: "0"
                        py: "0"
                        pz: "0"
                    }
                    PositionInput {
                        id: anchor2
                        name: "A2"
                        px: "1"
                        py: "0"
                        pz: "0"
                    }
                }
                RowLayout {
                    PositionInput {
                        id: anchor3
                        name: "A3"
                        px: "0"
                        py: "4"
                        pz: "0"
                    }
                    PositionInput {
                        id: anchor4
                        name: "A4"
                        px: "1"
                        py: "4"
                        pz: "0"
                    }
                }
                RowLayout {
                    PositionInput {
                        id: anchor5
                        name: "A5"
                        px: "0"
                        py: "1"
                        pz: "0"
                    }
                    PositionInput {
                        id: anchor6
                        name: "A6"
                        px: "1"
                        py: "1"
                        pz: "0"
                    }
                }
                RowLayout {
                    PositionInput {
                        id: anchor7
                        name: "A7"
                        px: "0"
                        py: "3"
                        pz: "0"
                    }
                    PositionInput {
                        id: anchor8
                        name: "A8"
                        px: "0"
                        py: "3"
                        pz: "0"
                    }
                }
            }

            Text {
                Layout.topMargin: 6
                text: qsTr("Receiver Performance")
                font.pointSize: 10
                color: "blue"
            }

            Text {
                id: receiverStatus
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: DigiKey.receiverStatus
            }

            Text {
                Layout.topMargin: 6
                text: qsTr("Distance and Position Update")
                font.pointSize: 10
                color: "blue"
            }

            ScrollView {
                id: positionLogScroller
                property ScrollBar hScrollBar: ScrollBar.horizontal
                property ScrollBar vScrollBar: ScrollBar.vertical

                function scrollTo(type, ratio) {
                    var scrollFunc = function (bar, ratio) {
                        bar.setPosition(ratio - bar.size)
                    }
                    switch (type) {
                    case Qt.Horizontal:
                        scrollFunc(hScrollBar, ratio)
                        break
                    case Qt.Vertical:
                        scrollFunc(vScrollBar, ratio)
                        break
                    }
                }

                clip: true
                Layout.fillWidth: true
                Layout.fillHeight: true
                ScrollBar.vertical.policy: ScrollBar.AlwaysOn

                Text {
                    id: positionLog
                    anchors.fill: parent
                }

                Connections {
                    target: DigiKey
                    function onPositionUpdated(position) {
                        var msg = "Location update <font color='#FF0000'>"
                                + position.coordinate + "</font><br>"
                                + "D1 = " + position.distance[0] + ", D2 = " + position.distance[1]
                                + ", D3 = " + position.distance[2]
                                + ", D4 = " + position.distance[3] + "<br>" + "D5 = "
                                + position.distance[4] + ", D6 = "
                                + position.distance[5] + ", D7 = "
                                + position.distance[6] + ", D8 = "
                                + position.distance[7] + "<br><br>"
                        positionLog.text += msg
                        positionLogScroller.scrollTo(Qt.Vertical, 1)
                    }
                }
            }

            Text {
                Layout.topMargin: 6
                text: qsTr("Range and Accuracy")
                font.pointSize: 10
                color: "blue"
            }

            Text {
                Layout.fillWidth: true
                text: qsTr("The <font color=\"red\">Real Position</font> of your key is inside of uncertainty circles of range <font color=\"blue\">10cm, 20cm, 30cm</font> from the center of 'Calculated Position'")
                wrapMode: Text.WordWrap
            }

            RowLayout {
                PositionInput {
                    id: realKey
                    name: qsTr("<font color=\"red\">Real Key Position</font>")
                    nameWidth: 83
                    px: "0"
                    py: "0"
                    pz: "0"
                }

                Text {
                    text: qsTr("Show")
                }

                Switch {
                    id: realKey_sw
                    Layout.preferredHeight: 30
                }
            }

            RowLayout {
                Layout.topMargin: 6
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                RoundButton {
                    Layout.preferredWidth: 100
                    text: qsTr("Init")
                    onClicked: DigiKey.request_init()
                }

                RoundButton {
                    Layout.preferredWidth: 100
                    text: qsTr("Start")
                    onClicked: DigiKey.request_start()
                }

                RoundButton {
                    Layout.preferredWidth: 100
                    text: qsTr("Record")
                    onClicked: DigiKey.request_record()
                }

                RoundButton {
                    Layout.preferredWidth: 100
                    text: qsTr("Stop")
                    onClicked: DigiKey.request_stop()
                }
            }
        }
    }

    Component.onCompleted: {
        console.log("DigiKey", DigiKey)
        console.log("DigiKey.receiverStatus", DigiKey.receiverStatus)
        console.log("DigiKey.position", DigiKey.position)
        console.log("DigiKey.position.coordinate", DigiKey.position.coordinate)
        console.log("DigiKey.position.distance", DigiKey.position.distance)
    }
}
