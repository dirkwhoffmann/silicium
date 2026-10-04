import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

SuSymbolButton {

    property int alignment: Qt.AlignRight

    symbol: "help"
    Layout.alignment: Qt.AlignVCenter
    font.pixelSize: 19

    DebugRect {}
}
