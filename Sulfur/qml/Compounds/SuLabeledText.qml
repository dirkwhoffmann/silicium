import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Sulfur

// A labeled read-only text display -- the text counterpart to
// SuLabeledNumberView. Wraps a SuTextView in the standard SuLabeled
// label/control layout.
SuLabeled {

    id: root

    property alias text: control.text

    control: [

        SuTextView {

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
