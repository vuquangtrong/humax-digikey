import QtQuick 2.0
import QtQuick.Controls 2.12

TextField {
    property string lastText

    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter

    font.pointSize: 10

    onFocusChanged: {
        if(text) {
            lastText = text
        }
        if(activeFocus) {
            text = ""
        } else {
            text = lastText
        }
    }
}
