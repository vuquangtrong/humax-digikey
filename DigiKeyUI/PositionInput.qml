import QtQuick 2.12
import QtQuick.Layouts 1.12

RowLayout {
    id: position

    property int nameWidth: 30
    property alias name: name.text
    property alias px: px.text
    property alias py: py.text
    property alias pz: pz.text

    signal textChanged

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
        onTextChanged: position.textChanged()
    }

    NumberInput {
        id: py
        Layout.preferredHeight: 30
        Layout.preferredWidth: 50
        text: "0.00"
        onTextChanged: position.textChanged()
    }

    NumberInput {
        id: pz
        Layout.preferredHeight: 30
        Layout.preferredWidth: 50
        text: "0.00"
        onTextChanged: position.textChanged()
    }
}
