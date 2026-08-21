import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Silicium.Theme

SiControl {

    id: root

    property alias value: control.value
    property alias base: control.base
    property alias padded: control.padded
    property alias bits: control.bits
    property alias font: control.font

    control: [

        SiNumberView {

            id: control
            size: root.size
            Layout.fillWidth: hasFlexControl
            Layout.fillHeight: false
            Layout.preferredWidth: hasFlexControl ? control.implicitWidth : root.controlWidth
            Layout.preferredHeight: control.implicitHeight
            Layout.minimumWidth: hasFlexControl ? 40 : root.controlWidth
            Layout.maximumWidth: hasFlexControl ? 9999 : root.controlWidth
            Layout.alignment: Qt.AlignVCenter
        }
    ]
}
