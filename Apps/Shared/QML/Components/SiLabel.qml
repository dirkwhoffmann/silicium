import QtQuick
import QtQuick.Controls
import Silicium.Theme

Label {

    // Control-size level (see Size). Regular maps to the app's base font size,
    // so unsized labels are unchanged.
    property int size: Size.regular

    font.family: Fonts.main
    font.pixelSize: Size.fontSize(size)
    color: enabled ? Palette.primary : Palette.disabled
}
