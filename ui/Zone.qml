import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import QtQuick.Shapes 1.12

ShapePath {
    id: zone
    property var pointA: [0, 0]
    property var pointB: [100, 100]
    property var arcA: [0, 45]
    property var arcB: [90, 45]
    property var arcR: 100

    startX: pointA[0]
    startY: pointA[1]
    
    PathLine { 
        x: zone.pointB[0]
        y: zone.pointB[1]
    }

    PathAngleArc {
        moveToStart: false
        centerX: zone.pointB[0]
        centerY: zone.pointB[1]
        radiusX: zone.arcR
        radiusY: zone.arcR
        startAngle: zone.arcA[0]
        sweepAngle: zone.arcA[1]
    }

    PathAngleArc {
        moveToStart: false
        centerX: zone.pointA[0]
        centerY: zone.pointA[1]
        radiusX: zone.arcR
        radiusY: zone.arcR
        startAngle: zone.arcB[0]
        sweepAngle: zone.arcB[1]
    }
}
