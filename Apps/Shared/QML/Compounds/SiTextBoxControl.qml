import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Silicium.Theme

SiControl {

    id: root
    // property int controlWidth: 0

    property alias text: control.text
    property alias placeholderText: control.placeholderText

    signal accepted()
    signal editingFinished()

    // Let the combo box stretch by default
    // controlWidth: -1

    control: [

        SiTextField {

            id: control
            size: root.size
            Layout.fillWidth: hasFlexControl
            Layout.fillHeight: false
            Layout.preferredWidth: hasFlexControl ? control.implicitWidth : root.controlWidth
            Layout.preferredHeight: Size.controlHeight(root.size)
            Layout.minimumWidth: hasFlexControl ? 40 : root.controlWidth
            Layout.maximumWidth: hasFlexControl ? 9999 : root.controlWidth
            Layout.alignment: Qt.AlignVCenter

            onAccepted: root.accepted()
            onEditingFinished: root.editingFinished()
        }
    ]
}
