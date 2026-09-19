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
import Silicium.Components
import Silicium.Controllers
import Silicium.Theme

// SiAmDenisePanel's "Registers" tab -- split out into its own file once the
// panel's five BPLCONx columns (each now a full 16-bit list plus its own
// decoded sub-field(s)) made SiAmDenisePanel.qml too long to navigate
// comfortably alongside the Colors and Sprites tabs. Split purely for size;
// no behavior changed. denise/numBase/numPadded/lw/hlw/indent all come from
// SiAmDenisePanel's own root properties of the same name -- see its class
// comment for what each one is for.
RowLayout {

    id: root

    required property var denise
    required property int numBase
    required property bool numPadded
    required property int lw
    required property int hlw
    required property int indent

    spacing: Style.mediumSpacing

    //
    // Subcomponents
    //

    component Si1: SiBitViewControl {

        size: Size.tiny
    }

    component Si8: SiByteViewControl {

        size: Size.small
        controlWidth: 36
        base: root.numBase
        padded: root.numPadded
    }

    component Si16: SiWordViewControl {

        size: Size.small
        controlWidth: 44
        base: root.numBase
        padded: root.numPadded
    }

    component HRule: Rectangle {

        Layout.fillWidth: true
        Layout.topMargin: Style.tinySpacing
        Layout.bottomMargin: Style.tinySpacing
        implicitHeight: 1
        color: Palette.tertiary
    }

    //
    // Control -- BPLCON0..4, two groups per row (BPLCON0/1,
    // then 2/3, then 4 alone) via a 2-column outer grid --
    // GridLayout's default left-to-right/top-to-bottom flow
    // lands each in the right cell with no explicit
    // Layout.row/column. Each group's own bit list is
    // itself a 2-column grid, so a 13-entry group (BPLCON0,
    // the tallest) only needs 7 rows. Wrapped in a
    // SiScrollBox (rather than depending on getting the
    // fixed sizing exactly right) so if this ever doesn't
    // quite fit some window size, it scrolls instead of
    // overflowing into Display Window/Data beside it --
    // SiBox's own Pane never clips its content. root.lw/
    // indent and Si16's controlWidth are all trimmed down
    // from their usual defaults too, purely to keep the box
    // itself compact.
    //

    SiScrollBox {

        title: qsTr("Control")
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Style.mediumSpacing

        RowLayout {

            Layout.fillWidth: true
            spacing: Style.largeSpacing

            // BPLCON0 -- bit 15 down to bit 0, no gaps: even
            // BPU's 4 bits (2/1/0 grouped near HIRES, 3 on
            // its own at bit 4) and every other multi-bit
            // field show up as individual checkboxes at
            // their real bit position, exactly like the
            // genuinely single-bit flags -- reading straight
            // off the raw register value rather than through
            // the controller's decoded bpu/hires/etc.
            // properties, so the layout can show all 16
            // bits uniformly instead of some as bits and
            // some as a decoded number.
            ColumnLayout {

                spacing: -1

                Si16 { l: qsTr("BPLCON0"); lwidth: root.lw; value: denise.bplcon0 }
                VSpacer { size: Style.smallSpacing }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("HIRES");  checked: !!(denise.bplcon0 & 0x8000) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("BPU2");   checked: !!(denise.bplcon0 & 0x4000) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("BPU1");   checked: !!(denise.bplcon0 & 0x2000) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("BPU0");   checked: !!(denise.bplcon0 & 0x1000) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("HAM");    checked: !!(denise.bplcon0 & 0x0800) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("DPF");    checked: !!(denise.bplcon0 & 0x0400) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("COLOR");  checked: !!(denise.bplcon0 & 0x0200) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("GAUD");   checked: !!(denise.bplcon0 & 0x0100) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("UHRES");  checked: !!(denise.bplcon0 & 0x0080) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("SHRES");  checked: !!(denise.bplcon0 & 0x0040) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("BYPASS"); checked: !!(denise.bplcon0 & 0x0020) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("BPU3");   checked: !!(denise.bplcon0 & 0x0010) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("LPEN");   checked: !!(denise.bplcon0 & 0x0008) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("LACE");   checked: !!(denise.bplcon0 & 0x0004) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("ERSY");   checked: !!(denise.bplcon0 & 0x0002) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("ECSENA"); checked: !!(denise.bplcon0 & 0x0001) }

                HRule { }

                Si8 { indent: root.indent; lwidth: root.lw; l: qsTr("BPU"); value: denise.bpu }

                VSpacer { }
            }

            // BPLCON1 -- only PF2H (bits 7-4) and PF1H (bits
            // 3-0) are ever written; bits 15-8 are unused on
            // every chipset revision, shown as "-" rather
            // than omitted, same as BPLCON3's own unassigned
            // bits below.
            ColumnLayout {

                spacing: -1

                Si16 { l: qsTr("BPLCON1"); lwidth: root.lw; value: denise.bplcon1 }
                VSpacer { size: Style.smallSpacing }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("-");     checked: !!(denise.bplcon1 & 0x8000) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("-");     checked: !!(denise.bplcon1 & 0x4000) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("-");     checked: !!(denise.bplcon1 & 0x2000) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("-");     checked: !!(denise.bplcon1 & 0x1000) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("-");     checked: !!(denise.bplcon1 & 0x0800) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("-");     checked: !!(denise.bplcon1 & 0x0400) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("-");     checked: !!(denise.bplcon1 & 0x0200) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("-");     checked: !!(denise.bplcon1 & 0x0100) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("PF2H3"); checked: !!(denise.bplcon1 & 0x0080) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("PF2H2"); checked: !!(denise.bplcon1 & 0x0040) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("PF2H1"); checked: !!(denise.bplcon1 & 0x0020) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("PF2H0"); checked: !!(denise.bplcon1 & 0x0010) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("PF1H3"); checked: !!(denise.bplcon1 & 0x0008) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("PF1H2"); checked: !!(denise.bplcon1 & 0x0004) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("PF1H1"); checked: !!(denise.bplcon1 & 0x0002) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("PF1H0"); checked: !!(denise.bplcon1 & 0x0001) }

                HRule { }

                Si8 { indent: root.indent; lwidth: root.lw; l: qsTr("PF1H"); value: denise.p1h }
                Si8 { indent: root.indent; lwidth: root.lw; l: qsTr("PF2H"); value: denise.p2h }

                VSpacer { }
            }

            // BPLCON2 (AGA) -- all 16 bits are assigned; see
            // Denise.h's own "BPLCON2" accessor block for
            // pf2pri()/killehb()/rdram(), and the
            // SiAmDeniseController field comment for the
            // ZDBPSEL/ZDBPEN/ZDCTEN/SOGEN bits it doesn't
            // act on.
            ColumnLayout {

                spacing: -1

                Si16 { l: qsTr("BPLCON2"); lwidth: root.lw; value: denise.bplcon2 }
                VSpacer { size: Style.smallSpacing }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("-");       checked: !!(denise.bplcon2 & 0x8000) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("ZDBPSEL2"); checked: !!(denise.bplcon2 & 0x4000) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("ZDBPSEL1"); checked: !!(denise.bplcon2 & 0x2000) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("ZDBPSEL0"); checked: !!(denise.bplcon2 & 0x1000) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("ZDBPEN");  checked: !!(denise.bplcon2 & 0x0800) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("ZDCTEN");  checked: !!(denise.bplcon2 & 0x0400) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("KILLEHB"); checked: !!(denise.bplcon2 & 0x0200) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("RDRAM");   checked: !!(denise.bplcon2 & 0x0100) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("SOGEN");   checked: !!(denise.bplcon2 & 0x0080) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("PF2PRI");  checked: !!(denise.bplcon2 & 0x0040) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("PF2P2");   checked: !!(denise.bplcon2 & 0x0020) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("PF2P1");   checked: !!(denise.bplcon2 & 0x0010) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("PF2P0");   checked: !!(denise.bplcon2 & 0x0008) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("PF1P2");   checked: !!(denise.bplcon2 & 0x0004) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("PF1P1");   checked: !!(denise.bplcon2 & 0x0002) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("PF1P0");   checked: !!(denise.bplcon2 & 0x0001) }

                HRule { }

                Si8 { indent: root.indent; lwidth: root.lw; l: qsTr("ZDBPSEL"); value: denise.zdbpsel }

                VSpacer { }
            }

            // BPLCON3 (AGA) -- bits 8, 3 and 2 carry no
            // assigned function at all (see
            // SiAmDeniseController's own field comment),
            // shown as "-" for completeness.
            ColumnLayout {

                spacing: -1

                Si16 { l: qsTr("BPLCON3"); lwidth: root.lw; value: denise.bplcon3 }
                VSpacer { size: Style.smallSpacing }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("BANK2");    checked: !!(denise.bplcon3 & 0x8000) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("BANK1");    checked: !!(denise.bplcon3 & 0x4000) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("BANK0");    checked: !!(denise.bplcon3 & 0x2000) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("PF2OF2");   checked: !!(denise.bplcon3 & 0x1000) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("PF2OF1");   checked: !!(denise.bplcon3 & 0x0800) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("PF2OF0");   checked: !!(denise.bplcon3 & 0x0400) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("LOCT");     checked: !!(denise.bplcon3 & 0x0200) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("-");        checked: !!(denise.bplcon3 & 0x0100) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("SPRES1");   checked: !!(denise.bplcon3 & 0x0080) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("SPRES0");   checked: !!(denise.bplcon3 & 0x0040) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("BRDRBLNK"); checked: !!(denise.bplcon3 & 0x0020) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("BRDNTRAN"); checked: !!(denise.bplcon3 & 0x0010) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("-");        checked: !!(denise.bplcon3 & 0x0008) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("-");        checked: !!(denise.bplcon3 & 0x0004) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("BRDSPRT");  checked: !!(denise.bplcon3 & 0x0002) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("EXTBLKEN"); checked: !!(denise.bplcon3 & 0x0001) }

                HRule { }

                Si8 { indent: root.indent; lwidth: root.lw; l: qsTr("BANK");  value: denise.colorBank }
                Si8 { indent: root.indent; lwidth: root.lw; l: qsTr("PF2OF"); value: denise.pf2of }
                Si8 { indent: root.indent; lwidth: root.lw; l: qsTr("SPRES"); value: denise.spres }

                VSpacer { }
            }

            // BPLCON4 (AGA) -- BPLAM (bits 15-8), ESPRM
            // (bits 7-4), OSPRM (bits 3-0); all 16 bits
            // assigned, no gaps.
            ColumnLayout {

                spacing: -1

                Si16 { l: qsTr("BPLCON4"); lwidth: root.lw; value: denise.bplcon4 }
                VSpacer { size: Style.smallSpacing }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("BPLAM7"); checked: !!(denise.bplcon4 & 0x8000) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("BPLAM6"); checked: !!(denise.bplcon4 & 0x4000) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("BPLAM5"); checked: !!(denise.bplcon4 & 0x2000) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("BPLAM4"); checked: !!(denise.bplcon4 & 0x1000) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("BPLAM3"); checked: !!(denise.bplcon4 & 0x0800) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("BPLAM2"); checked: !!(denise.bplcon4 & 0x0400) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("BPLAM1"); checked: !!(denise.bplcon4 & 0x0200) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("BPLAM0"); checked: !!(denise.bplcon4 & 0x0100) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("ESPRM3"); checked: !!(denise.bplcon4 & 0x0080) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("ESPRM2"); checked: !!(denise.bplcon4 & 0x0040) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("ESPRM1"); checked: !!(denise.bplcon4 & 0x0020) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("ESPRM0"); checked: !!(denise.bplcon4 & 0x0010) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("OSPRM3"); checked: !!(denise.bplcon4 & 0x0008) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("OSPRM2"); checked: !!(denise.bplcon4 & 0x0004) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("OSPRM1"); checked: !!(denise.bplcon4 & 0x0002) }
                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("OSPRM0"); checked: !!(denise.bplcon4 & 0x0001) }

                HRule { }

                Si8 { indent: root.indent; lwidth: root.lw; l: qsTr("BPLAM"); value: denise.bplam }
                Si8 { indent: root.indent; lwidth: root.lw; l: qsTr("ESPRM"); value: denise.esprm }
                Si8 { indent: root.indent; lwidth: root.lw; l: qsTr("OSPRM"); value: denise.osprm }

                VSpacer { }
            }
        }

        VSpacer { }
    }

    //
    // Display Mode / Display Window -- stacked in one
    // column on the right rather than sitting beside
    // Control, so Control keeps the full remaining height
    // for its own BPLCON row instead of being squeezed to
    // whatever a third side-by-side box leaves over.
    //

    ColumnLayout {

        Layout.preferredWidth: 180
        Layout.fillHeight: true
        spacing: Style.mediumSpacing

        // Meta-information about the display mode the
        // BPLCON registers currently add up to -- not a
        // register dump (the Control box's job), just the
        // derived, human-readable summary a plain-language
        // reading of the register bits (see Denise.h's
        // "Derived values" block and SiAmDeniseController's
        // own resolutionText/modeText comment). A single
        // column of plain sentences rather than a label/
        // value grid, e.g.:
        //
        //   4 Bitplanes
        //   Lores
        //   Single Playfield
        //   Non-interlaced
        SiBox {

            title: qsTr("Display Mode")
            Layout.fillWidth: true
            spacing: Style.smallSpacing
            padding: Style.largeSpacing

            ColumnLayout {

                spacing: Style.smallSpacing

                SiLabel { size: Size.small; font.bold: true; text: denise.modeText }
                SiLabel { size: Size.small; font.bold: true; text: denise.resolutionText }
                SiLabel { size: Size.small; font.bold: true; text: denise.dbplf ? qsTr("Dual Playfield") : qsTr("Single Playfield") }
                SiLabel { size: Size.small; font.bold: true; text: denise.lace ? qsTr("Interlaced") : qsTr("Non-interlaced") }
            }
        }

        // DIWSTRT/DIWSTOP/DIWHIGH and the pixel coordinates
        // Denise derives from them. The Swift reference's
        // little start/stop diagram is dropped: it added
        // height this tab can't spare and the same
        // information is already right there as numbers.
        SiBox {

            title: qsTr("Display Window")
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Style.tinySpacing

            Si16 { lwidth: root.hlw; l: qsTr("DIWSTRT"); value: denise.diwstrt }
            Si16 { lwidth: root.hlw; l: qsTr("DIWSTOP"); value: denise.diwstop }
            Si16 { lwidth: root.hlw; l: qsTr("DIWHIGH"); value: denise.diwhigh }

            GridLayout {

                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Style.mediumSpacing
                columns: 3
                columnSpacing: Style.tinySpacing // Style.mediumSpacing
                rowSpacing: Style.tinySpacing

                Si16 { Layout.columnSpan: 3; Layout.alignment: Qt.AlignHCenter; value: denise.vstrt }

                Si16 { Layout.alignment: Qt.AlignHCenter; value: denise.hstrt }
                SiSymbol {

                    size: Size.huge
                    Layout.alignment: Qt.AlignHCenter
                    phosphor: "arrows-out-cardinal"
                    color: Palette.disabled
                    DebugRect {}
                }
                Si16 { Layout.alignment: Qt.AlignHCenter; value: denise.hstop }

                Si16 { Layout.columnSpan: 3; Layout.alignment: Qt.AlignHCenter; value: denise.vstop }
            }

            VSpacer { }
        }
    }
}
