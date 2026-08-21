import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Silicium.Preferences
import Silicium.Theme

Item {

    id: root

    property alias label: mainLabel.text

    property alias sliderValue: internalSlider.value
    property alias sliderFrom: internalSlider.from
    property alias sliderTo: internalSlider.to

    // Emitted while the user drags the slider (carries the live value). Use
    // this for write-back instead of onSliderValueChanged; sliderValue only
    // drives the slider when idle.
    signal sliderMoved(real value)

    property alias knobValue: internalKnob.value
    property alias knobFrom: internalKnob.from
    property alias knobTo: internalKnob.to

    // Emitted while the user turns the knob (carries the live value). Use this
    // for write-back instead of onKnobValueChanged, so a rounded write-back
    // doesn't fight the drag -- knobValue only drives the dial when idle.
    signal knobMoved(real value)

    property bool slider: true
    property bool knob: true

    implicitWidth: mainCol.implicitWidth
    implicitHeight: mainCol.implicitHeight
    Layout.preferredWidth: root.implicitWidth
    Layout.preferredHeight: root.implicitHeight
    Layout.fillWidth: false
    Layout.fillHeight: true

    DebugRect {}

    ColumnLayout {

        id: mainCol
        anchors.fill: parent
        spacing: Style.smallSpacing

        SiText {

            id: mainLabel
            visible: text !== ""
            Layout.alignment: Qt.AlignHCenter
            font.pixelSize: Style.small
            color: Palette.secondary
        }

        AudioSlider {

            id: internalSlider
            visible: slider
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignHCenter
            from: 0
            to: 100

            onMoved: (value) => root.sliderMoved(value)
        }

        AudioKnob {

            id: internalKnob
            visible: root.knob
            Layout.alignment: Qt.AlignHCenter
            from: 0
            to: 100

            onMoved: (value) => root.knobMoved(value)
        }

        VSpacer {}
    }
}