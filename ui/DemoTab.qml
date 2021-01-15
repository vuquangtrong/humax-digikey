import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import Position 1.0

Item {
    id: root
    width: 1920
    height: 1080

    enum Source {
        From_Device,
        From_Log
    }
    readonly property int eFromDevice: 0
    readonly property int eFromLog: 1
    property int fromSource: eFromLog
    property variant positionSource:  fromSource == eFromDevice ? obj_DigiKeyFromDevice : obj_DigiKeyFromLog

    function whoami() {
        if (fromSource == eFromDevice) {
            return "DEVICE"
        } else {
            return "LOG"
        }
    }

    RowLayout {
        anchors.fill: parent    
        spacing: 0

        Item {
            id: graph
            Layout.fillWidth: true
            Layout.fillHeight: true

            function sx(x) {
                return x
            }

            function sy(y) {
                return -y
            }

            function px(x) {
                return sx(x) * sldPpm.value
            }

            function py(y) {
                return sy(y) * sldPpm.value
            }

            function translate(c=null) {
                var nx = (Math.floor(width / sldPpm.value / 2)) * sldPpm.value
                var ny = (Math.floor(height / sldPpm.value / 2) + 3) * sldPpm.value

                /*
                console.log(whoami(), "graph.translate()",
                    ", width = ", width,
                    ", height = ", height,
                    ", nx = ", nx,
                    ", ny = ", ny)
                */

                if(c)
                    c.translate(nx, ny)

                return {x: nx, y: ny}
            }

            function line(c, x0, y0, x1, y1) {
                c.moveTo(px(x0), py(y0))
                c.lineTo(px(x1), py(y1))
            }

            function rect(c, x0, y0, x1, y1) {
                c.rect(px(x0), py(y0), px(x1), py(y1))
            }

            function arc(c, x, y, r, sa, ea) {
                c.arc(px(x), py(y), r, sa, ea)
            }

            function text(c, x, y, t, a='left', dx=0, dy=0, gl=false) {
                c.save()

                if(gl) {
                    c.lineWidth = 0.8
                    c.strokeStyle = 'purple'
                    c.beginPath()
                    c.moveTo(px(x), py(y))
                    c.lineTo(px(x)+sx(dx), py(y)+sy(dy))
                    c.stroke()
                }

                c.textAlign = a
                c.fillText(t, px(x)+sx(dx), py(y)+sy(dy))

                c.restore()
            }

            Image {
                id: car
                source: "car.png"
                opacity: sldCar.value / 100

                function relocate() {
                    var offset_x = a1_offset_x.getValue()
                    var offset_y = a1_offset_y.getValue()
                    var real_width = car_width.getValue()
                    var real_height = car_height.getValue()
                    var new_xy = graph.translate()

                    car.width = Math.abs(graph.px(real_width))
                    car.height = Math.abs(graph.py(real_height))

                    console.log(whoami(), "car.relocate()",
                        ", offset_x = ", offset_x,
                        ", offset_y = ", offset_y,
                        ", real_width = ", real_width,
                        ", real_height = ", real_height,
                        ", nx = ", new_xy.x,
                        ", ny = ", new_xy.y,
                        ", car.width = ", car.width,
                        ", car.height = ", car.height)

                    car.x = new_xy.x - graph.px(offset_x)
                    car.y = new_xy.y - car.height - graph.py(offset_y)
                }
            }

            Canvas {
                id: canvas_grid
                anchors.fill: parent

                onPaint: {
                    console.log(whoami(), "canvas_grid.onPaint()",
                        ", sldPpm.value = ", sldPpm.value,
                        ", swRefAnchors.checked = ", swRefAnchors.checked)

                    if(!graph.visible) {
                        console.log(whoami(), "canvas_grid: !graph.visible -> skip onPaint()")
                        return
                    }

                    car.relocate()

                    var ctx = getContext("2d")
                    ctx.reset()

                    graph.translate(ctx)
                    ctx.globalAlpha = 0.5

                    var w = Math.floor(graph.width / sldPpm.value)
                    var h = Math.floor(graph.height / sldPpm.value)
                    var d = Math.max(w, h)
                    var i = 0, j = 0, s = 0

                    if(sldPpm.value <= 20) {
                        s = 1
                    } else if(sldPpm.value <= 50) {
                        s = 2
                    } else if(sldPpm.value <= 100) {
                        s = 5
                    } else {
                        s = 10
                    }

                    // draw major lines
                    ctx.strokeStyle = "green"
                    ctx.lineWidth = 0.4

                    ctx.beginPath()
                    for(i=-d; i<=d; i+=1) {
                        graph.line(ctx, i, d, i, -d)
                        graph.line(ctx, d, i, -d, i)
                    }
                    ctx.stroke()

                    // draw minor lines
                    ctx.strokeStyle = "gray"
                    ctx.lineWidth = 0.2

                    ctx.beginPath()
                    for(i=-d; i<=d; i+=1) {
                        for(j=1; j<s; j++) {
                            graph.line(ctx, i+j*(1/s), d, i+j*(1/s), -d)
                            graph.line(ctx, d, i+j*(1/s), -d, i+j*(1/s))
                        }
                    }
                    ctx.stroke()

                    // draw reference points
                    if(swRefAnchors.checked) {
                        for(var u=-15; u<=15; u+=5) {
                            for(var v=-15; v<=20; v+=5) {
                                ctx.beginPath()
                                graph.arc(ctx, u, v, 2, 0, 2*Math.PI)
                                ctx.fill()
                                graph.text(ctx, u, v, "(" + u + ", " + v + ")", 'right', -5, -15)
                            }
                        }
                    }

                    // draw zone boudaries
                    var offset_x = a1_offset_x.getValue()
                    var offset_y = a1_offset_y.getValue()
                    var real_width = car_width.getValue()
                    var real_height = car_height.getValue()
                    var w = real_width-2*offset_x
                    var h = real_height-2*offset_y

                    ctx.strokeStyle = 'darkred'
                    ctx.lineWidth = 1

                    ctx.beginPath()

                    var l = 2*Math.sin(Math.PI/4)
                    graph.rect(ctx, 0, 0, w, h)
                    graph.line(ctx, 0, 0, -l, -l)
                    graph.line(ctx, w, 0, w+l, -l)
                    graph.line(ctx, 0, h, -l, h+l)
                    graph.line(ctx, w, h, w+l, h+l)

                    for(var i=1; i<=2; i++) {
                        graph.line(ctx, -i, 0, -i, h)
                        graph.arc(ctx, 0, h, graph.px(i), Math.PI, 3*Math.PI/2)

                        graph.line(ctx, 0, h+i, w, h+i)
                        graph.arc(ctx, w, h, graph.px(i), 3*Math.PI/2, 0)
                        
                        graph.line(ctx, w+i, h, w+i, 0)
                        graph.arc(ctx, w, 0, graph.px(i), 0, Math.PI/2)

                        graph.line(ctx, w, -i, 0, -i)
                        graph.arc(ctx, 0, 0, graph.px(i), Math.PI/2, Math.PI)                
                    }

                    ctx.stroke()

                    canvas_zone.requestPaint()
                }
            }

            Canvas {
                id: canvas_zone
                anchors.fill: parent

                property int activatedZone: -1
                property var innerColor: 'green'
                property var outterColor: 'yellow'

                function drawInCar(c, w, h) {
                    c.save()
                    c.fillStyle = innerColor
                    c.beginPath()
                    graph.rect(c, 0, 0, w, h)
                    c.fill()
                    c.restore()
                }

                function drawRear(c,w,h,z) {
                    c.save()
                    c.fillStyle = (z==5 ? outterColor : innerColor)
                    c.beginPath()
                    graph.line(c, 0, 0, w, 0)
                    graph.arc(c, w, 0, graph.px(z==5 ? 2 : 1), Math.PI/4, Math.PI/2)
                    graph.arc(c, 0, 0, graph.px(z==5 ? 2 : 1), Math.PI/2, 3*Math.PI/4)
                    c.fill()
                    c.restore()
                }

                function drawRight(c,w,h,z) {
                    c.save()
                    c.fillStyle = (z==7 ? outterColor : innerColor)
                    c.beginPath()
                    graph.line(c, w, 0, w, h)
                    graph.arc(c, w, h, graph.px(z==7 ? 2 : 1), 7*Math.PI/4, 0)
                    graph.arc(c, w, 0, graph.px(z==7 ? 2 : 1), 0, Math.PI/4)
                    c.fill()
                    c.restore()
                }

                function drawFront(c,w,h,z) {
                    c.save()
                    c.fillStyle = (z==1 ? outterColor : innerColor)
                    c.beginPath()
                    graph.line(c, w, h, 0, h)
                    graph.arc(c, 0, h, graph.px(z==1 ? 2 : 1), 5*Math.PI/4, 3*Math.PI/2)
                    graph.arc(c, w, h, graph.px(z==1 ? 2 : 1), 3*Math.PI/2, 7*Math.PI/4)
                    c.fill()
                    c.restore()
                }

                function drawLeft(c,w,h,z) {
                    c.save()
                    c.fillStyle = (z==3 ? outterColor : innerColor)
                    c.beginPath()
                    graph.line(c, 0, h, 0, 0)
                    graph.arc(c, 0, 0, graph.px(z==3 ? 2 : 1), 3*Math.PI/4, Math.PI)
                    graph.arc(c, 0, h, graph.px(z==3 ? 2 : 1), Math.PI, 5*Math.PI/4)
                    c.fill()
                    c.restore()
                }

                onPaint: {
                    console.log(whoami(), "canvas_zone.onPaint()",
                        ", activatedZone = ", activatedZone)

                    if(!graph.visible) {
                        console.log(whoami(), "canvas_zone: !graph.visible -> skip onPaint()")
                        return
                    }

                    var ctx = getContext("2d")
                    ctx.reset()

                    graph.translate(ctx)
                    ctx.globalAlpha = 0.3

                    // draw zones
                    var offset_x = a1_offset_x.getValue()
                    var offset_y = a1_offset_y.getValue()
                    var real_width = car_width.getValue()
                    var real_height = car_height.getValue()
                    var w = real_width-2*offset_x
                    var h = real_height-2*offset_y

                    switch(activatedZone) {
                        case 0:
                            drawInCar(ctx, w, h)
                            break
                        case 1:
                            drawFront(ctx, w, h, 2)
                            break
                        case 2:
                            drawFront(ctx, w, h, 1)
                            break
                        case 3:
                            drawLeft(ctx, w, h, 4)
                            break
                        case 4:
                            drawLeft(ctx, w, h, 3)
                            break
                        case 5:
                            drawRear(ctx, w, h, 6)
                            break
                        case 6:
                            drawRear(ctx, w, h, 5)
                            break
                        case 7:
                            drawRight(ctx, w, h, 8)
                            break
                        case 8:
                            drawRight(ctx, w, h, 7)
                            break
                    }  
                }
            }

            Canvas {
                id: canvas_anchors
                anchors.fill: parent

                onPaint: {
                    console.log(whoami(), "canvas_anchors.onPaint()", 
                        ", sldPpm.value = ", sldPpm.value, 
                        ", swDebug.checked = ", swDebug.checked)

                    if(!graph.visible) {
                        console.log(whoami(), "canvas_anchors: !graph.visible -> skip onPaint()")
                        return
                    }

                    var ctx = getContext("2d")
                    ctx.reset()

                    graph.translate(ctx)
                    ctx.fillStyle = "darkblue"

                    var tpx = 5
                    var lpx = 15

                    if(sldPpm.value <= 20) {
                        ctx.font = "10px sans-serif"
                        tpx = 6
                        lpx = 6
                    } else if(sldPpm.value <= 50) {
                        ctx.font = "14px sans-serif"
                        tpx = 10
                        lpx = 10
                    } else if(sldPpm.value <= 100) {
                        ctx.font = "18px sans-serif"
                        tpx = 15
                        lpx = 15
                    } else {
                        ctx.font = "18px sans-serif"
                        tpx = 15
                        lpx = 15
                    }

                    // draw anchors
                    for (var i = 0; i < positionSource.params.anchors.length; i++) {
                        if(parseFloat(positionSource.params.anchors[i][3])==1.0) {
                            var a = "A" + (i + 1)
                            ctx.save()

                            if(swDebug.checked) {
                                if(positionSource.anchors[i].active) {
                                    ctx.fillStyle = "red"
                                }
                            }
                            ctx.beginPath()
                            graph.arc(ctx, positionSource.params.anchors[i][0], positionSource.params.anchors[i][1], 5, 0, 2*Math.PI)
                            ctx.fill()
                            graph.text(ctx, positionSource.params.anchors[i][0], positionSource.params.anchors[i][1], a, 'left', 5, -tpx)

                            if(swDebug.checked)
                            {
                                var t = positionSource.position.distance[i].toFixed(2)
                                graph.text(ctx, positionSource.params.anchors[i][0], positionSource.params.anchors[i][1], t, 'left', 5, -(tpx+lpx))
                            }

                            ctx.restore()
                        }
                    }
                    
                }
            }

            Canvas {
                id: canvas_real_key
                anchors.fill: parent

                onPaint: {
                    console.log(whoami(), "canvas_real_key.onPaint()", 
                        ", swRealKey.checked = ", swRealKey.checked)

                    if(!graph.visible) {
                        console.log(whoami(), "canvas_real_key: !graph.visible -> skip onPaint()")
                        return
                    }

                    var ctx = getContext("2d")
                    ctx.reset()

                    if(!swRealKey.checked) {
                        console.log(whoami(), "canvas_real_key -> skip onPaint()")
                        return
                    }

                    graph.translate(ctx)
                    ctx.fillStyle = "darkred"

                    ctx.beginPath()
                    graph.arc(ctx, parseFloat(realKey.px.text), parseFloat(realKey.py.text), 5, 0, 2*Math.PI)
                    ctx.fill()
                }
            }

            Canvas {
                id: canvas_key
                anchors.fill: parent
                visible: sw1stCalc.checked

                property int key_status: 0

                onPaint: {
                    console.log(whoami(), "canvas_key.onPaint()", 
                        ", sw1stCalc.checked = ", sw1stCalc.checked, 
                        ", key_status = ", key_status)

                    if(!graph.visible) {
                        console.log(whoami(), "canvas_key: !graph.visible -> skip onPaint()")
                        return
                    }

                    var ctx = getContext("2d")
                    ctx.reset()

                    if(!sw1stCalc.checked || key_status == 0) {
                        console.log(whoami(), "canvas_key -> skip onPaint()")
                        return
                    }

                    graph.translate(ctx)
                    ctx.font = "16px sans-serif"
                    ctx.strokeStyle = "blue"
                    ctx.fillStyle = "blue"

                    //console.log(positionSource.positionHistory)
                    if(swDebug.checked && swTrace.checked && positionSource.positionHistory[0].length > 1) {
                        ctx.lineWidth = 1.5

                        // first point
                        ctx.beginPath()
                        graph.arc(ctx, positionSource.positionHistory[0][0], positionSource.positionHistory[1][0], 2, 0, 2*Math.PI)
                        ctx.fill()
                        graph.text(ctx, positionSource.positionHistory[0][0], positionSource.positionHistory[1][0], "1", 'left', 5, -10)

                        // next points
                        for(var i=1; i<positionSource.positionHistory[0].length; i++) {
                            ctx.beginPath()
                            graph.line(ctx,
                                positionSource.positionHistory[0][i-1], positionSource.positionHistory[1][i-1],
                                positionSource.positionHistory[0][i], positionSource.positionHistory[1][i])
                            ctx.stroke()

                            ctx.beginPath()
                            graph.arc(ctx, 
                                positionSource.positionHistory[0][i], positionSource.positionHistory[1][i], 
                                2, 0, 2*Math.PI)
                            ctx.fill()

                            if(i==positionSource.positionHistory[0].length-1) {
                                graph.text(ctx, 
                                    positionSource.positionHistory[0][i], positionSource.positionHistory[1][i],
                                    "" + (i+1),
                                    'left', 50, -50, true)
                            } else {
                                graph.text(ctx, 
                                    positionSource.positionHistory[0][i], positionSource.positionHistory[1][i],
                                    "" + (i+1),
                                    'left', 5, -10)
                            }
                        }
                    }

                    // draw current position
                    ctx.beginPath()
                    graph.arc(ctx, positionSource.position.coordinate[0], positionSource.position.coordinate[1], 5, 0, 2*Math.PI)
                    ctx.fill()

                    ctx.lineWidth = 0.8

                    // draw outter circles
                    ctx.beginPath()
                    graph.arc(ctx, positionSource.position.coordinate[0], positionSource.position.coordinate[1], 5+0.1*sldPpm.value, 0, 2*Math.PI)
                    ctx.stroke()

                    ctx.beginPath()
                    graph.arc(ctx, positionSource.position.coordinate[0], positionSource.position.coordinate[1], 5+0.2*sldPpm.value, 0, 2*Math.PI)
                    ctx.stroke()

                    ctx.beginPath()
                    graph.arc(ctx, positionSource.position.coordinate[0], positionSource.position.coordinate[1], 5+0.3*sldPpm.value, 0, 2*Math.PI)
                    ctx.stroke()
                }
            }

            Canvas {
                id: canvas_key2
                anchors.fill: parent
                visible: swDebug.checked && sw2ndCalc.checked

                property int key_status: 0

                onPaint: {
                    console.log(whoami(), "canvas_key2.onPaint()", 
                        ", swDebug.checked = ", swDebug.checked, 
                        ", sw2ndCalc.checked = ", sw2ndCalc.checked, 
                        ", key_status = ", key_status)

                    if(!graph.visible) {
                        console.log(whoami(), "canvas_key2: !graph.visible -> skip onPaint()")
                        return
                    }

                    var ctx = getContext("2d")
                    ctx.reset()

                    if(!swDebug.checked || !sw2ndCalc.checked || key_status == 0) {
                        console.log(whoami(), "canvas_key2 -> skip onPaint()")
                        return
                    }

                    graph.translate(ctx)
                    ctx.font = "16px sans-serif"
                    ctx.strokeStyle = "brown"
                    ctx.fillStyle = "brown"
                    ctx.setLineDash([2, 2]);

                    //console.log(positionSource.positionHistory2)
                    if(swTrace.checked && positionSource.positionHistory2[0].length > 1) {
                        ctx.lineWidth = 1.5

                        // first point
                        ctx.beginPath()
                        graph.arc(ctx, positionSource.positionHistory2[0][0], positionSource.positionHistory2[1][0], 2, 0, 2*Math.PI)
                        ctx.fill()
                        graph.text(ctx, positionSource.positionHistory2[0][0], positionSource.positionHistory2[1][0], "1", 'left', 5, -10)

                        // next points
                        for(var i=1; i<positionSource.positionHistory2[0].length; i++) {
                            ctx.beginPath()
                            graph.line(ctx,
                                positionSource.positionHistory2[0][i-1], positionSource.positionHistory2[1][i-1],
                                positionSource.positionHistory2[0][i], positionSource.positionHistory2[1][i])
                            ctx.stroke()

                            ctx.beginPath()
                            graph.arc(ctx, 
                                positionSource.positionHistory2[0][i], positionSource.positionHistory2[1][i], 
                                2, 0, 2*Math.PI)
                            ctx.fill()

                            if(i==positionSource.positionHistory2[0].length-1) {
                                graph.text(ctx, 
                                    positionSource.positionHistory2[0][i], positionSource.positionHistory2[1][i],
                                    "" + (i+1), 
                                    'left', 50, -50, true)
                            } else {
                                graph.text(ctx, 
                                    positionSource.positionHistory2[0][i], positionSource.positionHistory2[1][i],
                                    "" + (i+1), 
                                    'left', 5, -10)
                            }
                        }
                    }

                    // draw current position
                    ctx.beginPath()
                    graph.arc(ctx, positionSource.position2.coordinate[0], positionSource.position2.coordinate[1], 5, 0, 2*Math.PI)
                    ctx.fill()

                    ctx.lineWidth = 0.8

                    // draw outter circles
                    ctx.beginPath()
                    graph.arc(ctx, positionSource.position2.coordinate[0], positionSource.position2.coordinate[1], 5+0.1*sldPpm.value, 0, 2*Math.PI)
                    ctx.stroke()

                    ctx.beginPath()
                    graph.arc(ctx, positionSource.position2.coordinate[0], positionSource.position2.coordinate[1], 5+0.2*sldPpm.value, 0, 2*Math.PI)
                    ctx.stroke()

                    ctx.beginPath()
                    graph.arc(ctx, positionSource.position2.coordinate[0], positionSource.position2.coordinate[1], 5+0.3*sldPpm.value, 0, 2*Math.PI)
                    ctx.stroke()
                }
            }

            MouseArea {
                anchors.fill: parent
                enabled: !swAutoZoom.checked
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

            ColumnLayout {
                spacing: 0

                RowLayout {
                    spacing: 0
                    Layout.preferredHeight: 20

                    Text {
                        Layout.preferredWidth: 30
                        text: qsTr("Resolution")
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
                        value: 30
                        from: 20
                        to: 200
                        stepSize: 5
                        ToolTip.visible: hovered
                        ToolTip.text: qsTr("Pixels per Meter")

                        onValueChanged: {
                            console.log(whoami(), "sldPpm.onValueChanged()", 
                                ", sldPpm.value = ", sldPpm.value)
                            canvas_grid.requestPaint()
                            canvas_zone.requestPaint()
                            canvas_anchors.requestPaint()
                            canvas_real_key.requestPaint()
                            canvas_key.requestPaint()
                            canvas_key2.requestPaint()
                        }
                    }
                }

                RowLayout {
                    spacing: 0
                    Layout.preferredHeight: 20

                    Text {
                        Layout.preferredWidth: 30
                        text: qsTr("AutoZoom")
                    }

                    Switch {
                        id: swAutoZoom
                        scale: 0.4
                    }
                }

                RowLayout {
                    spacing: 0
                    Layout.preferredHeight: 20

                    Text {
                        Layout.preferredWidth: 30
                        text: qsTr("Refers")
                    }

                    Switch {
                        id: swRefAnchors
                        scale: 0.4
                        checked: true
                        onToggled: {
                            console.log(whoami(), "swRefAnchors.onToggled -> canvas_grid.requestPaint()")
                            canvas_grid.requestPaint()
                        }
                    }
                }

                RowLayout {
                    spacing: 0
                    Layout.preferredHeight: 20

                    Text {
                        Layout.preferredWidth: 30
                        text: qsTr("Debug")
                    }

                    Switch {
                        id: swDebug
                        scale: 0.4
                        //checked: true
                        onToggled: {
                            positionSource.debuggable = swDebug.checked
                            console.log(whoami(), "swDebug.onToggled -> canvas_anchors.requestPaint()")
                            canvas_anchors.requestPaint()

                            console.log(whoami(), "swDebug.onToggled -> canvas_key.requestPaint()")
                            canvas_key.requestPaint()
                        }
                    }
                }

                RowLayout {
                    spacing: 0
                    Layout.preferredHeight: 20

                    Text {
                        Layout.preferredWidth: 30
                        text: qsTr("Trace")
                    }

                    Switch {
                        id: swTrace
                        scale: 0.4
                        //checked: true
                        onToggled: {
                            console.log(whoami(), "swTrace.onToggled -> canvas_key.requestPaint()")
                            canvas_key.requestPaint()

                            console.log(whoami(), "swTrace.onToggled -> canvas_key2.requestPaint()")
                            canvas_key2.requestPaint()
                        }
                    }
                }

                RowLayout {
                    spacing: 0
                    Layout.preferredHeight: 20

                    Text {
                        Layout.preferredWidth: 30
                        text: qsTr("1st Calc")
                    }

                    Switch {
                        id: sw1stCalc
                        scale: 0.4
                        checked: true
                        onToggled: {
                            console.log(whoami(), "sw1stCalc.onToggled -> canvas_key.requestPaint()")
                            canvas_key.requestPaint()
                        }
                    }
                }

                RowLayout {
                    spacing: 0
                    Layout.preferredHeight: 20

                    Text {
                        Layout.preferredWidth: 30
                        text: qsTr("2nd Calc")
                    }

                    Switch {
                        id: sw2ndCalc
                        scale: 0.4
                        //checked: true
                        onToggled: {
                            console.log(whoami(), "sw2ndCalc.onToggled -> canvas_key2.requestPaint()")
                            canvas_key2.requestPaint()

                            positionSource.use2ndCalc = sw2ndCalc.checked
                        }
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

                        Component.onCompleted: {
                            text = positionSource.params.CarWidth
                        }

                        onTextEdited: {
                            var n = parseInt(text)
                            if(!isNaN(n)) {
                                positionSource.params.CarWidth = n
                            } else {
                                positionSource.params.CarWidth = 2.4
                            }
                            canvas_grid.requestPaint()
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

                        Component.onCompleted: {
                            text = positionSource.params.CarHeight
                        }

                        onTextEdited: {
                            var n = parseInt(text)
                            if(!isNaN(n)) {
                                positionSource.params.CarHeight = n
                            } else {
                                positionSource.params.CarHeight = 5.5
                            }
                            canvas_grid.requestPaint()
                        }
                    }
                }

                RowLayout {
                    Layout.preferredHeight: 32

                    Text {
                        Layout.preferredWidth: 50
                        text: qsTr("Offset")
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

                        Component.onCompleted: {
                            text = positionSource.params.CarOffsetX
                        }

                        onTextEdited: {
                            var n = parseInt(text)
                            if(!isNaN(n)) {
                                positionSource.params.CarOffsetX = n
                            } else {
                                positionSource.params.CarOffsetX = 0.3
                            }
                            canvas_grid.requestPaint()
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

                        Component.onCompleted: {
                            text = positionSource.params.CarOffsetY
                        }

                        onTextEdited: {
                            var n = parseInt(text)
                            if(!isNaN(n)) {
                                positionSource.params.CarOffsetY = n
                            } else {
                                positionSource.params.CarOffsetY = 0.3
                            }
                            canvas_grid.requestPaint()
                        }
                    }
                }
            }

            ColumnLayout {
                anchors.bottom: parent.bottom
                anchors.right: parent.right

                Text {
                    id: txt_real_key
                    Layout.alignment: Qt.AlignRight
                    visible: swRealKey.checked

                    text: "Real Position (" + parseFloat(realKey.px.text).toFixed(2) + ", " + parseFloat(realKey.py.text).toFixed(2) + ")"
                    font.pointSize: 10
                    color: "darkred"
                }

                Text {
                    id: txt_key
                    Layout.alignment: Qt.AlignRight
                    visible: sw1stCalc.checked

                    text: "Calc. Position (" + positionSource.position.coordinate[0].toFixed(2) + ", " +  positionSource.position.coordinate[1].toFixed(2) + ")"
                    font.pointSize: 10
                    color: "blue"
                }

                Text {
                    id: txt_key2
                    Layout.alignment: Qt.AlignRight
                    visible: swDebug.checked && sw2ndCalc.checked

                    text: "2nd Calc. Position (" + positionSource.position2.coordinate[0].toFixed(2) + ", " +  positionSource.position2.coordinate[1].toFixed(2) + ")"
                    font.pointSize: 10
                    color: "brown"
                }
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
                text: (settings.visible ? "\u25BC" : "\u25B2") + " " + qsTr("Settings") + " " + (settings.visible ? "\u25BC" : "\u25B2")
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
            //visible: false

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
                        enabled: fromSource == eFromDevice
                        
                        function show() {
                            text = positionSource.params.N
                        }

                        Component.onCompleted: {
                            param_n.show()    
                        }

                        Connections {
                            target: positionSource
                            function onParamsUpdated() {
                                param_n.show()
                            }
                        }

                        onTextEdited: {
                            var n = parseInt(text)
                            if(!isNaN(n)) {
                                positionSource.params.N = n
                            } else {
                                positionSource.params.N = 10
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
                        property var items: ["CH5 - 6489600", "CH6 - 6988800", "CH7 - 6489600", "CH8 - 7488000", "CH9 - 7987200"]
                        id: param_f
                        Layout.preferredHeight: 30
                        Layout.preferredWidth: 124
                        model: items
                        ToolTip.visible: hovered
                        ToolTip.text: qsTr("Carrier Frequency")
                        enabled: fromSource == eFromDevice

                        function show() {
                            var f = "" + positionSource.params.F
                            for (var i=0; i<items.length; i++) {
                                if (items[i].includes(f)) {
                                    currentIndex = i
                                    break
                                }
                            }
                        }

                        Component.onCompleted: {
                            param_f.show()
                        }

                        Connections {
                            target: positionSource
                            function onParamsUpdated() {
                                param_f.show()
                            }
                        }

                        onDisplayTextChanged: {
                            positionSource.params.F = parseInt(displayText.split(" - ")[1])
                        }
                    }

                    Text {
                        text: "R"
                        horizontalAlignment: Text.AlignRight
                        Layout.preferredWidth: 8
                        font.pixelSize: 14
                    }

                    ComboBox {
                        property var items: ["0", "1", "2", "3", "4", "5", "6", "7"]
                        id: param_r
                        Layout.preferredHeight: 30
                        Layout.preferredWidth: 58
                        model: items
                        ToolTip.visible: hovered
                        ToolTip.text: qsTr("RX index for Radio Setting")
                        enabled: fromSource == eFromDevice

                        function show() {
                            var r = "" + positionSource.params.R
                            for (var i=0; i<items.length; i++) {
                                if (items[i].includes(r)) {
                                    currentIndex = i
                                    break
                                }
                            }
                        }

                        Component.onCompleted: {
                            param_r.show()
                        }

                        Connections {
                            target: positionSource
                            function onParamsUpdated() {
                                param_r.show()
                            }
                        }

                        onDisplayTextChanged: {
                            positionSource.params.R = parseInt(displayText)
                        }
                    }

                    Text {
                        text: "P"
                        horizontalAlignment: Text.AlignRight
                        Layout.preferredWidth: 8
                        font.pixelSize: 14
                    }

                    ComboBox {
                        property var items: ["-12 dBm", "-11 dBm", "-10 dBm", "-9 dBm", "-8 dBm", "-7 dBm", "-6 dBm", "-5 dBm", "-6 dBm", "-5 dBm", "-4 dBm", "-3 dBm", "-2 dBm", "-1 dBm", "0 dBm", "1 dBm", "2 dBm", "3 dBm", "4 dBm", "5 dBm", "6 dBm", "7 dBm", "8 dBm", "9 dBm", "10 dBm", "11 dBm", "12 dBm", "13 dBm", "14 dBm"]
                        id: param_p
                        Layout.preferredHeight: 30
                        Layout.preferredWidth: 92
                        model: items
                        ToolTip.visible: hovered
                        ToolTip.text: qsTr("Transmission Power in dBm")
                        enabled: fromSource == eFromDevice

                        function show() {
                            var p = "" + positionSource.params.P + " dBm"
                            for (var i=0; i<items.length; i++) {
                                if (items[i].includes(p)) {
                                    currentIndex = i
                                    break
                                }
                            }
                        }

                        Component.onCompleted: {
                            param_p.show()
                        }

                        Connections {
                            target: positionSource
                            function onParamsUpdated() {
                                param_p.show()
                            }
                        }

                        onDisplayTextChanged: {
                            positionSource.params.P = parseInt(displayText)
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
                        text: qsTr("Anchors")
                        leftPadding: 5
                        verticalAlignment: Text.AlignVCenter
                        font.pointSize: 10
                        color: "blue"
                    }

                    Text {
                        anchors.fill: parent
                        text: (anchors.visible ? qsTr("Hide \u25B2") : qsTr("Show \u25BC"))
                        rightPadding: 5
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment:Text.AlignRight
                        font.pointSize: 10
                        color: "darkblue"
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
                    //visible: false

                    Repeater {
                        model: 8
                        RowLayout {
                            CheckBox {
                                id: param_a_cb
                                Layout.preferredWidth: 20
                                scale: 0.5
                                enabled: fromSource == eFromDevice

                                function show() {
                                    checked = parseFloat(positionSource.params.anchors[index][3])==1.0
                                }

                                Component.onCompleted: {
                                    show()
                                }

                                Connections {
                                    target: positionSource
                                    function onParamsUpdated() {
                                        param_a_cb.show()
                                    }
                                }

                                onToggled: {
                                    positionSource.params.set_anchor(index, 3, checked ? "1.00" : "0.00")
                                    console.log(whoami(), "positionSource.anchors[*].visible -> canvas_anchors.requestPaint()")
                                    canvas_anchors.requestPaint()
                                }
                            }

                            PositionInput {
                                id: param_a_i
                                name: "A" + (index + 1)
                                nameWidth: 10
                                enabled: fromSource == eFromDevice

                                function show() {
                                    px.text = positionSource.params.anchors[index][0]
                                    py.text = positionSource.params.anchors[index][1]
                                    pz.text = positionSource.params.anchors[index][2]
                                }

                                Component.onCompleted: {
                                    show()
                                }

                                Connections {
                                    target: positionSource
                                    function onParamsUpdated() {
                                        param_a_i.show()
                                    }
                                }

                                onPxTextChanged: {
                                    positionSource.params.set_anchor(index, 0, parseFloat(px.text))
                                }

                                onPyTextChanged: {
                                    positionSource.params.set_anchor(index, 1, parseFloat(py.text))
                                }

                                onPzTextChanged: {
                                    positionSource.params.set_anchor(index, 2, parseFloat(pz.text))
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    radius: 5
                    color: "#E6E9ED"
                    visible: swDebug.checked

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
                    visible: swDebug.checked
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
                            console.log(whoami(), "realKey.onPxTextChanged() -> canvas_anchors.requestPaint()")
                            if(swRealKey != null && swRealKey.checked) canvas_real_key.requestPaint()
                        }

                        onPyTextChanged: {
                            console.log(whoami(), "realKey.onPyTextChanged() -> canvas_anchors.requestPaint()")
                            if(swRealKey != null && swRealKey.checked) canvas_real_key.requestPaint()
                        }

                        onPzTextChanged: {
                            console.log(whoami(), "realKey.onPzTextChanged() -> canvas_anchors.requestPaint()")
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

                        onToggled: {
                            console.log(whoami(), "swRealKey.onToggled -> canvas_real_key.requestPaint()")
                            canvas_real_key.requestPaint()
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    radius: 5
                    color: "#E6E9ED"

                    Row {
                        anchors.fill: parent

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: qsTr("Run Mode: ")
                            leftPadding: 5
                            verticalAlignment: Text.AlignVCenter
                            font.pointSize: 10
                            color: "blue"
                        }

                        Switch {
                            id: swRunMode
                            scale: 0.6
                            anchors.verticalCenter: parent.verticalCenter
                            checked: fromSource == eFromLog
                            enabled: !positionSource.started
                            ToolTip.visible: hovered
                            ToolTip.text: qsTr("Run mode only can be changed when you stop the current session.")
                            onToggled: {
                                if(fromSource == eFromDevice) {
                                    fromSource = eFromLog
                                } else {
                                    fromSource = eFromDevice
                                }

                                positionSource.activate()
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: fromSource == eFromDevice ? "From Device" : "From Log Files"
                            leftPadding: 5
                            verticalAlignment: Text.AlignVCenter
                            font.pointSize: 10
                            font.bold: true
                            color: fromSource == eFromDevice ? "blue" : "red"
                        }
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
                            positionSource.request_start()
                        }
                    }

                    RoundButton {
                        Layout.preferredWidth: 100
                        Layout.preferredHeight: 30
                        text: qsTr("Stop")
                        onClicked: positionSource.request_stop()
                    }

                    RoundButton {
                        Layout.preferredWidth: 100
                        Layout.preferredHeight: 30
                        visible: fromSource == eFromLog
                        text: reading ? qsTr("Pause UI") : qsTr("Read Log")
                        property bool reading: false
                        onClicked: {
                            positionSource.request_read_log(reading)
                            reading = !reading
                        }
                    }

                    RoundButton {
                        Layout.preferredWidth: 100
                        Layout.preferredHeight: 30
                        visible: fromSource == eFromLog
                        text: qsTr("Clear UI")
                        onClicked: {
                            positionSource.request_clear_ui()
                        }
                    }
                }
            }
        }

        // connect to backend's signals
        Connections {
            target: positionSource

            function onParamsUpdated() {
                console.log(whoami(), "positionSource.onParamsUpdated() -> canvas_anchors.requestPaint()")
                canvas_anchors.requestPaint()
            }

            function onPositionUpdated(status) {
                console.log(whoami(), "positionSource.onPositionUpdated()", 
                    ", status = ", status,
                    ", swDebug.checked = ", swDebug.checked)

                var isSldPpmChanged = true

                if(swAutoZoom.checked) {
                    var min_distance = 10000.0
                    for (var i = 0; i < positionSource.params.anchors.length; i++) {
                        var d = positionSource.position.distance[i]
                        if(d >= 0 && d < min_distance) {
                            min_distance = d;
                        }
                    }

                    if(min_distance > 15 && sldPpm.value != 25) {
                        sldPpm.value = 25
                    } else if (min_distance > 10 && sldPpm.value != 50) {
                        sldPpm.value = 50
                    } else if (min_distance > 5 && sldPpm.value != 75) {
                        sldPpm.value = 75
                    } else if (min_distance > 1 && sldPpm.value != 100) {
                        sldPpm.value = 100
                    } else if(sldPpm.value != 150){
                        sldPpm.value = 150
                    } else {
                        isSldPpmChanged = false
                    }
                } else {
                    isSldPpmChanged = false
                }

                if(!isSldPpmChanged) {
                    console.log(whoami(), "positionSource.onPositionUpdated() -> canvas_key.requestPaint()")
                    canvas_key.key_status = status
                    canvas_key.requestPaint()

                    console.log(whoami(), "positionSource.onPositionUpdated() -> canvas_anchors.requestPaint()")
                    canvas_anchors.requestPaint()
                }
                //txt_key.text = "Calc. Position (" + positionSource.position.coordinate[0].toFixed(2) + ", " +  positionSource.position.coordinate[1].toFixed(2) + ")"

                if(status == 0) {
                    console.log(whoami(), "positionLog -> skip logging")
                } else {
                    var position = positionSource.position
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

            function onPosition2Updated(status) {
                console.log(whoami(), "positionSource.onPosition2Updated()",
                    ", status = ", status)
                console.log(whoami(), "positionSource.onPosition2Updated -> canvas_key2.requestPaint()")
                canvas_key2.key_status = status
                canvas_key2.requestPaint()

                //txt_key2.text = "2nd Calc. Position (" + positionSource.position2.coordinate[0].toFixed(2) + ", " +  positionSource.position2.coordinate[1].toFixed(2) + ")"
            }

            function onAnchorsUpdated() {
                var anchors = positionSource.anchors
                var msg = ""
                for (var i = 0; i < anchors.length; i++) {
                    if(parseFloat(positionSource.params.anchors[i][3])==1.0) {
                        msg += "A" + (i + 1) + ": "
                        msg += "F  = <font color='green'>" + anchors[i].RSSI.toFixed(0) + "dBm</font>, "
                        msg += "Ei = <font color='green'>" + anchors[i].SNR + "</font>, "
                        msg += "Fi = <font color='green'>" + anchors[i].NEV + "</font>, "
                        msg += "Mi = <font color='green'>" + anchors[i].NER + "</font>, "
                        msg += "T  = <font color='green'>" + anchors[i].PER.toFixed(0) + "dBm</font>"

                        if (i < anchors.length - 1)
                            msg += "<br>"
                    }
                }

                receiverStatus.text = msg
            }

            function onZoneUpdated() {
                console.log(whoami(), "positionSource.onZoneUpdated() -> canvas_zone.requestPaint()")
                canvas_zone.activatedZone = positionSource.activatedZone
                canvas_zone.requestPaint()
            }
        }
    }

    Component.onCompleted: {
        positionSource.activate()
    }
}