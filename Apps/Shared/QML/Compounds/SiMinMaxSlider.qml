import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Silicium.Theme

Item {
    id: root

    readonly property bool debug: false

    // Property Aliases
    property alias topText: topLabel.text
    property alias bottomText: bottomLabel.text
    property alias from: control.from
    property alias to: control.to
    // 'value' is the gated model input (see SiSlider.boundValue): it drives the
    // handle except while the user is dragging. Aliasing the slider's plain
    // 'value' instead would let the drag destroy the caller's binding, after
    // which the handle no longer follows the model -- so a factory reset would
    // leave it where the user last dropped it.
    property alias value: control.boundValue
    property alias stepSize: control.stepSize
    property int length: 140

    // The handle's current position, which tracks the drag live. Bind captions
    // to this rather than to 'value', which only changes when the model does.
    readonly property alias liveValue: control.value

    // User-driven changes. Use this for write-back, never an onValueChanged
    // handler: assigning 'value' is what breaks the binding above.
    signal moved(real value)

    // We set a higher implicit height because we now have two rows of content
    implicitWidth: layout.implicitWidth
    implicitHeight: 45

    GridLayout {
        id: layout
        anchors.fill: parent
        columns: 3
        rowSpacing: 2
        columnSpacing: Style.smallSpacing

        // Row 1: - | topText | -
        SiText {
            id: topLabel
            Layout.columnSpan: 3
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: Style.small
            color: Palette.secondary
            elide: Text.ElideRight
        }

        // Row 2: Min Value | Slider | Max Value
        SiText {
            text: control.from.toFixed(1)
            font.pixelSize: Style.small
            color: Palette.secondary
            Layout.alignment: Qt.AlignVCenter
        }

        SiSlider {
            id: control
            Layout.preferredWidth: root.length
            Layout.alignment: Qt.AlignVCenter
            padding: 0

            onMoved: root.moved(control.value)
        }

        SiText {
            text: control.to.toFixed(1)
            font.pixelSize: Style.small
            color: Palette.secondary
            Layout.alignment: Qt.AlignVCenter
        }

        // Row 3: - | bottomText | -
        SiText {
            id: bottomLabel
            Layout.columnSpan: 3
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: Style.small
            color: Palette.secondary
            elide: Text.ElideRight
        }
    }
}