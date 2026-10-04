import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

SiControl {

    id: root

    property alias value: control.value
    property alias readOnly: control.readOnly

    hasFlexControl: false

    signal picked(color value)

    control: [

        SiColorWell {

            id: control
            Layout.alignment: Qt.AlignVCenter
            onPicked: (value) => root.picked(value)
        }
    ]
}
