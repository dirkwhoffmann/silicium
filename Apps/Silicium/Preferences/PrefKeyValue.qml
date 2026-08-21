import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Silicium.Theme

RowLayout {

    property alias key: keyLabel.text
    property alias value: valueLabel.text

    property int keyWidth: 100
    property int valueWidth: 150

    spacing: 15
    Layout.fillWidth: true

    SiText {

        id: keyLabel
        Layout.preferredWidth: keyWidth
        horizontalAlignment: Text.AlignRight
        color: Palette.secondary
        elide: Text.ElideRight
    }

    SiText {

        id: valueLabel
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignLeft
        color: Palette.primary
        font.bold: true
        elide: Text.ElideRight
    }

    HSpacer { }
}