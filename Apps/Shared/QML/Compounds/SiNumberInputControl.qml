import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Silicium.Theme

SiControl {

    id: root

    property alias value: control.text
    property int intValue: 0
    property alias placeholderText: control.placeholderText
    property int minValue: 0
    property int maxValue: 999999

    onIntValueChanged: {

        var parsedField = parseInt(control.text) || 0
        if (root.intValue !== parsedField) {
            control.text = root.intValue.toString()
        }
    }

    /* Emitted once the user has finished editing the field. Write the value
     * back to whatever 'intValue' is bound to from here.
     *
     * Do not assign intValue itself: callers bind it to a config option or a
     * preference, and a QML assignment would destroy that binding. The field
     * would then stop following its source -- which is what used to break
     * "Restore factory defaults" for every text-input option. Writing to the
     * source instead lets the value travel back through the existing binding,
     * so a clamped or rejected value also shows up correctly.
     */
    signal valueEdited(int value)

    signal editingFinished()

    control: [

        SiNumberInput {

            id: control
            size: root.size
            Layout.fillWidth: hasFlexControl
            Layout.fillHeight: false
            Layout.preferredWidth: hasFlexControl ? control.implicitWidth : root.controlWidth
            Layout.preferredHeight: Size.controlHeight(root.size)
            Layout.minimumWidth: hasFlexControl ? 40 : root.controlWidth
            Layout.maximumWidth: hasFlexControl ? 9999 : root.controlWidth
            Layout.alignment: Qt.AlignVCenter
        }
    ]
}