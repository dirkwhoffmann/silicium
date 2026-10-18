import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Sulfur

// A single Amiga keyboard key cap. Every key on the virtual keyboard
// (SiAmKeyboardPanel.qml) is one of these -- plain rectangular keys and the
// notched Return key alike.
//
// The look matches the C64 keyboard, whose keys are SuButtons: a vertical
// gradient fill, a one pixel border, a soft drop shadow and a thin highlight
// along the top edge. A pressed key turns accent colored.
//
// An ordinary key is a gradient Rectangle, exactly like a SuButton. The
// Return key is not a rectangle: its bounding box has a notch cut out of the
// top-left corner (notchWidth/notchHeight, both zero for an ordinary key),
// which leaves an upside-down L. It is drawn as a Shape that follows the
// true outline, with the same gradient, border, shadow and highlight. Every
// real corner of the outline is rounded; the notch's inner corner stays a
// sharp right angle, as on real ISO-Enter keycaps.

Item {

    id: root

    property string label: ""

    // A picture drawn instead of the label (e.g., the logo on the Amiga keys)
    property url image: ""

    // Draws the label vertically (rotated by 90 degrees), as it is printed on
    // the keypad's Enter key
    property bool vertical: false

    property bool down: false
    readonly property bool pressed: mouseArea.pressed || down

    // The label is drawn in the largest of a few fixed sizes that lets it
    // fit on a single line (the text is never wrapped or squeezed). Labels
    // with an explicit line break (e.g., "Caps\nLock") use the smallest.
    readonly property real textSpace: (vertical ? height : width) - 2 * Style.tinySpacing - 2
    readonly property real fontPixelSize: {

        if (label.indexOf("\n") !== -1) return Style.tiny

        const perPixel = textMetrics.boundingRect.width / textMetrics.font.pixelSize
        const sizes = [Style.regular, Style.small, Style.tiny]
        for (const size of sizes) {
            if (perPixel * size <= textSpace) return size
        }

        // Even the smallest size does not fit: shrink it to the space
        return Math.max(textSpace / perPixel, 0.5 * Style.tiny)
    }

    property real radius: Style.radius
    property real borderWidth: 1

    // The notch cut out of the top-left corner. Both zero for an ordinary
    // rectangular key.
    property real notchWidth: 0
    property real notchHeight: 0

    // A notched key's visual centre of mass sits in its wider lower half,
    // not at the bounding box's own centre.
    property real labelVerticalOffset: notchHeight / 2

    signal pressedKey()
    signal releasedKey()
    signal toggledKey()

    implicitWidth: 40
    implicitHeight: 40

    // Colors as in SuButton (accentedDown)
    readonly property color bgColor: pressed ? Palette.accentElevated : Palette.widget
    readonly property color edgeColor: pressed ? Palette.accent : Palette.widgetBorder
    readonly property bool notched: notchWidth > 0 && notchHeight > 0

    // Gradient, border, drop shadow and highlight, shared by both shapes
    readonly property color gradientTop: bgColor.lighter(1.4)
    readonly property color gradientBottom: bgColor.darker(1.05)

    component Shadow: MultiEffect {

        shadowEnabled: true
        shadowColor: "#40000000"
        shadowBlur: 0.1
        shadowVerticalOffset: 1
        shadowHorizontalOffset: 1
    }

    // Ordinary keys
    Rectangle {

        visible: !root.notched
        anchors.fill: parent
        radius: root.radius
        border.color: root.edgeColor
        border.width: root.borderWidth

        gradient: Gradient {

            GradientStop { position: 0.0; color: root.gradientTop }
            GradientStop { position: 1.0; color: root.gradientBottom }
        }

        layer.enabled: !root.notched
        layer.effect: Shadow { }
    }

    // The notched Return key
    Shape {

        id: notchedShape

        visible: root.notched
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        layer.enabled: root.notched
        layer.effect: Shadow { }

        // The outline is inset by half the stroke width so that the border
        // lies inside the bounding box, like Rectangle.border does
        readonly property real inset: root.borderWidth / 2
        readonly property real r: root.radius
        readonly property real x0: inset
        readonly property real y0: inset
        readonly property real x1: width - inset
        readonly property real y1: height - inset
        readonly property real nx: root.notchWidth
        readonly property real ny: root.notchHeight

        ShapePath {

            strokeColor: root.edgeColor
            strokeWidth: root.borderWidth

            fillGradient: LinearGradient {

                x1: 0; y1: 0
                x2: 0; y2: notchedShape.height

                GradientStop { position: 0.0; color: root.gradientTop }
                GradientStop { position: 1.0; color: root.gradientBottom }
            }

            // Clockwise, starting at the top edge to the right of the notch
            startX: notchedShape.nx + notchedShape.r
            startY: notchedShape.y0

            PathLine { x: notchedShape.x1 - notchedShape.r; y: notchedShape.y0 }
            PathArc { x: notchedShape.x1; y: notchedShape.y0 + notchedShape.r; radiusX: notchedShape.r; radiusY: notchedShape.r }
            PathLine { x: notchedShape.x1; y: notchedShape.y1 - notchedShape.r }
            PathArc { x: notchedShape.x1 - notchedShape.r; y: notchedShape.y1; radiusX: notchedShape.r; radiusY: notchedShape.r }
            PathLine { x: notchedShape.x0 + notchedShape.r; y: notchedShape.y1 }
            PathArc { x: notchedShape.x0; y: notchedShape.y1 - notchedShape.r; radiusX: notchedShape.r; radiusY: notchedShape.r }
            PathLine { x: notchedShape.x0; y: notchedShape.ny + notchedShape.r }
            PathArc { x: notchedShape.x0 + notchedShape.r; y: notchedShape.ny; radiusX: notchedShape.r; radiusY: notchedShape.r }

            // The notch's inner corner is a sharp right angle
            PathLine { x: notchedShape.nx; y: notchedShape.ny }
            PathLine { x: notchedShape.nx; y: notchedShape.y0 + notchedShape.r }
            PathArc { x: notchedShape.nx + notchedShape.r; y: notchedShape.y0; radiusX: notchedShape.r; radiusY: notchedShape.r }
        }
    }

    // Highlight along the top edge (of the part that is not notched away)
    Rectangle {

        x: root.notchWidth + 4
        y: 1
        width: root.width - root.notchWidth - 8
        height: 1
        color: "#80ffffff"
    }

    // Measures the label at a reference size (see fontPixelSize)
    TextMetrics {

        id: textMetrics

        font.family: Fonts.main
        font.pixelSize: 100
        text: root.label
    }

    SuText {

        visible: root.image == ""
        anchors.centerIn: parent
        anchors.verticalCenterOffset: root.labelVerticalOffset
        width: root.textSpace
        rotation: root.vertical ? -90 : 0
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.NoWrap
        text: root.label
        font.pixelSize: root.fontPixelSize
        color: root.pressed ? Palette.accentText : Palette.primary
    }

    Image {

        visible: root.image != ""
        anchors.centerIn: parent
        width: parent.width - 2 * Style.smallSpacing
        height: parent.height * 0.7
        source: root.image
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
    }

    MouseArea {

        id: mouseArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        // The right button toggles the key without releasing it
        onPressed: (mouse) => mouse.button === Qt.RightButton ? root.toggledKey() : root.pressedKey()
        onReleased: (mouse) => { if (mouse.button === Qt.LeftButton) root.releasedKey() }
    }
}
