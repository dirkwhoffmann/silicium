import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Silicium.Theme

// Read-only numeric display -- the view counterpart to SiNumberInput. Shows
// 'value' formatted in 'base' (2 = binary, 10 = decimal, 16 = hex), zero
// padded to the natural width of a 'bits'-wide value when 'padded' is set.
Item {

    id: control

    property alias font: textElement.font

    property int value: 0

    // Display format
    property int base: 16
    property bool padded: false

    // Width (in bits) of the displayed value -- used to derive the zero-pad
    // width for the current base (e.g. an 8-bit value is 2 hex digits, 8
    // binary digits or 3 decimal digits).
    property int bits: 8

    // Control-size level (see Size)
    property int size: Size.regular

    readonly property int padWidth: base === 16 ? Math.ceil(bits / 4)
                                  : base === 2  ? bits
                                  : Math.floor(bits * Math.log10(2)) + 1

    readonly property string display: {
        var s = (value >>> 0).toString(base)
        if (base === 16) s = s.toUpperCase()
        if (padded) while (s.length < padWidth) s = "0" + s
        return s
    }

    implicitWidth: 48
    implicitHeight: Size.controlHeight(size)
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight
    Layout.fillWidth: true
    Layout.fillHeight: false

    Rectangle {

        anchors.fill: parent
        radius: 4
        color: !control.enabled ? Palette.disabled : Palette.control
        border.color: Palette.controlBorder
        border.width: 1

        // Subtle inner shadow, matching SiNumberInput
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: 4
            color: "transparent"
            border.color: "#15000000"
        }
    }

    SiText {

        id: textElement
        anchors.fill: parent
        leftPadding: Size.hPadding(control.size)
        rightPadding: Size.hPadding(control.size)
        text: control.display
        font.family: Fonts.mono
        font.pixelSize: Size.fontSize(control.size)
        horizontalAlignment: Text.AlignRight
        verticalAlignment: Text.AlignVCenter
        color: control.enabled ? Palette.primary : Palette.tertiary
    }
}
