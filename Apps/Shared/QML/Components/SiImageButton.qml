import QtQuick
import QtQuick.Controls
import Silicium.Theme

ToolButton {

    property bool state: true
    visible: state || Preferences.qtDebug
    implicitHeight: 22
    implicitWidth: 22
    padding: 0
    icon.color: Palette.icon
    icon.width: 16
    icon.height: 16
    background: Rectangle { color: "transparent" }
}
