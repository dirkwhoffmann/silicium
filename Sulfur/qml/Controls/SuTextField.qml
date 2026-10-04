import QtQuick
import QtQuick.Controls

TextField {

    // Control-size level (see Size)
    property int size: Size.regular

    font.family: Fonts.main
    font.pixelSize: Size.fontSize(size)
}
