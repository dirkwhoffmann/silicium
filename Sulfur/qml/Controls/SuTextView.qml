import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Sulfur

// Read-only text display -- the text counterpart to SuNumberView. Shows
// 'text' in the same boxed, control-styled look used for numeric readouts.
Item {

    id: control

    property string text: ""

    // Control-size level (see Size)
    property int size: Size.regular

    implicitWidth: 48
    implicitHeight: Size.controlHeight(size)
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight
    Layout.fillWidth: true
    Layout.fillHeight: false

    Rectangle {

        anchors.fill: parent
        radius: 4
        color: !control.enabled ? Palette.disabled : Palette.inset
        border.color: Palette.insetBorder
        border.width: 1

        // Subtle inner shadow, matching SuNumberInput
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: 4
            color: "transparent"
            border.color: "#15000000"
        }
    }

    SuText {

        anchors.fill: parent
        leftPadding: Size.hPadding(control.size)
        rightPadding: Size.hPadding(control.size)
        text: control.text
        font.pixelSize: Size.fontSize(control.size)
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        color: control.enabled ? Palette.primary : Palette.tertiary
    }
}
