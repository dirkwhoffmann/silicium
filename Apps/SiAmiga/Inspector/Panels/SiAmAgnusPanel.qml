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
        SiWord24ViewControl { id: field }
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
        //
        // width/height are set imperatively (via the handlers below) rather
        // than as plain `width: Math.max(implicitWidth, ...)` bindings.
        // Declaring it as a direct binding makes QtQuick Layouts report a
        // "Binding loop detected for property width/height": setting width
        // re-stretches this GridLayout's Layout.fillWidth/fillHeight
        // children, which re-triggers the internal size-hint recalculation
        // that implicitWidth/Height is read from, so the binding's own
        // dependency gets rewritten while it's still being evaluated. The
        // resulting value is stable (it converges immediately), but the
        // engine's loop detector flags the reentrant evaluation regardless.
        // Doing the same computation from onImplicitWidthChanged/
        // onImplicitHeightChanged instead is a plain, one-shot property
        // assignment rather than a tracked binding, so it isn't subject to
        // that diagnostic (see SiAmBlitterPanel.qml for the original fix).
        GridLayout {

            id: content

            function updateWidth() { width = Math.max(implicitWidth, scrollView.availableWidth) }
            function updateHeight() { height = Math.max(implicitHeight, scrollView.availableHeight) }

            Component.onCompleted: { updateWidth(); updateHeight() }
            onImplicitWidthChanged: updateWidth()
            onImplicitHeightChanged: updateHeight()

            Connections {
                target: scrollView
                function onAvailableWidthChanged() { content.updateWidth() }
                function onAvailableHeightChanged() { content.updateHeight() }
            }

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

                        SiWordViewControl { l: qsTr("VPOS:"); lwidth: root.labelWidth; value: agnus.vpos }
                        SiWordViewControl { l: qsTr("HPOS:"); lwidth: root.labelWidth; value: agnus.hpos }
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

                        SiWordViewControl { l: qsTr("DMACON:"); lwidth: root.labelWidth; value: agnus.dmacon }
                        SiWordViewControl { l: qsTr("BPL0CON:"); lwidth: root.labelWidth; value: agnus.bplcon0 }

                        SiWordViewControl { l: qsTr("FMODE:"); lwidth: root.labelWidth; value: agnus.fmode }
                        Item { }

                        SiWordViewControl { l: qsTr("DDFSTRT:"); lwidth: root.labelWidth; value: agnus.ddfstrt }
                        SiWordViewControl { l: qsTr("DDFSTOP:"); lwidth: root.labelWidth; value: agnus.ddfstop }

                        SiWordViewControl { l: qsTr("DIWSTRT:"); lwidth: root.labelWidth; value: agnus.diwstrt }
                        SiWordViewControl { l: qsTr("DIWSTOP:"); lwidth: root.labelWidth; value: agnus.diwstop }

                        SiWordViewControl { l: qsTr("DIWHIGH:"); lwidth: root.labelWidth; value: agnus.diwhigh }
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

                    SiWordViewControl { l: qsTr("BLTAMOD:"); lwidth: root.labelWidth; value: agnus.bltamod }
                    SiWordViewControl { l: qsTr("BPL1MOD:"); lwidth: root.labelWidth; value: agnus.bpl1mod }

                    SiWordViewControl { l: qsTr("BLTBMOD:"); lwidth: root.labelWidth; value: agnus.bltbmod }
                    SiWordViewControl { l: qsTr("BPL2MOD:"); lwidth: root.labelWidth; value: agnus.bpl2mod }

                    SiWordViewControl { l: qsTr("BLTCMOD:"); lwidth: root.labelWidth; value: agnus.bltcmod }
                    Item { }

                    SiWordViewControl { l: qsTr("BLTDMOD:"); lwidth: root.labelWidth; value: agnus.bltdmod }
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
                                SiWord24ViewControl { value: agnus.audLc(parent.index); r: qsTr("AUD%1LC").arg(parent.index) }
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
