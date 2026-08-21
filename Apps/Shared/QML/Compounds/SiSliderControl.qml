import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Silicium.Theme

SiControl {

    id: root

    // 'value' is the gated model input (see SiSlider.boundValue): it drives the
    // slider except while the user is dragging. User-driven changes are
    // reported via moved(value) -- use that for write-back so a rounded value
    // can't snap the handle back under the user.
    property alias value: control.boundValue
    property alias from: control.from
    property alias to: control.to
    property alias stepSize: control.stepSize
    property alias snapMode: control.snapMode
    property alias unicolor: control.unicolor

    signal moved(real value)

    control: [

        SiSlider {

            id: control
            enabled: root.enabled

            Layout.fillWidth: hasFlexControl
            Layout.fillHeight: false
            Layout.preferredWidth: hasFlexControl ? control.implicitWidth : root.controlWidth
            Layout.preferredHeight: Size.controlHeight(root.size)
            Layout.minimumWidth: hasFlexControl ? 40 : root.controlWidth
            Layout.maximumWidth: hasFlexControl ? 9999 : root.controlWidth
            Layout.alignment: Qt.AlignVCenter

            from: 0
            to: 100
            stepSize: 1

            onMoved: root.moved(control.value)
        }
    ]
}