import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Silicium.Theme

SiControl {

    id: root

    property alias checked: control.checked
    property alias checkBoxText: control.text
    property alias readOnly: control.readOnly
    property alias bitStyle: control.bitStyle

    hasFlexControl: false

    signal clicked()

    control: [

        SiCheckBox {

            id: control
            size: root.size
            Layout.preferredHeight: Size.controlHeight(root.size)
            onClicked: root.clicked()
        }
    ]
}