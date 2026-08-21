import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Silicium.Theme

TextField {

    id: control

    // Control-size level (see Size)
    property int size: Size.regular

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
        bottom: root.minValue; top: root.maxValue
    }
    inputMethodHints: Qt.ImhDigitsOnly

    onEditingFinished: {
        root.valueEdited(parseInt(control.text) || 0)
        root.editingFinished()
    }

    // onEditingFinished: root.editingFinished()

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
