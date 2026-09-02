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
// The C64 panel's icon bar toggles independent modifier-preview switches
// (SHIFT/Commodore/CTRL/lowercase); AmigaKeyModel has no per-modifier label
// variants to preview, so SiAmKeyboardIconBar's toggles do something
// different instead -- they pick which of the four physical Amiga keyboards
// (A500/A1000 x ANSI/ISO) is on screen, which is why the Binding targets
// below go to keyModel's a1000/iso properties rather than shiftPressed-style
// preview flags.
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

    spacing: Style.largeSpacing

    //
    // Layout selection
    //
    // Key cap labels and positions follow the icon bar's A500/A1000 and
    // ANSI/ISO toggles, which together pick one of AmigaKeyModel's four
    // built-in key tables -- see AmigaKeyModel::build().
    //

    Binding { target: kc.keyModel; property: "a1000"; value: iconBar.a1000 }
    Binding { target: kc.keyModel; property: "iso"; value: iconBar.iso }

    //
    // Header row
    //

    RowLayout {

        id: headerRow

        Layout.fillWidth: true
        Layout.fillHeight: false
        spacing: Style.mediumSpacing

        HSpacer {}

        SiAmKeyboardIconBar { id: iconBar }

        HSpacer {}

        SiTemplateImage {

            id: mouseIcon1
            source: Assets.iconUrl(Assets.MousePress)
            opacity: 0.5
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
        }

        SiTemplateImage {

            id: mouseIcon2
            source: Assets.iconUrl(Assets.MousePush)
            opacity: 0.5
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            Layout.rightMargin: 10
        }
    }

    //
    // Key section
    //

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
                // Return's own click target is still its whole bounding
                // rectangle, notch included -- but that's harmless, because
                // AmigaKeyModel adds Return *first* in every layout (see
                // AmigaKeyModel::buildA500Ansi() and friends), so every key
                // that visually overlaps the notch (here, "]") comes later
                // and is stacked on top by the Repeater, both for painting
                // and for mouse hit-testing. A click in the notch therefore
                // always reaches the key actually drawn there, never
                // Return's own MouseArea underneath.
                //

                // Return is rendered as an ordinary Rectangle background
                // (returnBg, pixel-identical to SiButton's own -- Palette.
                // widget, lighter(1.4)/darker(1.05)) clipped to the notch
                // polygon via a Shape used purely as an alpha mask
                // (returnShape). ShapePath.fillColor/fillGradient silently
                // fails to paint at all on some of the notch's smaller
                // instances (e.g. the A1000 layouts) when given
                // Palette.widget directly -- reproducible, not tied to any
                // one renderer backend, and specific to colors close in
                // lightness to the panel background -- so the actual key
                // color never goes through ShapePath at all here; the mask
                // is filled with plain opaque black instead (only its alpha
                // coverage is ever used, so its own color doesn't matter,
                // and black was never affected by the failure). Both
                // returnBg and returnShape run through a ShaderEffectSource
                // with hideSource: true -- the standard way to keep an item
                // in the scene graph (so MultiEffect can sample it) without
                // it also drawing itself directly on top.

                Rectangle {

                    id: returnBg
                    visible: keyItem.isReturn
                    anchors.fill: parent

                    border.color: keyItem.pressed ? Palette.accent : Palette.widgetShadow
                    border.width: 1

                    gradient: Gradient {

                        GradientStop {
                            position: 0.0
                            color: (keyItem.pressed ? Palette.accentElevated : Palette.widget).lighter(1.4)
                        }
                        GradientStop {
                            position: 1.0
                            color: (keyItem.pressed ? Palette.accentElevated : Palette.widget).darker(1.05)
                        }
                    }
                }

                Shape {

                    id: returnShape
                    visible: keyItem.isReturn
                    anchors.fill: parent
                    antialiasing: true

                    readonly property real nw: model.notchWidth * root.scale
                    readonly property real nh: model.notchHeight * root.scale
                    readonly property real kw: width
                    readonly property real kh: height
                    readonly property real r: Style.radius

                    ShapePath {

                        fillColor: "black"

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

                ShaderEffectSource {

                    id: returnBgSource
                    sourceItem: returnBg
                    hideSource: true
                    live: true
                    anchors.fill: returnBg
                    visible: false
                }

                ShaderEffectSource {

                    id: returnMaskSource
                    sourceItem: returnShape
                    hideSource: true
                    live: true
                    anchors.fill: returnShape
                    visible: false
                }

                MultiEffect {

                    visible: keyItem.isReturn
                    anchors.fill: parent
                    source: returnBgSource
                    maskEnabled: true
                    maskSource: returnMaskSource
                    maskThresholdMin: 0.5
                    maskSpreadAtMin: 0.0

                    // Same drop shadow SiButton gets from its own background
                    // Rectangle, so the notched key reads as raised too.
                    shadowEnabled: true
                    shadowColor: "#40000000"
                    shadowBlur: 0.1
                    shadowVerticalOffset: 1
                    shadowHorizontalOffset: 1
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
