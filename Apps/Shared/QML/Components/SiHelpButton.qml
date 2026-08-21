import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Silicium.Theme

SiSymbolButton {

    property int alignment: Qt.AlignRight

    symbol: "help"
    Layout.alignment: Qt.AlignVCenter
    font.pixelSize: 19

    DebugRect {}
}
