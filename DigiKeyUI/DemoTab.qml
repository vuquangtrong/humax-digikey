import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtCharts 2.3
import Position 1.0

RowLayout {
    width: 1280
    height: 720

    Item {
        id: graph
        Layout.fillWidth: true
        Layout.fillHeight: true

        property int pixelsPerMeter: 50

        function m2px(x) {
            return x * pixelsPerMeter
        }

        function translate(context, w, h) {
            var nx = m2px(Math.floor(w / pixelsPerMeter / 2) - 1)
            var ny = m2px(Math.floor(h / pixelsPerMeter / 2) + 3)
            context.translate(nx, ny)
            context.rotate(-Math.PI / 2)
        }

        function drawCircle(context, x, y, r, filled, text) {
            context.beginPath()
            context.arc(m2px(y), m2px(x), r, 0, 2 * Math.PI)
            if (filled) {
                context.fill()
            } else {
                context.stroke()
            }

            if (text !== "") {
                context.save()

                // move origin and rotate
                context.translate(m2px(y), m2px(x))
                context.rotate(Math.PI / 2)

                // draw text
                context.fillText(text, x + 5, y + 15)

                context.restore()
            }
        }

        Image {
            property double real_width: 3.0
            property double real_height: 6.0
            property double offset: 0.5
            id: car
            source: "car.png"

            function relocate(w, h) {
                car.width = graph.m2px(real_width)
                car.height = graph.m2px(real_height)

                // move to origin
                var nx = graph.m2px(Math.floor(w / graph.pixelsPerMeter / 2) - 1)
                var ny = graph.m2px(Math.floor(h / graph.pixelsPerMeter / 2) + 3)

                // relocate
                car.x = nx - graph.m2px(offset)
                car.y = ny - car.height + graph.m2px(offset)
            }
        }

        Canvas {
            id: canvas_grid
            anchors.fill: parent

            onPaint: {
                car.relocate(canvas_grid.width, canvas_grid.height)

                var ctx = getContext("2d")
                ctx.strokeStyle = "gray"
                ctx.lineWidth = 0.5
                ctx.setLineDash([5, 5])

                // draw grid
                ctx.save()

                var i = 0
                for (i = 0; i < height / graph.pixelsPerMeter + 1; i++) {
                    ctx.beginPath()
                    ctx.moveTo(0, graph.m2px(i))
                    ctx.lineTo(width, graph.m2px(i))
                    ctx.stroke()
                }

                for (i = 0; i < width / graph.pixelsPerMeter + 1; i++) {
                    ctx.beginPath()
                    ctx.moveTo(graph.m2px(i), 0)
                    ctx.lineTo(graph.m2px(i), height)
                    ctx.stroke()
                }

                // draw fixed anchors
                // move the origin and rotate left
                graph.translate(ctx, canvas_anchors.width, canvas_anchors.height)

                for(var u=-15; u<=15; u+=5) {
                    for(var v=-15; v<=15; v+= 5) {
                        graph.drawCircle(ctx, u, v, 2, true, "(" + u + "," + v + ")")
                    }
                }

                ctx.restore()
            }
        }

        Canvas {
            id: canvas_anchors
            anchors.fill: parent

            onPaint: {
                var ctx = getContext("2d")
                ctx.fillStyle = "red"
                ctx.lineWidth = 1

                // draw anchors
                ctx.save()

                // move the origin and rotate left
                graph.translate(ctx, canvas_anchors.width, canvas_anchors.height)

                for (var i = 0; i < DigiKey.params.anchors.length; i++) {
                    graph.drawCircle(ctx, DigiKey.params.anchors[i][0], DigiKey.params.anchors[i][1], 5, true, "A" + (i + 1) + " (" + DigiKey.params.anchors[i][0] +"," +  DigiKey.params.anchors[i][1] + ")")
                }

                ctx.restore()
            }
        }

        Canvas {
            id: canvas_key
            anchors.fill: parent
            Connections {
                target: DigiKey
                function onPositionUpdated() {
                    var ctx = canvas_key.getContext("2d")
                    if (ctx !== null) {
                        ctx.reset()

                        ctx.fillStyle = "blue"
                        ctx.strokeStyle = "blue"
                        ctx.lineWidth = 1

                        ctx.save()
                        // move the origin and rotate left
                        graph.translate(ctx, canvas_key.width,
                                        canvas_key.height)

                        graph.drawCircle(ctx, DigiKey.position.coordinate[0], DigiKey.position.coordinate[1], 5, true, "Calc. Position (" + DigiKey.position.coordinate[0] + "," +  DigiKey.position.coordinate[1] + ")")
                        graph.drawCircle(ctx, DigiKey.position.coordinate[0], DigiKey.position.coordinate[1], 5 + 0.1 * graph.pixelsPerMeter, false, "")
                        graph.drawCircle(ctx, DigiKey.position.coordinate[0], DigiKey.position.coordinate[1], 5 + 0.2 * graph.pixelsPerMeter, false, "")
                        graph.drawCircle(ctx, DigiKey.position.coordinate[0], DigiKey.position.coordinate[1], 5 + 0.3 * graph.pixelsPerMeter, false, "")

                        if (realKey_sw.checked) {
                            ctx.save()
                            ctx.fillStyle = "orange"
                            graph.drawCircle(ctx, parseFloat(realKey.px), parseFloat(realKey.py), 10, true, "Real Position (" + parseFloat(realKey.px) + "," + parseFloat(realKey.py) + ")")
                            ctx.restore()
                        }

                        canvas_key.requestPaint()
                    }
                }
            }
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
                    Layout.preferredWidth: 10
                }

                ComboBox {
                    id: param_f
                    Layout.preferredHeight: 30
                    Layout.preferredWidth: 125
                    model: ["CH5 - 6489600", "CH6 - 6988800", "CH7 - 6489600", "CH8 - 7488000", "CH9 - 7987200"]
                    ToolTip.visible: hovered
                    ToolTip.text: qsTr("Carrier Frequency")
                }

                Text {
                    text: "R"
                    horizontalAlignment: Text.AlignRight
                    Layout.preferredWidth: 10
                }

                ComboBox {
                    id: param_r
                    Layout.preferredHeight: 30
                    Layout.preferredWidth: 58
                    model: ["0", "1", "2", "3", "4", "5", "6", "7"]
                    currentIndex: 3
                    ToolTip.visible: hovered
                    ToolTip.text: qsTr("RX index for Radio Setting")
                }

                Text {
                    text: "P"
                    horizontalAlignment: Text.AlignRight
                    Layout.preferredWidth: 10
                }

                ComboBox {
                    id: param_p
                    Layout.preferredHeight: 30
                    Layout.preferredWidth: 92
                    model: ["-12 dbm"]
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

            GridLayout {
                rows: 4
                columns: 2
                Repeater {
                    model: 8
                    PositionInput {
                        name: "A" + (index + 1)
                        px: DigiKey.params.anchors[index][0]
                        py: DigiKey.params.anchors[index][1]
                        pz: DigiKey.params.anchors[index][2]
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
                Connections {
                    target: DigiKey
                    function onAnchorsUpdated() {
                        var anchors = DigiKey.anchors
                        var msg = ""
                        for (var i = 0; i < anchors.length; i++) {
                            msg += "A" + (i + 1) + ": "
                            msg += "RSSI = " + anchors[i].RSSI.toFixed(0) + "dBm, "
                            msg += "SNR = " + anchors[i].SNR.toFixed(2) + "dB, "
                            msg += "NEV = " + anchors[i].NEV + ", "
                            msg += "NER = " + anchors[i].NER + ", "
                            msg += "PER = " + anchors[i].PER.toFixed(2) + "%"

                            if (i < anchors.length - 1)
                                msg += "\n"
                        }

                        receiverStatus.text = msg
                    }
                }
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
                    function onPositionUpdated() {
                        var position = DigiKey.position
                        var msg = "<br><br>"
                        msg += "Location update <font color='#FF0000'>" + position.coordinate + "</font><br>"
                        msg += "D1 = " + position.distance[0] + ", "
                        msg += "D2 = " + position.distance[1] + ", "
                        msg += "D3 = " + position.distance[2] + ", "
                        msg += "D4 = " + position.distance[3] + ", "
                        msg += "D5 = " + position.distance[4] + ", "
                        msg += "D6 = " + position.distance[5] + ", "
                        msg += "D7 = " + position.distance[6] + ", "
                        msg += "D8 = " + position.distance[7]

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
                text: qsTr("Uncertainty circles with ranges of <font color=\"blue\">10cm, 20cm, 30cm</font> from the <font color=\"blue\">Calculated Position</font>")
                wrapMode: Text.WordWrap
            }

            RowLayout {
                PositionInput {
                    id: realKey
                    name: qsTr("<font color=\"red\">Real Key Position</font>")
                    nameWidth: 83
                    px: "3"
                    py: "3"
                    pz: "1"
                }

                Text {
                    text: qsTr("Show")
                    horizontalAlignment: Text.AlignRight
                    Layout.preferredWidth: 60
                }

                Switch {
                    id: realKey_sw
                    scale: 0.6
                    Layout.preferredWidth: 40
                    checked: true
                }
            }

            RowLayout {
                Layout.topMargin: 6
                Layout.fillWidth: true

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
        console.log("DigiKey.receiverStatus", DigiKey.receiverStatus)
        console.log("DigiKey.position.coordinate", DigiKey.position.coordinate)
        console.log("DigiKey.position.distance", DigiKey.position.distance)
        console.log("DigiKey.anchors", DigiKey.anchors)
        for (var i = 0; i < DigiKey.anchors.length; i++) {
            console.log(DigiKey.anchors[i].RSSI)
            console.log(DigiKey.anchors[i].SNR)
            console.log(DigiKey.anchors[i].NEV)
            console.log(DigiKey.anchors[i].NER)
            console.log(DigiKey.anchors[i].PER)
        }
    }
}
