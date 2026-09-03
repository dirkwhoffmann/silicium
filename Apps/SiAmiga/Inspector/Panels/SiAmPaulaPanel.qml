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

// Port of vAmiga's own GUI/Inspector/PaulaPanel.swift -- there is no C64
// counterpart to port from (Paula's interrupt controller, disk controller
// and audio DMA state machines have no C64 equivalent). A plain page
// inside SiAmInspectorWindow's sidebar StackLayout (see that file), not
// its own window; SiAmInspectorWindow.updateActiveController() drives
// controller.paulaController.active for it, the same way it already does
// for the other panels.
//
// The one piece with no off-the-shelf Silicium control to reuse is the
// four "State machine N" diagrams -- the Swift reference swaps in one of
// five bitmap assets (Resources/Assets.xcassets/Audio/state0Template.pdf
// .. state5Template.pdf) showing a 5-node graph with the active node
// filled in. Rather than ship five new bitmap assets, StateDiagram below
// draws the same 5-node graph (and the same 7 edges connecting them --
// see SiAmPaulaController's class comment for the exact transition table
// the filled node follows) with a plain QtQuick Canvas, so the "state"
// numbering and the topology are pixel-for-pixel decisions made once here
// rather than baked into images.
Item {

    id: root

    required property SiAmController controller

    readonly property var paula: controller.paulaController
    readonly property var ic: controller.inspectorController
    readonly property int numBase: ic.hex ? 16 : 10
    readonly property bool numPadded: ic.padded

    component SiHex8: SiNumberViewControl {
        size: Size.small
        font.weight: 500
        controlWidth: 44
        bits: 8
        base: root.numBase
        padded: root.numPadded
    }

    component SiHex16: SiNumberViewControl {
        size: Size.small
        font.weight: 500
        controlWidth: 64
        bits: 16
        base: root.numBase
        padded: root.numPadded
    }

    // A single FIFO byte slot -- blank once its index reaches
    // paula.fifoCount, unlike SiHex8 (which always shows a formatted
    // number) -- see SiAmPaulaController::fifoAt().
    component FifoCell: Rectangle {

        property string value: ""

        implicitWidth: 36
        implicitHeight: Size.controlHeight(Size.small)
        radius: 4
        color: Palette.control
        border.width: 1
        border.color: Palette.controlBorder

        SiText {
            anchors.centerIn: parent
            text: parent.value
            font.family: Fonts.mono
            font.weight: 500
        }
    }

    // Five-node DMA state-machine diagram -- see the class comment. Nodes
    // are laid out A(state0, left) - B(state1) - C(state5) - D(state2,
    // right) along the top, with E(state3) at the bottom; edges: A->B,
    // A->D (direct, taken when DMA is off), B->C, C->D, D->E, E->D and
    // E->A, matching SiAmPaulaController's transition table exactly.
    component StateDiagram: Canvas {

        id: diagram

        property int currentState: 0

        implicitWidth: 150
        implicitHeight: 120

        readonly property var nodes: ({
            0: Qt.point(20, 60),
            1: Qt.point(58, 32),
            5: Qt.point(96, 32),
            2: Qt.point(132, 60),
            3: Qt.point(96, 96)
        })

        onCurrentStateChanged: requestPaint()
        Component.onCompleted: requestPaint()

        onPaint: {

            var ctx = getContext("2d")
            ctx.reset()

            var r = 9
            var lineColor = Palette.tertiary

            function drawArrow(from, to, bend) {

                // Control point offset perpendicular to the from->to line,
                // so 'bend' > 0 curves one way and < 0 the other -- lets
                // the direct A->D and E->A edges arc well clear of the
                // short chain between them.
                var mx = (from.x + to.x) / 2
                var my = (from.y + to.y) / 2
                var dx = to.x - from.x
                var dy = to.y - from.y
                var len = Math.max(1, Math.sqrt(dx * dx + dy * dy))
                var nx = -dy / len
                var ny = dx / len
                var cx = mx + nx * bend
                var cy = my + ny * bend

                // Shorten the line so it doesn't dive under the node
                // circles.
                var t0 = r / len
                var sx = from.x + dx * t0
                var sy = from.y + dy * t0
                var ex = to.x - dx * t0
                var ey = to.y - dy * t0

                ctx.strokeStyle = lineColor
                ctx.lineWidth = 1.4
                ctx.beginPath()
                ctx.moveTo(sx, sy)
                ctx.quadraticCurveTo(cx, cy, ex, ey)
                ctx.stroke()

                // Arrowhead pointing along the curve's tangent at the end.
                var tx = ex - cx
                var ty = ey - cy
                var tl = Math.max(1, Math.sqrt(tx * tx + ty * ty))
                tx /= tl; ty /= tl

                var ah = 6
                ctx.fillStyle = lineColor
                ctx.beginPath()
                ctx.moveTo(ex, ey)
                ctx.lineTo(ex - ah * tx + ah * 0.5 * ty, ey - ah * ty - ah * 0.5 * tx)
                ctx.lineTo(ex - ah * tx - ah * 0.5 * ty, ey - ah * ty + ah * 0.5 * tx)
                ctx.closePath()
                ctx.fill()
            }

            drawArrow(nodes[0], nodes[1], -10)
            drawArrow(nodes[0], nodes[2], -34)
            drawArrow(nodes[1], nodes[5], -8)
            drawArrow(nodes[5], nodes[2], -8)
            drawArrow(nodes[2], nodes[3], 14)
            drawArrow(nodes[3], nodes[2], -14)
            drawArrow(nodes[3], nodes[0], 34)

            for (var key in nodes) {

                var p = nodes[key]
                var active = Number(key) === currentState

                ctx.beginPath()
                ctx.arc(p.x, p.y, r, 0, 2 * Math.PI)
                ctx.fillStyle = active ? Palette.primary : Palette.background
                ctx.fill()
                ctx.strokeStyle = lineColor
                ctx.lineWidth = 1.4
                ctx.stroke()
            }
        }
    }

    RowLayout {

        anchors.fill: parent
        anchors.margins: Style.mediumSpacing
        spacing: Style.mediumSpacing

        //
        // Interrupts
        //

        SiBox {

            title: qsTr("Interrupts")
            Layout.preferredWidth: 260
            Layout.fillHeight: true
            spacing: Style.tinySpacing

            ColumnLayout {

                Layout.alignment: Qt.AlignHCenter
                spacing: Style.tinySpacing

                RowLayout {
                    spacing: Style.tinySpacing
                    SiHex16 { l: qsTr("INTENA"); lwidth: 55; value: paula.intena }
                    SiHex16 { value: paula.intreq }
                    SiLabel { text: qsTr("INTREQ") }
                }

                Repeater {

                    model: 15

                    RowLayout {

                        required property int index
                        readonly property int bit: 14 - index
                        spacing: Style.largeSpacing

                        SiCheckBoxControl {
                            readOnly: true
                            checked: paula.intenaBit(bit)
                            l: paula.intBitLabel(bit)
                            lwidth: 55
                        }

                        SiCheckBoxControl {
                            readOnly: true
                            checked: paula.intreqBit(bit)
                            l: paula.intBitLabel(bit)
                            lwidth: 55
                        }
                    }
                }
            }
        }

        //
        // Disk Controller
        //

        SiBox {

            title: qsTr("Disk Controller")
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Style.mediumSpacing

            ColumnLayout {

                Layout.alignment: Qt.AlignHCenter
                spacing: Style.tinySpacing

                RowLayout {
                    spacing: Style.smallSpacing
                    SiLabel { text: qsTr("Selected Drive:") }
                    Repeater {
                        model: 4
                        RowLayout {
                            required property int index
                            spacing: 2
                            SiLabel { text: index }
                            SiCheckBoxControl { readOnly: true; checked: paula.selectedDrive === index }
                        }
                    }
                }

                RowLayout {
                    spacing: Style.smallSpacing
                    SiLabel { text: qsTr("State:") }
                    SiLabel { text: paula.dcStateText; font.weight: 500 }
                }

                RowLayout {
                    Layout.topMargin: Style.smallSpacing
                    spacing: Style.tinySpacing
                    SiHex16 { l: qsTr("DSKLEN"); lwidth: 65; value: paula.dsklen }
                    SiHex8 { value: paula.adkconHi }
                    SiLabel { text: qsTr("ADKCON HI") }
                }

                GridLayout {

                    Layout.topMargin: Style.smallSpacing
                    columns: 2
                    columnSpacing: Style.largeSpacing
                    rowSpacing: Style.tinySpacing

                    SiCheckBoxControl { readOnly: true; checked: paula.dmaen; l: qsTr("DMAEN"); lwidth: 90 }
                    SiCheckBoxControl { readOnly: true; checked: paula.precomp1; l: qsTr("PRECOMP1"); lwidth: 90 }

                    SiCheckBoxControl { readOnly: true; checked: paula.write; l: qsTr("WRITE"); lwidth: 90 }
                    SiCheckBoxControl { readOnly: true; checked: paula.precomp0; l: qsTr("PRECOMP0"); lwidth: 90 }

                    SiHex16 { l: qsTr("DSKBYTE"); lwidth: 90; value: paula.dskbytr }
                    SiCheckBoxControl { readOnly: true; checked: paula.mfmprec; l: qsTr("MFMPREC"); lwidth: 90 }

                    SiCheckBoxControl { readOnly: true; checked: paula.byteready; l: qsTr("BYTEREADY"); lwidth: 90 }
                    SiCheckBoxControl { readOnly: true; checked: paula.uartbrk; l: qsTr("UARTBRK"); lwidth: 90 }

                    SiCheckBoxControl { readOnly: true; checked: paula.dmaon; l: qsTr("DMAON"); lwidth: 90 }
                    SiCheckBoxControl { readOnly: true; checked: paula.wordsync; l: qsTr("WORDSYNC"); lwidth: 90 }

                    SiCheckBoxControl { readOnly: true; checked: paula.diskwrite; l: qsTr("DISKWRITE"); lwidth: 90 }
                    SiCheckBoxControl { readOnly: true; checked: paula.msbsync; l: qsTr("MSBSYNC"); lwidth: 90 }

                    SiCheckBoxControl { readOnly: true; checked: paula.wordequal; l: qsTr("WORDEQUAL"); lwidth: 90 }
                    SiCheckBoxControl { readOnly: true; checked: paula.fast; l: qsTr("FAST"); lwidth: 90 }
                }

                RowLayout {

                    Layout.topMargin: Style.smallSpacing
                    spacing: Style.tinySpacing

                    SiHex16 { l: qsTr("DSKSYNC"); lwidth: 65; value: paula.dsksync }

                    SiText {
                        visible: paula.dsksyncWarning
                        text: qsTr("(expected 4489)")
                        color: "#E0A030"
                    }
                }

                SiBox {

                    Layout.topMargin: Style.mediumSpacing
                    Layout.fillWidth: true
                    title: qsTr("FIFO Buffer")
                    color: Palette.control
                    borderColor: Palette.controlBorder

                    RowLayout {

                        Layout.alignment: Qt.AlignHCenter
                        spacing: Style.smallSpacing

                        SiText { text: "→" }

                        Repeater {
                            model: 6
                            FifoCell {
                                required property int index
                                value: paula.fifoAt(index)
                            }
                        }

                        SiText { text: "→" }
                    }
                }
            }
        }

        //
        // Audio
        //

        SiBox {

            title: qsTr("Audio")
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Style.mediumSpacing

            ColumnLayout {

                Layout.alignment: Qt.AlignHCenter
                spacing: Style.mediumSpacing

                GridLayout {

                    Layout.alignment: Qt.AlignHCenter
                    columns: 5
                    columnSpacing: Style.mediumSpacing
                    rowSpacing: Style.tinySpacing

                    Item { Layout.preferredWidth: 80 }
                    Repeater { model: 4; SiLabel { required property int index; text: index; horizontalAlignment: Text.AlignHCenter; Layout.preferredWidth: 64 } }

                    SiLabel { text: qsTr("AUDxLEN"); Layout.preferredWidth: 80 }
                    Repeater { model: 4; SiHex16 { required property int index; value: paula.audioLen(index) } }

                    SiLabel { text: qsTr("AUDxPER"); Layout.preferredWidth: 80 }
                    Repeater { model: 4; SiHex16 { required property int index; value: paula.audioPer(index) } }

                    SiLabel { text: qsTr("AUDxVOL"); Layout.preferredWidth: 80 }
                    Repeater { model: 4; SiHex16 { required property int index; value: paula.audioVol(index) } }

                    SiLabel { text: qsTr("AUDxDAT"); Layout.preferredWidth: 80 }
                    Repeater { model: 4; SiHex16 { required property int index; value: paula.audioDat(index) } }
                }

                GridLayout {

                    Layout.topMargin: Style.mediumSpacing
                    columns: 2
                    columnSpacing: Style.mediumSpacing
                    rowSpacing: Style.mediumSpacing

                    Repeater {

                        model: 4

                        ColumnLayout {

                            required property int index
                            spacing: Style.tinySpacing

                            SiLabel { text: qsTr("State machine %1").arg(index); font.weight: 500 }
                            StateDiagram { currentState: paula.displayState(index) }
                        }
                    }
                }
            }
        }
    }
}
