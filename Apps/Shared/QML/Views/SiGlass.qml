// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

import QtQuick
import QtQuick.Effects
import Silicium.Theme

/* Frosted-glass fill: a blurred copy of the page artwork shining through a
 * translucent tint. Meant as the 'background' of a Pane.
 *
 * Qt Quick cannot blur "whatever happens to be behind" an item -- the scene
 * graph offers no read-back of what has already been drawn. So this draws its
 * own copy of the artwork, aligned with the real one and blurred, then clips it
 * to its own bounds. Only the named backdrop shines through; siblings drawn
 * between it and this item do not.
 *
 * The blur is applied through layer.effect rather than by feeding a
 * ShaderEffectSource into a MultiEffect: an item's layer is rendered as part of
 * drawing that item, whereas a separate capture item has to be rendered in its
 * own right to produce a texture at all -- which a hidden one may never be.
 * layer.effect is also the pattern used elsewhere in this project.
 *
 * With no backdrop this degrades to a plain tinted rectangle.
 */
Item {

    id: root

    // Artwork to blur
    property Image backdrop: null

    /* Opaque fill drawn under the blurred copy, hiding the original artwork
     * beneath this pane.
     *
     * This is what makes the blur visible at all. The artwork is RGBA and only
     * ~36% opaque on average, so without an opaque base the blurred copy
     * composites over the *sharp* original underneath and roughly two thirds of
     * the crisp detail survives -- no blur setting can compensate. Use whatever
     * colour the artwork normally sits on, so only the blur changes.
     */
    property color base: Palette.background

    // Laid over the blurred copy. Alpha is what sells the effect.
    property color tint: "#20ffffff"

    // Blur strength, 0..1, scaled by blurMax (see MultiEffect). Note that
    // MultiEffect caps the useful blurMax at 64; beyond that nothing changes.
    property real blurAmount: 1.0
    property int blurMax: 32

    // Corner radius. 0 leaves the pane square and skips the masking pass.
    property real radius: 0

    // The copy is as large as the whole artwork, so crop it to this pane.
    clip: true

    /* Rounding the corners needs a mask, not a radius.
     *
     * Item.clip is rectangular, and putting a radius on the base and tint
     * rectangles alone is not enough: the blurred copy between them keeps its
     * square corners, which show wherever the artwork has content there (2 of 4
     * corners, measured). Masking the finished pane cuts all four.
     */
    layer.enabled: root.radius > 0
    layer.effect: MultiEffect {

        maskEnabled: true
        maskSource: cornerMask
        // Masking only -- no padding, so the mask can't drift from the content.
        autoPaddingEnabled: false

        // A child of the effect rather than of the pane: a child of the pane
        // would be captured into the very layer it is meant to mask.
        Item {

            id: cornerMask
            width: root.width
            height: root.height
            visible: false
            layer.enabled: true

            Rectangle {

                anchors.fill: parent
                radius: root.radius
                color: "white"
            }
        }
    }

    /* Position of the artwork's origin in our own coordinates, so the copy can
     * be laid exactly over the original.
     *
     * mapFromItem() is not something a binding can track, so the geometry it
     * depends on is read explicitly to make this re-evaluate. Width and height
     * of both items cover the cases that occur here -- this pane only ever
     * moves when the window resizes, which resizes the artwork too.
     */
    readonly property point origin: {

        const w = root.width
        const h = root.height
        const bw = root.backdrop ? root.backdrop.width : 0
        const bh = root.backdrop ? root.backdrop.height : 0

        if (w <= 0 || h <= 0 || bw <= 0 || bh <= 0) return Qt.point(0, 0)

        return root.mapFromItem(root.backdrop, 0, 0)
    }

    Rectangle {

        anchors.fill: parent
        color: root.base
    }

    Image {

        // Same source, size and fill mode as the original, so the copy lands
        // pixel-for-pixel on top of it before being blurred.
        visible: root.backdrop !== null && root.backdrop.visible
        x: root.origin.x
        y: root.origin.y
        width: root.backdrop ? root.backdrop.width : 0
        height: root.backdrop ? root.backdrop.height : 0
        source: root.backdrop ? root.backdrop.source : ""
        fillMode: root.backdrop ? root.backdrop.fillMode : Image.PreserveAspectFit

        layer.enabled: true
        layer.effect: MultiEffect {

            blurEnabled: true
            blur: root.blurAmount
            blurMax: root.blurMax
        }
    }

    Rectangle {

        anchors.fill: parent
        color: root.tint
    }
}
