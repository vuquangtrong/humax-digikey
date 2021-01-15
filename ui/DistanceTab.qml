import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtCharts 2.3
import Position 1.0

Item {
    id: root
    width: 1920
    height: 1080

    property variant positionSource: obj_DigiKeyFromDevice

    ColumnLayout {
        id: distanceTab
        anchors.fill: parent
        
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ChartView {
                id: graph_distance
                title: qsTr("Distances to Anchors")
                titleFont.pointSize: 10
                titleFont.bold: true
                anchors.fill: parent
                antialiasing: true

                function draw(force = false) {
                    if(force || distanceTab.visible) {
                        graph_distance.removeAllSeries()
                        for (var i = 0; i < positionSource.distanceHistory.length; i++) {
                            var lines = graph_distance.createSeries(
                                        ChartView.SeriesTypeLine, "A" + (i+1),
                                        axis_x_distance, axis_y_distance)
                            var p = positionSource.distanceHistory[i]
                            for (var j = 0; j < p.length; j++) {
                                var d = p[j]
                                axis_y_distance.setRange(d)
                                lines.append(j, d)
                            }
                        }
                    }
                }

                ValueAxis {
                    id: axis_x_distance
                    min: 0
                    max: 60
                    tickCount: 13
                    minorTickCount: 4
                }

                ValueAxis {
                    id: axis_y_distance
                    titleText: qsTr("Distance in meter")
                    function setRange(d) {
                        if (d < min) {
                            min = d
                        } else if (d > max) {
                            max = d
                        }

                        if(min < 0) min = 0
                    }
                }

                Component.onCompleted: graph_distance.draw(true)

                Connections {
                    target: positionSource
                    function onPositionUpdated() {
                        graph_distance.draw()
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ChartView {
                id: graph_position
                title: qsTr("Calcualted Position of Key")
                titleFont.pointSize: 10
                titleFont.bold: true
                anchors.fill: parent
                antialiasing: true

                function draw(force = false) {
                    if(force || distanceTab.visible) {
                        graph_position.removeAllSeries()
                        var names = ['X', 'Y', 'Z']
                        for (var i = 0; i < positionSource.positionHistory.length; i++) {
                            var lines = graph_position.createSeries(
                                        ChartView.SeriesTypeLine, names[i],
                                        axis_x_position, axis_y_position)
                            var p = positionSource.positionHistory[i]
                            for (var j = 0; j < p.length; j++) {
                                var d = p[j]
                                axis_y_position.setRange(d)
                                lines.append(j, d)
                            }
                        }
                    }
                }
                ValueAxis {
                    id: axis_x_position
                    min: 0
                    max: 60
                    tickCount: 13
                    minorTickCount: 4
                }

                ValueAxis {
                    id: axis_y_position
                    titleText: qsTr("Distance in meter")
                    function setRange(d) {
                        if (d < min) {
                            min = d
                        } else if (d > max) {
                            max = d
                        }
                    }
                }

                Component.onCompleted: graph_position.draw(true)

                Connections {
                    target: positionSource
                    function onPositionUpdated(status) {
                        graph_position.draw()
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 40

            RowLayout {
                anchors.fill: parent

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                RoundButton {
                    Layout.preferredWidth: 100
                    Layout.preferredHeight: 30
                    Layout.rightMargin: 30
                    text: qsTr("Reset Chart")
                    onClicked: positionSource.request_clear_history()
                }
            }
        }

        onVisibleChanged: {
            if(visible) {
                graph_distance.draw()
                graph_position.draw()
            }
        }
    }
}