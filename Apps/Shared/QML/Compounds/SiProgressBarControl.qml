import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Silicium.Theme

SiControl {

    id: root

    property alias value: control.value
    property alias from: control.from
    property alias to: control.to
    property alias indeterminate: control.indeterminate

    control: [

        SiProgressBar {

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
