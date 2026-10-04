import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Silicium.Preferences
import Sulfur

Item {

    id: root

    property string topLabelText: "Lorem"
    property string bottomLabelText: "Ipsum"

    property string maxLabelText: "MAX"
    property string midLabelText: "MID"
    property string minLabelText: "MIN"

    // 'value' is the gated model input (see SuSlider.boundValue); user-driven
    // changes are reported via moved(value). Use that for write-back so a
    // rounded value can't fight the drag.
    property alias value: internalSlider.boundValue
    property alias from: internalSlider.from
    property alias to: internalSlider.to

    signal moved(real value)

    implicitWidth: mainRow.implicitWidth
    implicitHeight: mainRow.implicitHeight
    Layout.preferredWidth: root.implicitWidth
    Layout.preferredHeight: root.implicitHeight
    Layout.fillWidth: false
    Layout.fillHeight: true

    DebugRect {}

    component SliderLabel: SuText {

        Layout.alignment: Qt.AlignLeft
        font.pixelSize: Style.tiny
        color: Palette.tertiary
    }

    // Labeled Slider
    RowLayout {

        id: mainRow
        anchors.fill: parent
        spacing: Style.smallSpacing

        HSpacer { size: labelColumn.width }

        SuSlider {

            id: internalSlider
            orientation: Qt.Vertical
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignHCenter

            from: 0
            to: 100

            onMoved: root.moved(internalSlider.value)
        }

        ColumnLayout {

            id: labelColumn
            Layout.fillHeight: true

            SliderLabel {
                text: root.maxLabelText
            }

            HSpacer {
            }

            SliderLabel {
                text: root.midLabelText
            }

            HSpacer {
            }

            SliderLabel {
                text: root.minLabelText
            }
        }
    }
}