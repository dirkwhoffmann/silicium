import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Silicium.Preferences
import Silicium.Theme

// A rotary knob (dial) with optional labels on any of its four sides
// (l / r / t / b -- left, right, top, bottom). Empty label strings collapse
// away. The labels are laid out in a column/row around the dial, so the
// control's implicit size always includes them; a top or bottom label is
// therefore never clipped by a parent (unlike an anchored overlay would be).

ColumnLayout {

    id: root

    // Labels around the knob (empty = hidden).
    property string l: ""
    property string r: ""
    property string t: ""
    property string b: ""

    // The bound (model) value. It drives the dial -- except while the user is
    // actively turning the knob, so a rounded write-back can't fight the drag
    // and cause jitter (see the gated Binding below). User-driven changes are
    // reported through moved() instead, letting the caller live-update the
    // model without moving the dial back under the user's finger.
    property real value: 0
    signal moved(real value)

    property alias from: internalDial.from
    property alias to: internalDial.to

    spacing: Style.smallSpacing

    // Keep the left / right label slots equal width so the dial stays on the
    // same vertical axis as the (horizontally centered) top / bottom labels.
    readonly property int sideWidth: Math.max(leftLabel.implicitWidth, rightLabel.implicitWidth)

    component KnobLabel: SiText {

        font.pixelSize: Style.tiny
        color: Palette.tertiary
    }

    //
    // Top label
    //

    KnobLabel {

        text: root.t
        visible: text !== ""
        Layout.alignment: Qt.AlignHCenter
    }

    //
    // Left label / dial / right label
    //

    RowLayout {

        Layout.alignment: Qt.AlignHCenter
        spacing: Style.smallSpacing

        KnobLabel {

            id: leftLabel
            text: root.l
            visible: text !== ""
            horizontalAlignment: Text.AlignRight
            Layout.preferredWidth: root.sideWidth
            Layout.alignment: Qt.AlignVCenter
        }

        CustomDial {

            id: internalDial
            Layout.alignment: Qt.AlignVCenter

            from: 0
            to: 100
            wrap: false

            // Fires only on user interaction (not on programmatic changes), so
            // the caller can live-update its model without a feedback loop.
            onMoved: root.moved(internalDial.value)
        }

        // Push the bound value into the dial, but never while the user is
        // turning it -- otherwise a rounded write-back would snap the dial
        // back under the user's finger. On release the dial re-syncs.
        Binding {
            target: internalDial
            property: "value"
            value: root.value
            when: !internalDial.pressed
            restoreMode: Binding.RestoreNone
        }

        KnobLabel {

            id: rightLabel
            text: root.r
            visible: text !== ""
            horizontalAlignment: Text.AlignLeft
            Layout.preferredWidth: root.sideWidth
            Layout.alignment: Qt.AlignVCenter
        }
    }

    //
    // Bottom label
    //

    KnobLabel {

        text: root.b
        visible: text !== ""
        Layout.alignment: Qt.AlignHCenter
    }

    //
    // The dial itself
    //

    component CustomDial: Dial {

        id: control
        implicitWidth: 27
        implicitHeight: 27

        // Background track
        background: Rectangle {

            x: control.topPadding
            y: control.leftPadding
            width: control.availableWidth
            height: control.availableHeight
            radius: width / 2
            color: Palette.surface
            border.color: Palette.background
            border.width: 1
        }

        // Handle
        handle: Rectangle {

            id: handleElement
            x: control.background.x + control.background.width / 2 - width / 2
            y: control.background.y + control.background.height / 2 - height / 2
            width: 6
            height: 6
            radius: width / 2
            color: Palette.primary

            // Subtle macOS-style border
            border.color: "#30000000"
            border.width: 0.5

            // Position the handle along the circular path
            transform: [

                Translate {
                    y: -((control.background.width - handleElement.width) / 2) + 2
                },
                Rotation {
                    angle: control.angle
                    origin.x: handleElement.width / 2
                    origin.y: handleElement.height / 2
                }
            ]
        }
    }
}
