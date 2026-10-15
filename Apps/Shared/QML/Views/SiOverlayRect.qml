import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Sulfur

Rectangle {

    id: root

    // Set by the user of the rect
    property bool hovered: false
    property bool down: false

    // Vertical offset of the drop shadow (negative: the shadow falls upwards)
    property real shadowOffset: 4
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
        shadowVerticalOffset: root.shadowOffset
    }
}
