import QtQuick
import QtQuick.Controls
import Silicium.Preferences

Rectangle {
    visible: Preferences.qtDebug
    anchors.fill: parent
    color: "red"
    opacity: 0.3
    z: -1
}