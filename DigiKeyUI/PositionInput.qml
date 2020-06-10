import QtQuick 2.12
import QtQuick.Layouts 1.12

RowLayout {
    id: position

    property int nameWidth: 30
    property alias name: name.text
    property alias px: px
    property alias py: py
    property alias pz: pz

    signal pxTextChanged
    signal pyTextChanged
    signal pzTextChanged

    Text {
        id: name
        horizontalAlignment: Text.AlignRight
        Layout.preferredWidth: nameWidth
        text: "A"
    }

    NumberInput {
        id: px
        Layout.preferredHeight: 30
        Layout.preferredWidth: 50
        text: "0.00"
        onTextChanged: position.pxTextChanged()
    }

    NumberInput {
        id: py
        Layout.preferredHeight: 30
        Layout.preferredWidth: 50
        text: "0.00"
        onTextChanged: position.pyTextChanged()
    }

    NumberInput {
        id: pz
        Layout.preferredHeight: 30
        Layout.preferredWidth: 50
        text: "0.00"
        onTextChanged: position.pzTextChanged()
    }
}
