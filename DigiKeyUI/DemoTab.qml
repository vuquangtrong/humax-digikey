import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtCharts 2.3
import Position 1.0

RowLayout {
    width: 1920
    height: 1080

    Item {
        id: graph
        Layout.fillWidth: true
        Layout.fillHeight: true

        property int pixelsPerMeter: sldPpm.value

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
            property double offset: 0.5
            property double real_width: 2 + offset
            property double real_height: 5 + offset
            id: car
            source: "car.png"
            visible: swCar.checked

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
                ctx.reset()

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
                        graph.drawCircle(ctx, u, v, 2, true, "(" + u + ", " + v + ")")
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
                ctx.reset()

                ctx.fillStyle = "red"
                ctx.lineWidth = 1

                // draw anchors
                ctx.save()

                // move the origin and rotate left
                graph.translate(ctx, canvas_anchors.width, canvas_anchors.height)

                for (var i = 0; i < DigiKey.params.anchors.length; i++) {
                    graph.drawCircle(ctx, DigiKey.params.anchors[i][0], DigiKey.params.anchors[i][1], 5, true, "A" + (i + 1) + " (" + DigiKey.params.anchors[i][0] +", " +  DigiKey.params.anchors[i][1] + ")")
                }

                ctx.restore()
            }

            Connections {
                target: DigiKey
                function onParamsUpdated() {
                    canvas_anchors.requestPaint()
                }
            }
        }

        Canvas {
            id: canvas_key
            anchors.fill: parent

            property int key_status: 0

            onPaint: {
                if(key_status == 0) {
                    return
                }
                var ctx = canvas_key.getContext("2d")
                ctx.reset()

                ctx.fillStyle = key_status === 1 ? "blue" : "purple"
                ctx.strokeStyle = "blue"
                ctx.lineWidth = 1

                ctx.save()
                // move the origin and rotate left
                graph.translate(ctx, canvas_key.width, canvas_key.height)

                graph.drawCircle(ctx, DigiKey.position.coordinate[0], DigiKey.position.coordinate[1], 5, true, "Calc. Position (" + DigiKey.position.coordinate[0].toFixed(2) + ", " +  DigiKey.position.coordinate[1].toFixed(2) + ")")
                graph.drawCircle(ctx, DigiKey.position.coordinate[0], DigiKey.position.coordinate[1], 5 + 0.1 * graph.pixelsPerMeter, false, "")
                graph.drawCircle(ctx, DigiKey.position.coordinate[0], DigiKey.position.coordinate[1], 5 + 0.2 * graph.pixelsPerMeter, false, "")
                graph.drawCircle(ctx, DigiKey.position.coordinate[0], DigiKey.position.coordinate[1], 5 + 0.3 * graph.pixelsPerMeter, false, "")

                if (swRealKey.checked) {
                    ctx.save()
                    ctx.fillStyle = "orange"
                    graph.drawCircle(ctx, parseFloat(realKey.px.text), parseFloat(realKey.py.text), 10, true, "Real Position (" + parseFloat(realKey.px.text).toFixed(2) + ", " + parseFloat(realKey.py.text).toFixed(2) + ")")
                    ctx.restore()
                }
            }

            Connections {
                target: DigiKey
                function onPositionUpdated(status) {
                    canvas_key.key_status = status
                    canvas_key.requestPaint()
                }
            }
        }

        ColumnLayout {
            spacing: 0

            RowLayout {
                spacing: 0

                Text {
                    text: qsTr("Show Car")
                }

                Switch {
                    id: swCar
                    scale: 0.6
                    checked: true
                }
            }

            RowLayout {
                spacing: 0

                Text {
                    text: qsTr("Px per Metter")
                }

                Slider {
                    id: sldPpm
                    scale: 0.6
                    value: 50
                    from: 50
                    to: 100
                    stepSize: 5
                }
            }
        }

        onPixelsPerMeterChanged: {
            canvas_grid.requestPaint()
            canvas_anchors.requestPaint()
            canvas_key.requestPaint()
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
                    ToolTip.visible: hovered
                    ToolTip.text: qsTr("Number of ranging cycles")

                    Component.onCompleted: {
                        text = DigiKey.params.N
                    }

                    onTextEdited: {
                        DigiKey.params.N = parseInt(text)
                    }
                }

                Text {
                    text: "F"
                    horizontalAlignment: Text.AlignRight
                    Layout.preferredWidth: 10
                }

                ComboBox {
                    property var items: []
                    id: param_f
                    Layout.preferredHeight: 30
                    Layout.preferredWidth: 125
                    model: items
                    ToolTip.visible: hovered
                    ToolTip.text: qsTr("Carrier Frequency")

                    Component.onCompleted: {
                        var f = "" + DigiKey.params.F
                        items = ["CH5 - 6489600", "CH6 - 6988800", "CH7 - 6489600", "CH8 - 7488000", "CH9 - 7987200"]
                        for (var i=0; i<items.length; i++) {
                            if (items[i].includes(f)) {
                                currentIndex = i
                                break
                            }
                        }
                    }

                    onDisplayTextChanged: {
                        DigiKey.params.F = parseInt(displayText.split(" - ")[1])
                    }
                }

                Text {
                    text: "R"
                    horizontalAlignment: Text.AlignRight
                    Layout.preferredWidth: 10
                }

                ComboBox {
                    property var items: []
                    id: param_r
                    Layout.preferredHeight: 30
                    Layout.preferredWidth: 58
                    model: items
                    ToolTip.visible: hovered
                    ToolTip.text: qsTr("RX index for Radio Setting")

                    Component.onCompleted: {
                        var r = "" + DigiKey.params.R
                        items = ["0", "1", "2", "3", "4", "5", "6", "7"]
                        for (var i=0; i<items.length; i++) {
                            if (items[i].includes(r)) {
                                currentIndex = i
                                break
                            }
                        }
                    }

                    onDisplayTextChanged: {
                        DigiKey.params.R = parseInt(displayText)
                    }
                }

                Text {
                    text: "P"
                    horizontalAlignment: Text.AlignRight
                    Layout.preferredWidth: 10
                }

                ComboBox {
                    property var items: []
                    id: param_p
                    Layout.preferredHeight: 30
                    Layout.preferredWidth: 92
                    model: items
                    ToolTip.visible: hovered
                    ToolTip.text: qsTr("Transmission Power in dBm")

                    Component.onCompleted: {
                        var p = "" + DigiKey.params.P + " dBm"
                        for (var i = -12; i <= 14; i++) {
                            items.push("" + i + " dBm")
                        }
                        model = items
                        for (i=0; i<items.length; i++) {
                            if(items[i] === p) {
                                currentIndex = i
                                break
                            }
                        }
                    }

                    onDisplayTextChanged: {
                        DigiKey.params.P = parseInt(displayText)
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
                        Component.onCompleted: {
                            px.text = DigiKey.params.anchors[index][0]
                            py.text = DigiKey.params.anchors[index][1]
                            pz.text = DigiKey.params.anchors[index][2]
                        }

                        onPxTextChanged: {
                            var p = parseFloat(px.text)
                            if(isNaN(p) && px.text != '-') {
                               px.text = ''
                            }
                            DigiKey.params.set_anchor(index, 0, p)
                        }

                        onPyTextChanged: {
                            var p = parseFloat(py.text)
                            if(isNaN(p) && py.text != '-') {
                               py.text = ''
                            }
                            DigiKey.params.set_anchor(index, 1, p)
                        }

                        onPzTextChanged: {
                            var p = parseFloat(pz.text)
                            if(isNaN(p) && pz.text != '-') {
                               pz.text = ''
                            }
                            DigiKey.params.set_anchor(index, 2, p)
                        }
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
                    function onPositionUpdated(status) {
                        var position = DigiKey.position
                        var msg = "<br><br>"
                        if (status == 1) {
                            msg += "Location update <font color='red'>"
                            msg += "" + position.coordinate[0].toFixed(2) + ", "
                            msg += "" + position.coordinate[1].toFixed(2) + ", "
                            msg += "" + position.coordinate[2].toFixed(2)
                            msg += "</font><br>"
                            msg += "D1 = " + position.distance[0].toFixed(2) + ", "
                            msg += "D2 = " + position.distance[1].toFixed(2) + ", "
                            msg += "D3 = " + position.distance[2].toFixed(2) + ", "
                            msg += "D4 = " + position.distance[3].toFixed(2) + "<br>"
                            msg += "D5 = " + position.distance[4].toFixed(2) + ", "
                            msg += "D6 = " + position.distance[5].toFixed(2) + ", "
                            msg += "D7 = " + position.distance[6].toFixed(2) + ", "
                            msg += "D8 = " + position.distance[7].toFixed(2)
                        } else if (status == -1) {
                            msg += "<font color='purple'>No new location received</font>"
                        } else if (status == -2) {
                            msg += "<font color='purple'>Can not calculate location</font>"
                        } else {
                            msg += "Unknown data"
                        }

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
                    px.text: "3"
                    py.text: "3"
                    pz.text: "1"
                }

                Text {
                    text: qsTr("Show")
                    horizontalAlignment: Text.AlignRight
                    Layout.preferredWidth: 60
                }

                Switch {
                    id: swRealKey
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
    /*
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
    */
}
