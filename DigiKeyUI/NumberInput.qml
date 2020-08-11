import QtQuick 2.0
import QtQuick.Controls 2.12

TextField {
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    leftPadding: 6

    font.pointSize: 10

    onFocusChanged: {
        var f = parseFloat(text)
        if(!isNaN(f)) {
            text = f
        } else {
            text = 0
        }
    }

    function getValue() {
        var v = parseFloat(text)
        if (isNaN(v)) v = 0
        return v
    }
}
