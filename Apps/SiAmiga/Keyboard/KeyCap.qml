// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

import QtQuick
import Silicium.Theme

// A single Amiga keyboard key cap: solid background, solid border, label,
// and press/release input. Every key on the virtual keyboard
// (SiAmKeyboardPanel.qml) is one of these -- plain rectangular keys and the
// notched Return key alike -- so there is exactly one place that draws a
// key rather than a special-cased branch for Return.
//
// The shape is the bounding box minus an optional notch cut out of its
// top-left corner (notchWidth/notchHeight, both zero for an ordinary key),
// drawn as the union of two rounded rectangles: a vertical one covering
// everything right of the notch, and a horizontal one covering everything
// below it. That union is where Return's upside-down-L comes from. Every
// corner of it that is a real corner of the key is one of the two
// rectangles' own rounded corners; the two corners that land inside the
// union (the vertical slab's bottom-left, the horizontal slab's top-right)
// are covered by the other rectangle, and the notch's inner corner, where
// the two outlines cross, stays a sharp right angle -- matching real
// ISO-Enter keycaps.
//
// The border is a second pair of rectangles rather than Rectangle.border:
// the shape is drawn once in the border color, then again one border width
// smaller in the fill color, leaving a uniform border showing underneath
// that follows the true outline, notch included. Rectangle.border alone
// only ever traces one rectangle's own four edges, so it cannot draw the
// notch's two inner edges at all.

Item {

    id: root

    property string label: ""
    property bool down: false
    readonly property bool pressed: mouseArea.pressed || down
    property real fontPixelSize: label.indexOf("\n") !== -1 ? Style.tiny : Style.regular

    property real radius: Style.radius
    property real borderWidth: 1

    // The notch cut out of the top-left corner. Both zero for an ordinary
    // rectangular key.
    property real notchWidth: 0
    property real notchHeight: 0

    // A notched key's visual centre of mass sits in its wider lower half,
    // not at the bounding box's own centre.
    property real labelVerticalOffset: notchHeight / 2

    readonly property color fillColor: pressed ? Palette.accentElevated : Palette.widget
    readonly property color borderColor: Qt.darker(pressed ? Palette.accent : Palette.widgetShadow, 1.4)

    signal pressedKey()
    signal releasedKey()

    implicitWidth: 40
    implicitHeight: 40

    // The key's whole shape in one flat color, optionally shrunk inward on
    // every edge -- drawn twice below, once for the border and once, one
    // border width smaller, for the fill.
    component Slab: Item {

        id: slab

        property color slabColor
        property real slabRadius: 0
        property real slabInset: 0

        anchors.fill: parent

        // Everything to the right of the notch, full height.
        Rectangle {

            x: root.notchWidth + slab.slabInset
            y: slab.slabInset
            width: slab.width - root.notchWidth - 2 * slab.slabInset
            height: slab.height - 2 * slab.slabInset
            radius: slab.slabRadius
            color: slab.slabColor
        }

        // Everything below the notch, full width -- only needed when there
        // is a notch at all, since without one this is the same rectangle
        // over again.
        Rectangle {

            visible: root.notchWidth > 0 && root.notchHeight > 0
            x: slab.slabInset
            y: root.notchHeight + slab.slabInset
            width: slab.width - 2 * slab.slabInset
            height: slab.height - root.notchHeight - 2 * slab.slabInset
            radius: slab.slabRadius
            color: slab.slabColor
        }
    }

    Slab {

        slabColor: root.borderColor
        slabRadius: root.radius
    }

    Slab {

        slabColor: root.fillColor
        slabRadius: Math.max(0, root.radius - root.borderWidth)
        slabInset: root.borderWidth
    }

    SiText {

        anchors.centerIn: parent
        anchors.verticalCenterOffset: root.labelVerticalOffset
        width: parent.width - 2 * Style.tinySpacing
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.Wrap
        elide: Text.ElideRight
        text: root.label
        font.pixelSize: root.fontPixelSize
        color: root.pressed ? Palette.accentText : Palette.primary
    }

    MouseArea {

        id: mouseArea
        anchors.fill: parent
        onPressed: root.pressedKey()
        onReleased: root.releasedKey()
    }
}
