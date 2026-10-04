import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Sulfur

TextField {

    id: control

    // Control-size level (see Size)
    property int size: Size.regular

    // The range of numbers the field accepts
    property int minValue: 0
    property int maxValue: 999999

    // Emitted once the user has finished editing, with the number entered
    signal valueEdited(int value)

    implicitWidth: 48
    implicitHeight: Size.controlHeight(size)
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight
    Layout.fillWidth: true
    Layout.fillHeight: false
    Layout.topMargin: 2
    Layout.bottomMargin: 2

    topPadding: 0
    bottomPadding: 0
    leftPadding: Size.hPadding(size)
    rightPadding: Size.hPadding(size)
    horizontalAlignment: Text.AlignRight
    font.pixelSize: Size.fontSize(size)
    color: control.enabled ? Palette.primary : Palette.tertiary
    verticalAlignment: Text.AlignVCenter

    // Restrict input exclusively to whole numbers
    validator: IntValidator {
        bottom: control.minValue; top: control.maxValue
    }
    inputMethodHints: Qt.ImhDigitsOnly

    onEditingFinished: control.valueEdited(parseInt(control.text) || 0)

    background: Rectangle {

        id: inputBackground
        radius: 4
        color: !control.enabled ? Palette.disabled : control.activeFocus ? Palette.controlSelected : Palette.control
        border.color: control.activeFocus ? Palette.controlBorderSelected : Palette.controlBorder
        border.width: 1

        // Subtle inner shadow for text fields
        Rectangle {
            anchors.fill: parent
            radius: 4
            color: "transparent"
            border.color: "#15000000"
            anchors.margins: 1
        }
    }
}
