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

SiAmInspectorWindow {

    id: root

    title: qsTr("Agnus Inspector")
    currentController: controller.agnusController

    readonly property var agnus: controller.agnusController

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
        contentWidth: content.width
        contentHeight: content.height

        // A single 3-column grid holds all the boxes. Columns are sized by
        // GridLayout itself, from each cell's natural content size (the
        // widest cell in that column wins) -- no explicit Layout.preferredWidth
        // anywhere below, unlike SiAmCIAPanel's equal-width columns.
        //
        // A Flickable's content item always sizes to its own implicitWidth/
        // implicitHeight, so a GridLayout inside a ScrollView never grows
        // past what its children need, even when the window is bigger than
        // that -- the extra space just sits blank to the right of / below
        // it. To have the grid (and every Layout.fillWidth/fillHeight cell
        // in it) actually stretch to fill a bigger window, and only fall
        // back to scrolling once the window gets smaller than the natural
        // content size, both dimensions have to be driven explicitly: the
        // larger of the GridLayout's own implicit size and the ScrollView's
        // available size.
        GridLayout {

            id: content

            width: Math.max(implicitWidth, scrollView.availableWidth)
            height: Math.max(implicitHeight, scrollView.availableHeight)

            columns: 3
            columnSpacing: Style.largeSpacing
            rowSpacing: Style.largeSpacing

            //
            // Cycle counters + DMA Control
            //

            ColumnLayout {

                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Style.mediumSpacing

                SiBox {

                    title: qsTr("Cycle Counters")
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: Style.smallSpacing

                    GridLayout {

                        Layout.alignment: Qt.AlignHCenter
                        columns: 2
                        columnSpacing: Style.smallSpacing
                        rowSpacing: Style.tinySpacing

                        SiHex16 { l: qsTr("VPOS:"); lwidth: root.labelWidth; value: agnus.vpos }
                        SiHex16 { l: qsTr("HPOS:"); lwidth: root.labelWidth; value: agnus.hpos }
                    }

                    // VSpacer {}
                }

                SiBox {

                    title: qsTr("DMA Control")
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: Style.smallSpacing

                    GridLayout {

                        Layout.alignment: Qt.AlignHCenter
                        columns: 2
                        columnSpacing: Style.smallSpacing
                        rowSpacing: Style.tinySpacing

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

                // VSpacer { }
            }

            //
            // Bitplane DMA + Sprite DMA
            //

            SiBox {

                title: qsTr("Bitplane DMA")
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Style.smallSpacing

                // 2-column grid: left = the 8 bitplane channels, right = the
                // 8 sprite channels (odd/even model indices, since GridLayout
                // fills row-major and both sides happen to have 8 rows).
                GridLayout {

                    Layout.alignment: Qt.AlignHCenter
                    columns: 2
                    columnSpacing: Style.smallSpacing
                    rowSpacing: Style.tinySpacing

                    Repeater {

                        model: 16

                        DmaRow {

                            required property int index
                            readonly property bool isSprite: index % 2 === 1
                            readonly property int n: Math.floor(index / 2)

                            label: isSprite ? qsTr("SPR%1PT:").arg(n) : qsTr("BPL%1PT:").arg(n + 1)
                            checked: isSprite ? agnus.sprEnabled : agnus.bplEnabled(n)
                            value: isSprite ? agnus.sprPt(n) : agnus.bplPt(n)
                        }
                    }
                }
            }

            //
            // Blitter DMA
            //

            ColumnLayout {

                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Style.mediumSpacing

                SiBox {

                    title: qsTr("Blitter DMA")
                    Layout.fillWidth: true
                    Layout.fillHeight: true
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

                        // VSpacer { }
                    }
                }
            }

            //
            // Modulos
            //

            SiBox {

                title: qsTr("Modulos")
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Style.smallSpacing

                GridLayout {

                    Layout.alignment: Qt.AlignHCenter
                    columns: 2
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

            //
            // Audio DMA
            //

            ColumnLayout {

                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Style.mediumSpacing

                SiBox {

                    title: qsTr("Audio DMA")
                    Layout.fillWidth: true
                    Layout.fillHeight: true
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

                // VSpacer { }
            }

            //
            // Copper DMA + Disk DMA
            //

            ColumnLayout {

                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Style.mediumSpacing

                SiBox {

                    title: qsTr("Copper DMA")
                    Layout.fillWidth: true
                    Layout.fillHeight: true
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
                    Layout.fillHeight: true
                    spacing: Style.smallSpacing

                    ColumnLayout {

                        Layout.alignment: Qt.AlignHCenter
                        spacing: Style.tinySpacing

                        DmaRow { label: qsTr("DSKPT:"); checked: agnus.dskEnabled; value: agnus.dskpt }
                    }
                }

                // VSpacer { }
            }
        }
    }
}
