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

/* A ring that turns while a job runs.
 *
 * The arc is as long as the job is far along, and the whole thing rotates
 * whatever that length is. The rotation is what says "still working": a job
 * that sits at one figure for a while -- unpacking an image, say, where there
 * is nothing to count -- would otherwise look stuck.
 */
Item {

    id: root

    // 0.0 ... 1.0
    property real value: 0.0

    property color color: Palette.accent
    property color backgroundColor: Palette.backdrop
    property real thickness: 4
    property int period: 1400

    implicitWidth: 48
    implicitHeight: 48

    // Never quite empty, or there would be nothing to see turning
    readonly property real sweep: Math.max(0.08, Math.min(1.0, value))

    onSweepChanged: ring.requestPaint()
    onColorChanged: ring.requestPaint()
    onBackgroundColorChanged: ring.requestPaint()

    Canvas {

        id: ring
        anchors.fill: parent

        onPaint: {

            const ctx = getContext("2d")
            ctx.reset()

            const r = Math.min(width, height) / 2 - root.thickness / 2
            const cx = width / 2
            const cy = height / 2

            ctx.lineWidth = root.thickness
            ctx.lineCap = "round"

            // The track the arc runs on
            ctx.beginPath()
            ctx.strokeStyle = root.backgroundColor
            ctx.arc(cx, cy, r, 0, 2 * Math.PI)
            ctx.stroke()

            // The arc itself, starting at twelve o'clock
            ctx.beginPath()
            ctx.strokeStyle = root.color
            ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + root.sweep * 2 * Math.PI)
            ctx.stroke()
        }

        RotationAnimator {

            target: ring
            running: root.visible
            loops: Animation.Infinite
            from: 0
            to: 360
            duration: root.period
        }
    }
}
