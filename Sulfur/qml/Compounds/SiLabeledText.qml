import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Sulfur

// A labeled read-only text display -- the text counterpart to
// SiLabeledNumberView. Wraps a SiTextView in the standard SiLabeled
// label/control layout.
SiLabeled {

    id: root

    property alias text: control.text

    control: [

        SiTextView {

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
