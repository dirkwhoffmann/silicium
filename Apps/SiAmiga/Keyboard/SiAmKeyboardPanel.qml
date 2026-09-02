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
// cut away -- zero for every other key. Every key, Return included, is a
// KeyCap (see KeyCap.qml) -- one component draws both, since KeyCap takes
// its outline as a plain polygon (shapePoints) and only special-cases a
// notched one internally, not this file.

ColumnLayout {

    id: root

    required property SiAmController controller
    readonly property var kc: controller.keyboardController

    // Builds Return's outline: the bounding box with its top-left corner
    // cut away from (0,0) across to (nw,0) down to (nw,nh) then left to
    // (0,nh) -- leaving a wide bottom (this row) and a narrower, right-
    // aligned top (the row above), which is exactly the ISO/Amiga Enter
    // shape. Traced starting at the notch's own inner corner so the
    // polygon closes cleanly back there.
    function notchPolygon(w, h, nw, nh) {

        return [
            Qt.point(nw, nh), Qt.point(nw, 0), Qt.point(w, 0),
            Qt.point(w, h), Qt.point(0, h), Qt.point(0, nh)
        ]
    }

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

            delegate: KeyCap {

                id: keyItem

                x: model.x * root.scale
                y: model.y * root.scale
                width: model.width * root.scale
                height: model.height * root.scale

                label: model.label

                // A plain rectangle for every ordinary key; Return's own
                // notch cut (see AmigaKeyModel.h) for the one key whose
                // notchWidth/notchHeight aren't zero. Recomputing the
                // rectangle explicitly here (rather than leaving shapePoints
                // at its own default) keeps this the single place that
                // decides a key's outline, matching how label/x/y/width/
                // height are all driven from 'model' too.
                shapePoints: (model.notchWidth > 0 || model.notchHeight > 0)
                             ? root.notchPolygon(width, height, model.notchWidth * root.scale, model.notchHeight * root.scale)
                             : [Qt.point(0, 0), Qt.point(width, 0), Qt.point(width, height), Qt.point(0, height)]

                // Return's own visual "center of mass" sits in its wider
                // bottom half, not the bounding box's true center.
                labelVerticalOffset: (model.notchHeight * root.scale) / 2

                // Return's own click target is still its whole bounding
                // rectangle, notch included -- but that's harmless, because
                // AmigaKeyModel adds Return *first* in every layout (see
                // AmigaKeyModel::buildA500Ansi() and friends), so every key
                // that visually overlaps the notch (here, "]") comes later
                // and is stacked on top by the Repeater, both for painting
                // and for mouse hit-testing. A click in the notch therefore
                // always reaches the key actually drawn there, never
                // Return's own MouseArea underneath.

                onPressedKey: kc.press(model.nr)
                onReleasedKey: kc.release(model.nr)

                Connections {

                    target: kc

                    function onKeyChanged(nr, isPressed) {

                        if (nr === -1 || nr === model.nr) {
                            keyItem.down = (nr === model.nr && isPressed)
                        }
                    }
                }
            }
        }
    }
}
