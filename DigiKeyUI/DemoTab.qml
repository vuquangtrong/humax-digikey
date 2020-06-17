import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtCharts 2.3
import Position 1.0

RowLayout {
    id: demoTab
    width: 1920
    height: 1080
    spacing: 0

    Item {
        id: graph
        Layout.fillWidth: true
        Layout.fillHeight: true

        property int pixelsPerMeter: sldPpm.value

        function m2px(x) {
            return x * pixelsPerMeter
        }

        function getNewX(w) {
            return m2px(Math.floor(w / pixelsPerMeter / 2) - 1)
        }

        function getNewY(h) {
            return m2px(Math.floor(h / pixelsPerMeter / 2) + 3)
        }

        function translate(context, w, h) {
            var nx = getNewX(w)
            var ny = getNewY(h)
            context.translate(nx, ny)
            context.rotate(-Math.PI / 2)
        }

        function drawLine(context, x0, y0, x1, y1) {
            context.beginPath()
            context.moveTo(m2px(y0), m2px(x0))
            context.lineTo(m2px(y1), m2px(x1))
            context.stroke()
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
            id: car
            source: "car.png"
            opacity: sldCar.value / 100

            function relocate(w, h) {
                var offset_x = parseFloat(a1_offset_x.text)
                if (isNaN(offset_x)) offset_x = 0.5

                var offset_y = parseFloat(a1_offset_y.text)
                if (isNaN(offset_y)) offset_y = 0.5

                var real_width = parseFloat(car_width.text)
                if (isNaN(real_width)) real_width = 2

                var real_height = parseFloat(car_height.text)
                if (isNaN(real_height)) real_height = 5

                car.width = graph.m2px(real_width - offset_x)
                car.height = graph.m2px(real_height - offset_y)

                // move to origin
                var nx = graph.getNewX(w)
                var ny = graph.getNewY(h)

                // relocate
                car.x = nx + graph.m2px(offset_x)
                car.y = ny - car.height - graph.m2px(offset_y)
            }
        }

        Canvas {
            id: canvas_grid
            anchors.fill: parent

            onPaint: {
                car.relocate(canvas_grid.width, canvas_grid.height)

                var ctx = getContext("2d")
                ctx.reset()

                ctx.globalAlpha = 0.5

                // move the origin and rotate left
                graph.translate(ctx, canvas_grid.width, canvas_grid.height)

                // draw grid
                var w = Math.floor(canvas_grid.width / graph.pixelsPerMeter)
                var h = Math.floor(canvas_grid.height / graph.pixelsPerMeter)
                var d = Math.max(w, h)
                var i,j,s

                if(graph.pixelsPerMeter <= 20) {
                    s = 1
                } else if(graph.pixelsPerMeter <= 50) {
                    s = 2
                } else if(graph.pixelsPerMeter <= 100) {
                    s = 5
                }

                for(i=-d; i<=d; i+=1) {
                    ctx.save()
                    ctx.strokeStyle = "green"
                    ctx.lineWidth = 0.4
                    graph.drawLine(ctx, -d, i, d, i)
                    graph.drawLine(ctx, i, -d, i, d)
                    ctx.restore()

                    for(j=1; j<s; j++) {
                        ctx.save()
                        ctx.strokeStyle = "gray"
                        ctx.lineWidth = 0.2
                        graph.drawLine(ctx, -d, i+j*(1/s), d, i+j*(1/s))
                        graph.drawLine(ctx, i+j*(1/s), -d, i+j*(1/s), d)
                        ctx.restore()
                    }
                }

                if(swRefAnchors.checked) {
                    for(var u=-15; u<=15; u+=5) {
                        for(var v=-15; v<=20; v+= 5) {
                            graph.drawCircle(ctx, u, v, 2, true, "(" + u + ", " + v + ")")
                        }
                    }
                }
            }

            Connections {
                target: swRefAnchors
                function onToggled() {
                    canvas_grid.requestPaint()
                }
            }
        }

        Canvas {
            id: canvas_anchors
            anchors.fill: parent

            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()
                ctx.font = "16px sans-serif"

                if(swDebug.checked) {
                    ctx.fillStyle = "black"
                } else {
                    ctx.fillStyle = "red"
                }

                ctx.lineWidth = 1

                // move the origin and rotate left
                graph.translate(ctx, canvas_anchors.width, canvas_anchors.height)

                // draw anchors
                for (var i = 0; i < DigiKey.params.anchors.length; i++) {
                    var t = "A" + (i + 1)
                    if(swDebug.checked)
                    {
                        t += ": " + DigiKey.position.distance[i].toFixed(2)
                    }
                    ctx.save()
                    if(swDebug.checked) {
                        if(DigiKey.anchors[i].active) {
                            ctx.fillStyle = "red"
                        } else {
                            ctx.fillStyle = "black"
                        }
                    }
                    graph.drawCircle(ctx, DigiKey.params.anchors[i][0], DigiKey.params.anchors[i][1], 5, true, t)
                    ctx.restore()
                }
            }

            Connections {
                target: DigiKey
                function onParamsUpdated() {
                    canvas_anchors.requestPaint()
                }
            }

            Connections {
                target: DigiKey
                function onPositionUpdated() {
                    if(swDebug.checked) {
                        canvas_anchors.requestPaint()
                    }
                }
            }

            Connections {
                target: swDebug
                function onToggled() {
                    canvas_anchors.requestPaint()
                }
            }
        }

        Canvas {
            id: canvas_real_key
            anchors.fill: parent

            onPaint: {
                var ctx = canvas_real_key.getContext("2d")
                ctx.reset()

                if(swRealKey.checked) {
                    ctx.font = "16px sans-serif"
                    ctx.fillStyle = "orange"
                    ctx.lineWidth = 1

                    // move the origin and rotate left
                    graph.translate(ctx, canvas_key.width, canvas_key.height)

                    graph.drawCircle(ctx, parseFloat(realKey.px.text), parseFloat(realKey.py.text), 8, true, "Real Position (" + parseFloat(realKey.px.text).toFixed(2) + ", " + parseFloat(realKey.py.text).toFixed(2) + ")")
                }
            }

            Connections {
                target: swRealKey
                function onToggled() {
                    canvas_real_key.requestPaint()
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

                ctx.font = "16px sans-serif"
                ctx.fillStyle = key_status === 1 ? "blue" : "purple"
                ctx.strokeStyle = "blue"
                ctx.lineWidth = 1

                // move the origin and rotate left
                graph.translate(ctx, canvas_key.width, canvas_key.height)

                graph.drawCircle(ctx, DigiKey.position.coordinate[0], DigiKey.position.coordinate[1], 5, true, "Calc. Position (" + DigiKey.position.coordinate[0].toFixed(2) + ", " +  DigiKey.position.coordinate[1].toFixed(2) + ")")
                graph.drawCircle(ctx, DigiKey.position.coordinate[0], DigiKey.position.coordinate[1], 5 + 0.1 * graph.pixelsPerMeter, false, "")
                graph.drawCircle(ctx, DigiKey.position.coordinate[0], DigiKey.position.coordinate[1], 5 + 0.2 * graph.pixelsPerMeter, false, "")
                graph.drawCircle(ctx, DigiKey.position.coordinate[0], DigiKey.position.coordinate[1], 5 + 0.3 * graph.pixelsPerMeter, false, "")

                ctx.save()
                ctx.lineWidth = 2
                if(swTrace.checked && DigiKey.positionHistory[0].length > 1) {
                    for(var i=1; i<DigiKey.positionHistory[0].length; i++) {
                        graph.drawLine(ctx,
                                       DigiKey.positionHistory[0][i-1], DigiKey.positionHistory[1][i-1],
                                       DigiKey.positionHistory[0][i], DigiKey.positionHistory[1][i])
                    }
                }
                ctx.restore()
            }

            Connections {
                target: DigiKey
                function onPositionUpdated(status) {
                    canvas_key.key_status = status
                    canvas_key.requestPaint()
                }
            }

            Connections {
                target: swTrace
                function onToggled() {
                    canvas_key.requestPaint()
                }
            }

            MouseArea {
                anchors.fill: parent
                onWheel: {
                    if (wheel.angleDelta.y > 0)
                    {
                        sldPpm.value += 5
                    }
                    else
                    {
                        sldPpm.value -= 5
                    }
                    wheel.accepted=true
                }
            }
        }

        ColumnLayout {
            spacing: 0

            RowLayout {
                spacing: 0
                Layout.preferredHeight: 20

                Text {
                    Layout.preferredWidth: 15
                    text: qsTr("PPM")
                    MouseArea {
                        anchors.fill: parent
                        onDoubleClicked: {
                            sldPpm.value = 50
                        }
                    }
                }

                Slider {
                    id: sldPpm
                    Layout.preferredWidth: 100
                    scale: 0.6
                    value: 28
                    from: 20
                    to: 100
                    stepSize: 5
                    ToolTip.visible: hovered
                    ToolTip.text: qsTr("Pixels per Meter")
                }
            }

            RowLayout {
                spacing: 0
                Layout.preferredHeight: 20

                Text {
                    Layout.preferredWidth: 20
                    text: qsTr("Debug")
                }

                Switch {
                    id: swDebug
                    scale: 0.4
                    checked: true
                }
            }

            RowLayout {
                spacing: 0
                Layout.preferredHeight: 20

                Text {
                    Layout.preferredWidth: 20
                    text: qsTr("Trace")
                }

                Switch {
                    id: swTrace
                    scale: 0.4
                }
            }

            RowLayout {
                spacing: 0
                Layout.preferredHeight: 20

                Text {
                    Layout.preferredWidth: 20
                    text: qsTr("Refers")
                }

                Switch {
                    id: swRefAnchors
                    scale: 0.4
                    checked: true
                }
            }
        }

        ColumnLayout {
            anchors.bottom: parent.bottom

            RowLayout {
                Layout.preferredHeight: 32

                Slider {
                    id: sldCar
                    Layout.preferredWidth: 50
                    value: 50
                    from: 10
                    to: 100
                    stepSize: 5
                    ToolTip.visible: hovered
                    ToolTip.text: qsTr("Car's opacity")
                }

                Text {
                    Layout.preferredWidth: 10
                    horizontalAlignment: Text.AlignRight
                    text: qsTr("w")
                }

                NumberInput {
                    id: car_width
                    Layout.preferredHeight: 30
                    Layout.preferredWidth: 50
                    font.pointSize: 8
                    text: "2"

                    onTextChanged: {
                        if(!isNaN(parseFloat(text))) {
                            canvas_grid.requestPaint()
                        }
                    }
                }

                Text {
                    Layout.preferredWidth: 10
                    horizontalAlignment: Text.AlignRight
                    text: qsTr("h")
                }

                NumberInput {
                    id: car_height
                    Layout.preferredHeight: 30
                    Layout.preferredWidth: 50
                    font.pointSize: 8
                    text: "5"

                    onTextChanged: {
                        if(!isNaN(parseFloat(text))) {
                            canvas_grid.requestPaint()
                        }
                    }
                }
            }

            RowLayout {
                Layout.preferredHeight: 32

                Text {
                    Layout.preferredWidth: 50
                    text: qsTr("A1 Offset")
                }

                Text {
                    Layout.preferredWidth: 10
                    horizontalAlignment: Text.AlignRight
                    text: qsTr("x")
                }

                NumberInput {
                    id: a1_offset_x
                    Layout.preferredHeight: 30
                    Layout.preferredWidth: 50
                    font.pointSize: 8
                    text: "-0.5"

                    onTextChanged: {
                        if(!isNaN(parseFloat(text))) {
                            canvas_grid.requestPaint()
                        }
                    }
                }

                Text {
                    Layout.preferredWidth: 10
                    horizontalAlignment: Text.AlignRight
                    text: qsTr("y")
                }

                NumberInput {
                    id: a1_offset_y
                    Layout.preferredHeight: 30
                    Layout.preferredWidth: 50
                    font.pointSize: 8
                    text: "-0.5"

                    onTextChanged: {
                        if(!isNaN(parseFloat(text))) {
                            canvas_grid.requestPaint()
                        }
                    }
                }
            }
        }

        onPixelsPerMeterChanged: {
            canvas_grid.requestPaint()
            canvas_anchors.requestPaint()
            canvas_real_key.requestPaint()
            canvas_key.requestPaint()
        }
    }

    Rectangle {
        Layout.preferredWidth: 20
        Layout.fillHeight: true
        color: "#E6E9ED"

        Text {
            anchors.fill: parent
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            rotation: -90
            text: qsTr("Settings")
            font.pointSize: 10
            color: "blue"
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                settings.visible = !settings.visible
            }
        }
    }

    Rectangle {
        id: settings
        Layout.preferredWidth: 426
        Layout.fillHeight: true
        radius: 10
        color: "#FCFCFC"
        border.color: "#687D91"
        visible: false

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 6

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                radius: 5
                color: "#E6E9ED"

                Text {
                    anchors.fill: parent
                    text: qsTr("Params")
                    leftPadding: 5
                    verticalAlignment: Text.AlignVCenter
                    font.pointSize: 10
                    color: "blue"
                }
            }

            RowLayout {
                Text {
                    text: "N"
                    horizontalAlignment: Text.AlignRight
                    Layout.preferredWidth: 30
                    font.pixelSize: 14
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
                        var n = parseInt(text)
                        if(!isNaN(n)) {
                            DigiKey.params.N = n
                        } else {
                            DigiKey.params.N = 10
                        }
                    }
                }

                Text {
                    text: "F"
                    horizontalAlignment: Text.AlignRight
                    Layout.preferredWidth: 8
                    font.pixelSize: 14
                }

                ComboBox {
                    property var items: []
                    id: param_f
                    Layout.preferredHeight: 30
                    Layout.preferredWidth: 124
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
                    Layout.preferredWidth: 8
                    font.pixelSize: 14
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
                    Layout.preferredWidth: 8
                    font.pixelSize: 14
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

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                radius: 5
                color: "#E6E9ED"

                Text {
                    anchors.fill: parent
                    text: qsTr("Anchors") + ": " + (anchors.visible ? qsTr("Hide") : qsTr("Show"))
                    leftPadding: 5
                    verticalAlignment: Text.AlignVCenter
                    font.pointSize: 10
                    color: "blue"
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        anchors.visible = !anchors.visible
                    }
                }
            }

            GridLayout {
                id: anchors
                rows: 4
                columns: 2
                visible: false

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
                            DigiKey.params.set_anchor(index, 0, parseFloat(px.text))
                        }

                        onPyTextChanged: {
                            DigiKey.params.set_anchor(index, 1, parseFloat(py.text))
                        }

                        onPzTextChanged: {
                            DigiKey.params.set_anchor(index, 2, parseFloat(pz.text))
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                radius: 5
                color: "#E6E9ED"

                Text {
                    anchors.fill: parent
                    text: qsTr("Receiver Performance")
                    leftPadding: 5
                    verticalAlignment: Text.AlignVCenter
                    font.pointSize: 10
                    color: "blue"
                }
            }

            Text {
                id: receiverStatus
                Layout.fillWidth: true
                Layout.leftMargin: 15
                text: qsTr("Waiting...")
                wrapMode: Text.WordWrap
                Connections {
                    target: DigiKey
                    function onAnchorsUpdated() {
                        var anchors = DigiKey.anchors
                        var msg = ""
                        for (var i = 0; i < anchors.length; i++) {
                            msg += "A" + (i + 1) + ": "
                            msg += "RSSI = <font color='green'>" + anchors[i].RSSI.toFixed(0) + "dBm</font>, "
                            msg += "SNR = <font color='green'>" + anchors[i].SNR.toFixed(2) + "dB</font>, "
                            msg += "NEV = <font color='green'>" + anchors[i].NEV + "</font>, "
                            msg += "NER = <font color='green'>" + anchors[i].NER + "</font>, "
                            msg += "PER = <font color='green'>" + anchors[i].PER.toFixed(2) + "%</font>"

                            if (i < anchors.length - 1)
                                msg += "<br>"
                        }

                        receiverStatus.text = msg
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                radius: 5
                color: "#E6E9ED"

                Text {
                    anchors.fill: parent
                    text: qsTr("Position and Distance")
                    leftPadding: 5
                    verticalAlignment: Text.AlignVCenter
                    font.pointSize: 10
                    color: "blue"
                }
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
                Layout.leftMargin: 15

                Text {
                    id: positionLog
                    property int count: 0
                    anchors.fill: parent
                    text: qsTr("Waiting...")
                }

                Connections {
                    target: DigiKey
                    function onPositionUpdated(status) {
                        var position = DigiKey.position
                        var msg = "<br><br>"
                        if (status === 1) {
                            msg += "Location update (" + positionLog.count + ") at <font color='blue'>"
                            msg += "" + position.coordinate[0].toFixed(2) + ", "
                            msg += "" + position.coordinate[1].toFixed(2) + ", "
                            msg += "" + position.coordinate[2].toFixed(2)
                            msg += "</font>"
                        } else if (status === -1) {
                            msg += "<font color='purple'>No new location received</font>"
                        } else if (status === -2) {
                            msg += "<font color='purple'>Can not calculate location</font>"
                        } else {
                            msg += "Unknown location data"
                        }

                        msg += "<br>"
                        for (var i=0; i<position.distance.length; i++) {
                            var d = parseFloat(position.distance[i])
                            msg += "D" + (i+1) + " = " + ((isNaN(d) || d < 0) ? "<font color='gray'>failed" : "<font color='green'>" + position.distance[i].toFixed(2)) + "</font>, "
                            if(i==3) msg += "<br>"
                        }
                        positionLog.count += 1
                        positionLog.text += msg
                        positionLogScroller.scrollTo(Qt.Vertical, 1)
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                radius: 5
                color: "#E6E9ED"

                Text {
                    anchors.fill: parent
                    text: qsTr("Accuracy")
                    leftPadding: 5
                    verticalAlignment: Text.AlignVCenter
                    font.pointSize: 10
                    color: "blue"
                }
            }

            Text {
                Layout.fillWidth: true
                Layout.leftMargin: 5
                text: qsTr("Uncertainty circles with ranges of <font color=\"blue\">10cm, 20cm, 30cm</font> from the <font color=\"blue\">Calculated Position</font>")
                wrapMode: Text.WordWrap
            }

            RowLayout {
                Layout.leftMargin: 5
                PositionInput {
                    id: realKey
                    name: qsTr("<font color=\"red\">Real Key Position</font>")
                    nameWidth: 83
                    px.text: "0.75"
                    py.text: "2.75"
                    pz.text: "0"

                    onPxTextChanged: {
                        if(swRealKey != null && swRealKey.checked) canvas_real_key.requestPaint()
                    }

                    onPyTextChanged: {
                        if(swRealKey != null && swRealKey.checked) canvas_real_key.requestPaint()
                    }

                    onPzTextChanged: {
                        if(swRealKey != null && swRealKey.checked) canvas_real_key.requestPaint()
                    }
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
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                Layout.topMargin: 6
                Layout.fillWidth: true

                RoundButton {
                    Layout.preferredWidth: 100
                    Layout.preferredHeight: 30
                    text: qsTr("Start")
                    onClicked: {
                        positionLog.count = 1
                        DigiKey.request_start()
                    }
                }

                RoundButton {
                    Layout.preferredWidth: 100
                    Layout.preferredHeight: 30
                    text: qsTr("Record")
                    onClicked: DigiKey.request_record()
                }

                RoundButton {
                    Layout.preferredWidth: 100
                    Layout.preferredHeight: 30
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
