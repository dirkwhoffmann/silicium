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

// Port of vAmiga's own GUI/Inspector/AgnusPanel.swift. Its own top-level
// window (see SiAmInspectorWindow.qml).
//
// Four departures from the Swift reference:
//
//  - Cycle counters (VPOS/HPOS) and DMA Control are one SiBox here, not two
//    -- a plain 4-column grid rather than a single-column box stacked on
//    top of a two-column one.
//  - FMODE (the AGA bitplane/sprite fetch-mode register) and DIWHIGH (the
//    ECS/AGA extended display-window register) are new rows in DMA Control
//    -- see SiAmAgnusController's class comment.
//  - Bitplane DMA lists all eight AGA bitplane channels (BPL1PT..BPL8PT),
//    not just the six OCS/ECS ones the Swift reference has fields for.
SiAmInspectorWindow {

    id: root

    title: qsTr("Agnus Inspector")
    currentController: controller.agnusController

    readonly property var agnus: controller.agnusController

    // Shared width for every SiBox (see SiAmCIAPanel)
    readonly property real columnWidth: Math.max(220,
        (scrollView.availableWidth - Style.largeSpacing * 3) / 4)

    // Shared label width for a register name
    readonly property int labelWidth: 62

    // 16-bit registers (DMACON, BPLCON0, FMODE, DDFSTRT/STOP, DIWSTRT/STOP,
    // the four modulo pairs) -- fmt16 in the Swift reference.
    component SiHex16: SiNumberViewControl {
        size: Size.small
        font.weight: 500
        controlWidth: 48
        bits: 16
        base: 16
        padded: true
    }

    // 24-bit DMA pointer/address registers -- fmt24 in the Swift reference.
    component SiHex24: SiNumberViewControl {
        size: Size.small
        font.weight: 500
        controlWidth: 68
        bits: 24
        base: 16
        padded: true
    }

    // One DMA channel row: a read-only "granted a cycle right now" checkbox
    // carrying the register name as its label, followed by the pointer's
    // current value -- the same shape as SiAmBlitterPanel's Blitter Data
    // rows.
    component DmaRow: RowLayout {

        property alias label: box.l
        property alias checked: box.checked
        property alias value: field.value

        spacing: 0

        SiCheckBoxControl { id: box; size: Size.small; readOnly: true; lwidth: root.labelWidth }
        SiHex24 { id: field }
    }

    ScrollView {

        id: scrollView

        anchors.fill: parent
        anchors.margins: Style.mediumSpacing

        clip: true
        contentWidth: content.implicitWidth

        // A single 4-column grid holds all the boxes (see SiAmCIAPanel).
        // GridLayout has no per-column stretch factor, so pin every cell's
        // width to root.columnWidth instead, so all four columns stay
        // equal and track window resizes together.
        GridLayout {

            id: content

            columns: 4
            columnSpacing: Style.largeSpacing
            rowSpacing: Style.largeSpacing

            //
            // Cycle counters + DMA Control
            //

            ColumnLayout {

                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: root.columnWidth
                spacing: Style.mediumSpacing

                SiBox {

                    title: qsTr("DMA Control")
                    Layout.fillWidth: true
                    spacing: Style.smallSpacing

                    GridLayout {

                        Layout.alignment: Qt.AlignHCenter
                        columns: 4
                        columnSpacing: Style.smallSpacing
                        rowSpacing: Style.tinySpacing

                        SiHex16 { l: qsTr("VPOS:"); lwidth: root.labelWidth; value: agnus.vpos }
                        SiHex16 { l: qsTr("HPOS:"); lwidth: root.labelWidth; value: agnus.hpos }

                        SiHex16 { l: qsTr("DMACON:"); lwidth: root.labelWidth; value: agnus.dmacon }
                        SiHex16 { l: qsTr("BPL0CON:"); lwidth: root.labelWidth; value: agnus.bplcon0 }

                        SiHex16 { l: qsTr("FMODE:"); lwidth: root.labelWidth; value: agnus.fmode }
                        Item { }

                        SiHex16 { l: qsTr("DDFSTRT:"); lwidth: root.labelWidth; value: agnus.ddfstrt }
                        SiHex16 { l: qsTr("DDFSTOP:"); lwidth: root.labelWidth; value: agnus.ddfstop }

                        SiHex16 { l: qsTr("DIWSTRT:"); lwidth: root.labelWidth; value: agnus.diwstrt }
                        SiHex16 { l: qsTr("DIWSTOP:"); lwidth: root.labelWidth; value: agnus.diwstop }

                        SiHex16 { l: qsTr("DIWHIGH:"); lwidth: root.labelWidth; value: agnus.diwhigh }
                        Item { }
                    }
                }

                SiBox {

                    title: qsTr("Modulos")
                    Layout.fillWidth: true
                    spacing: Style.smallSpacing

                    GridLayout {

                        Layout.alignment: Qt.AlignHCenter
                        columns: 4
                        columnSpacing: Style.smallSpacing
                        rowSpacing: Style.tinySpacing

                        SiHex16 { l: qsTr("BLTAMOD:"); lwidth: root.labelWidth; value: agnus.bltamod }
                        SiHex16 { l: qsTr("BPL1MOD:"); lwidth: root.labelWidth; value: agnus.bpl1mod }

                        SiHex16 { l: qsTr("BLTBMOD:"); lwidth: root.labelWidth; value: agnus.bltbmod }
                        SiHex16 { l: qsTr("BPL2MOD:"); lwidth: root.labelWidth; value: agnus.bpl2mod }

                        SiHex16 { l: qsTr("BLTCMOD:"); lwidth: root.labelWidth; value: agnus.bltcmod }
                        Item { }

                        SiHex16 { l: qsTr("BLTDMOD:"); lwidth: root.labelWidth; value: agnus.bltdmod }
                        Item { }
                    }
                }

                VSpacer { }
            }

            //
            // Bitplane DMA
            //

            SiBox {

                title: qsTr("Bitplane DMA")
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: root.columnWidth
                spacing: Style.smallSpacing

                ColumnLayout {

                    Layout.alignment: Qt.AlignHCenter
                    spacing: Style.tinySpacing

                    Repeater {

                        model: 8

                        DmaRow {

                            required property int index
                            label: qsTr("BPL%1PT:").arg(index + 1)
                            checked: agnus.bplEnabled(index)
                            value: agnus.bplPt(index)
                        }
                    }
                }
            }

            //
            // Sprite DMA + Audio DMA
            //

            ColumnLayout {

                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: root.columnWidth
                spacing: Style.mediumSpacing

                SiBox {

                    title: qsTr("Sprite DMA")
                    Layout.fillWidth: true
                    spacing: Style.smallSpacing

                    ColumnLayout {

                        Layout.alignment: Qt.AlignHCenter
                        spacing: Style.tinySpacing

                        Repeater {

                            model: 8

                            DmaRow {

                                required property int index
                                label: qsTr("SPR%1PT:").arg(index)
                                checked: agnus.sprEnabled
                                value: agnus.sprPt(index)
                            }
                        }
                    }
                }

                SiBox {

                    title: qsTr("Audio DMA")
                    Layout.fillWidth: true
                    spacing: Style.smallSpacing

                    ColumnLayout {

                        Layout.alignment: Qt.AlignHCenter
                        spacing: Style.tinySpacing

                        Repeater {

                            model: 4

                            RowLayout {

                                required property int index
                                spacing: Style.tinySpacing

                                DmaRow {
                                    label: qsTr("AUD%1PT:").arg(parent.index)
                                    checked: agnus.audEnabled(parent.index)
                                    value: agnus.audPt(parent.index)
                                }
                                SiLabel { text: qsTr("←") }
                                SiHex24 { value: agnus.audLc(parent.index); r: qsTr("AUD%1LC").arg(parent.index) }
                            }
                        }
                    }
                }

                VSpacer { }
            }

            //
            // Blitter DMA + Copper DMA + Disk DMA
            //

            ColumnLayout {

                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: root.columnWidth
                spacing: Style.mediumSpacing

                SiBox {

                    title: qsTr("Blitter DMA")
                    Layout.fillWidth: true
                    spacing: Style.smallSpacing

                    ColumnLayout {

                        Layout.alignment: Qt.AlignHCenter
                        spacing: Style.tinySpacing

                        DmaRow { label: qsTr("BLTAPT:"); checked: agnus.bltEnabled(0); value: agnus.bltPt(0) }
                        DmaRow { label: qsTr("BLTBPT:"); checked: agnus.bltEnabled(1); value: agnus.bltPt(1) }
                        DmaRow { label: qsTr("BLTCPT:"); checked: agnus.bltEnabled(2); value: agnus.bltPt(2) }
                        DmaRow { label: qsTr("BLTDPT:"); checked: agnus.bltEnabled(3); value: agnus.bltPt(3) }

                        SiCheckBoxControl { size: Size.small; readOnly: true; lwidth: root.labelWidth; l: qsTr("BLTPRI:"); checked: agnus.bltPri }
                        SiCheckBoxControl { size: Size.small; readOnly: true; lwidth: root.labelWidth; l: qsTr("BLS:"); checked: agnus.bls }
                    }
                }

                SiBox {

                    title: qsTr("Copper DMA")
                    Layout.fillWidth: true
                    spacing: Style.smallSpacing

                    ColumnLayout {

                        Layout.alignment: Qt.AlignHCenter
                        spacing: Style.tinySpacing

                        DmaRow { label: qsTr("COPPC:"); checked: agnus.copEnabled; value: agnus.coppc }
                    }
                }

                SiBox {

                    title: qsTr("Disk DMA")
                    Layout.fillWidth: true
                    spacing: Style.smallSpacing

                    ColumnLayout {

                        Layout.alignment: Qt.AlignHCenter
                        spacing: Style.tinySpacing

                        DmaRow { label: qsTr("DSKPT:"); checked: agnus.dskEnabled; value: agnus.dskpt }
                    }
                }

                VSpacer { }
            }
        }
    }
}
