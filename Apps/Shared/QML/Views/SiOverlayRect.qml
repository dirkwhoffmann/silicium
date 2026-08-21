import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Silicium.Theme

Rectangle {

    id: root
    anchors.topMargin: 0
    anchors.bottomMargin: 2
    anchors.leftMargin: 0
    anchors.rightMargin: 0
    radius: Style.borderRadius
    color: root.hovered ? "#E0000000" : "#C0000000"
    border.color: root.down ? "#90ffffff" : "#50ffffff"

    layer.enabled: true
    layer.effect: MultiEffect {

        shadowEnabled: true
        shadowColor: "#80000000"
        shadowBlur: 0.8
        shadowVerticalOffset: 4
    }
}
