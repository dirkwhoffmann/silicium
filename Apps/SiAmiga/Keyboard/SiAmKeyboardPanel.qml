// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes
import QtQuick.Effects
import Silicium.Controllers
import Silicium.Theme

// Visual content of the virtual Amiga keyboard, port of SiC64KeyboardPanel.qml.
// The C64 panel's icon bar (SHIFT/Commodore/CTRL preview toggles, lowercase
// switch) has no counterpart here -- the Amiga keyboard has no equivalent
// "preview a modifier's key caps" feature in AmigaKeyModel (that model has
// no per-modifier label variants at all yet, see AmigaKeyModel.h), so this
// is just the key grid, unlike SiC64KeyboardPanel's header row + grid.
//
// The interesting difference is Return: on a real Amiga keyboard it's an
// upside-down L (ISO Enter shape), not a rectangle. AmigaKeyModel encodes
// that as an ordinary bounding-box key (x/y/width/height) plus a
// notchWidth/notchHeight pair describing how much of the top-left corner to
// cut away -- zero for every other key. This Repeater renders most keys as
// a plain SiButton, but swaps in a QtQuick.Shapes polygon for the one key
// where notchWidth is non-zero.

ColumnLayout {

    id: root

    required property SiAmController controller
    readonly property var kc: controller.keyboardController

    // AmigaKeyModel's positions/sizes are already in pixels (lifted
    // straight from vAmiga's A500ANSI.xib), so unlike SiC64KeyboardPanel
    // there's no separate keyUnit/keyGap grid multiplication -- just an
    // overall scale factor for resizing the whole keyboard.
    readonly property real scale: 0.85

    spacing: 0

    Item {

        implicitWidth: childrenRect.width
        implicitHeight: childrenRect.height

        Repeater {

            model: root.kc.keyModel

            delegate: Item {

                id: keyItem

                readonly property bool isReturn: model.notchWidth > 0 || model.notchHeight > 0
                readonly property bool pressed: mouseArea.pressed || button.down

                x: model.x * root.scale
                y: model.y * root.scale
                width: model.width * root.scale
                height: model.height * root.scale

                //
                // Ordinary rectangular keys
                //

                SiButton {

                    id: button

                    visible: !keyItem.isReturn
                    anchors.fill: parent
                    accentedDown: true
                    text: model.label
                    font.pixelSize: model.label.indexOf("\n") !== -1 ? Style.tiny : Style.regular

                    onPressed: kc.press(model.nr)
                    onReleased: kc.release(model.nr)
                }

                //
                // Return: an L-shaped polygon instead of a rectangle. The
                // path cuts the top-left corner away -- from (0,0) across
                // to (notchWidth,0) down to (notchWidth,notchHeight) then
                // left to (0,notchHeight) -- leaving a wide bottom (this
                // row) and a narrower, right-aligned top (the row above),
                // which is exactly the ISO/Amiga Enter shape.
                //
                // The click target is the whole bounding rectangle, notch
                // included -- the same simplification vAmiga's own Mac app
                // makes (its Return button's hit-testable frame is the
                // full bounding box too; only the key-cap artwork shows
                // the notch). A precise hit region would need the same
                // polygon fed to a containsMouse()-style override, which
                // isn't worth it for a corner nobody will try to click.
                //

                Shape {

                    id: returnShape
                    visible: keyItem.isReturn
                    anchors.fill: parent
                    antialiasing: true

                    // Corner radius matching SiButton's own background
                    // Rectangle (radius: Style.radius), so the Return key
                    // reads the same as every other key.
                    readonly property real nw: model.notchWidth * root.scale
                    readonly property real nh: model.notchHeight * root.scale
                    readonly property real kw: keyItem.width
                    readonly property real kh: keyItem.height
                    readonly property real r: Style.radius

                    // SiButton gets its visual weight from a lighter-to-darker
                    // gradient plus a drop shadow (see SiButton.qml's own
                    // background Rectangle) -- a flat fill/stroke here just
                    // blended into the panel background, so the shape needs
                    // the same treatment to read as a raised key.
                    layer.enabled: true
                    layer.effect: MultiEffect {

                        shadowEnabled: true
                        shadowColor: "#40000000"
                        shadowBlur: 0.1
                        shadowVerticalOffset: 1
                        shadowHorizontalOffset: 1
                    }

                    ShapePath {

                        readonly property color baseColor: keyItem.pressed ? Palette.accentElevated : Palette.widget

                        fillGradient: LinearGradient {
                            x1: 0; y1: 0
                            x2: 0; y2: keyItem.height
                            GradientStop { position: 0.0; color: Qt.lighter(returnPath.baseColor, 1.4) }
                            GradientStop { position: 1.0; color: Qt.darker(returnPath.baseColor, 1.05) }
                        }
                        strokeColor: keyItem.pressed ? Palette.accent : Palette.widgetShadow
                        strokeWidth: 1
                        joinStyle: ShapePath.RoundJoin

                        id: returnPath

                        // Starts at the notch's inner corner (V5) -- the one
                        // corner left sharp, matching real ISO-Enter keycaps
                        // whose inner corner is a plain right angle even
                        // though the outer corners are rounded. Every other
                        // corner is a straight edge run up to r short of the
                        // corner, then a quarter-circle PathArc around it.
                        startX: returnShape.nw
                        startY: returnShape.nh

                        // Round V0 (top of the notch)
                        PathLine { x: returnShape.nw; y: returnShape.r }
                        PathArc {
                            x: returnShape.nw + returnShape.r; y: 0
                            radiusX: returnShape.r; radiusY: returnShape.r
                            direction: PathArc.Clockwise
                        }
                        // Round V1 (top-right)
                        PathLine { x: returnShape.kw - returnShape.r; y: 0 }
                        PathArc {
                            x: returnShape.kw; y: returnShape.r
                            radiusX: returnShape.r; radiusY: returnShape.r
                            direction: PathArc.Clockwise
                        }
                        // Round V2 (bottom-right)
                        PathLine { x: returnShape.kw; y: returnShape.kh - returnShape.r }
                        PathArc {
                            x: returnShape.kw - returnShape.r; y: returnShape.kh
                            radiusX: returnShape.r; radiusY: returnShape.r
                            direction: PathArc.Clockwise
                        }
                        // Round V3 (bottom-left)
                        PathLine { x: returnShape.r; y: returnShape.kh }
                        PathArc {
                            x: 0; y: returnShape.kh - returnShape.r
                            radiusX: returnShape.r; radiusY: returnShape.r
                            direction: PathArc.Clockwise
                        }
                        // Round V4 (bottom of the notch)
                        PathLine { x: 0; y: returnShape.nh + returnShape.r }
                        PathArc {
                            x: returnShape.r; y: returnShape.nh
                            radiusX: returnShape.r; radiusY: returnShape.r
                            direction: PathArc.Clockwise
                        }
                        // Back to V5 (sharp), closing the path
                        PathLine { x: returnShape.nw; y: returnShape.nh }
                    }
                }

                SiText {

                    visible: keyItem.isReturn
                    anchors.centerIn: returnShape
                    anchors.verticalCenterOffset: (model.notchHeight * root.scale) / 2
                    text: model.label
                    color: keyItem.pressed ? Palette.accentText : Palette.primary
                }

                MouseArea {

                    id: mouseArea
                    visible: keyItem.isReturn
                    anchors.fill: parent
                    onPressed: kc.press(model.nr)
                    onReleased: kc.release(model.nr)
                }

                Connections {

                    target: kc

                    function onKeyChanged(nr, isPressed) {

                        if (nr === -1 || nr === model.nr) {
                            button.down = (nr === model.nr && isPressed) ? true : undefined
                        }
                    }
                }
            }
        }
    }
}
