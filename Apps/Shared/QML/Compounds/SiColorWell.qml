import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Silicium.Theme

// A small clickable color swatch that opens a ColorDialog and reports the
// picked color via 'picked' -- the caller owns the actual color value and
// feeds it back in through 'value'.
Rectangle {

    id: root

    property color value: "black"

    // When true, the well is a read-only viewer: it ignores taps (no color
    // dialog opens) but still renders at full opacity -- mirrors the
    // readOnly property on SiCheckBox.
    property bool readOnly: false

    signal picked(color value)

    Layout.preferredWidth: 32
    Layout.preferredHeight: 18
    radius: Style.radius
    color: root.value
    border.width: 1
    border.color: Palette.controlBorder

    TapHandler {
        onTapped: if (!root.readOnly) colorDialog.open()
    }

    ColorDialog {

        id: colorDialog
        selectedColor: root.value

        // Live-update as the user drags around in the picker, rather than
        // only reporting the final color on accept.
        onSelectedColorChanged: root.picked(selectedColor)
    }
}
