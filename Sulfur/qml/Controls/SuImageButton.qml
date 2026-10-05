import QtQuick
import QtQuick.Controls
import Sulfur

ToolButton {

    property bool state: true
    visible: state || SulfurSettings.debug
    implicitHeight: 22
    implicitWidth: 22
    padding: 0
    icon.color: Palette.secondary
    icon.width: 16
    icon.height: 16
    background: Rectangle { color: "transparent" }
}
