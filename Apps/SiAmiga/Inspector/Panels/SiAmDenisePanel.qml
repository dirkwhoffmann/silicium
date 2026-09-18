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

// Port of vAmiga's own GUI/Inspector/DenisePanel.swift + SpriteTableView.swift.
// Its own top-level window (see SiAmInspectorWindow.qml).
SiAmInspectorWindow {

    id: root

    title: qsTr("Denise Inspector")
    currentController: controller.deniseController

    // Deliberately no width/height override here -- every inspector shares
    // SiAmInspectorWindow.qml's 880x440 default, so the Registers page
    // (Control/Display Window/Data, below) is laid out to fit inside that
    // rather than growing the window: each BPLCONx group's bit list runs in
    // 2 columns instead of 1 (13 rows -> 7 for BPLCON0, the tallest), and
    // every field on this tab uses Size.tiny.

    readonly property var denise: controller.deniseController
    readonly property var ic: controller.inspectorController
    readonly property int numBase: ic.hex ? 16 : 10
    readonly property bool numPadded: ic.padded
    readonly property int lw: 64
    readonly property int hlw: 62
    readonly property int indent: 0

    // SiWordViewControl/SiByteViewControl (Apps/Shared/QML/Compounds) hold
    // the structural bits; this panel only adds the width override and the
    // hex/decimal toggle binding.

    // Size.tiny rather than the more common Size.small, and a narrower
    // controlWidth than SiWordViewControl's own 48px default -- the
    // Registers page's Control box packs 5 BPLCONx groups (42 fields
    // total) into a 2-column grid, so every bit of horizontal/vertical
    // slack here counts. root.lw sizes the indented per-bit labels
    // ("HIRES", "BPU", ...); root.hlw is wider, for the un-indented
    // register-name header row of each group ("BPLCON0", "DIWSTRT", ...),
    // which needs more characters than fit in root.lw.
    component Si1: SiBitViewControl {

        size: Size.tiny
    }

    component Si16: SiWordViewControl {

        size: Size.small
        controlWidth: 44
        base: root.numBase
        padded: root.numPadded
    }

    // One color-register swatch -- a plain circle, matching the round
    // NSColorWell style DenisePanel.swift's colorReg wells use.
    component Swatch: Rectangle {

        property color value: "black"

        implicitWidth: 28
        implicitHeight: 28
        radius: width / 2
        color: value
        border.width: 1
        border.color: Palette.controlBorder
    }

    // Which page the stack shows: 0 = Registers, 1 = Colors, 2 = Sprites --
    // same Program/Trace/Debug tab-bar idiom as SiAmCPUPanel.qml, adopted
    // here so the growing set of AGA-only registers has room of its own
    // instead of squeezing the Sprites box sideways, and so the Colors tab
    // (four 32-swatch boxes, one per AGA color bank) has the whole window
    // to itself rather than sharing the Registers page with Display window.
    property int page: 0

    Item {

        anchors.fill: parent
        anchors.margins: Style.mediumSpacing

        SiBox {

            id: stackBox
            anchors.fill: parent
            anchors.topMargin: tabControl.height / 2
            spacing: Style.mediumSpacing

            VSpacer { size: Style.tinySpacing }

            StackLayout {

                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: root.page

                //
                // Registers
                //

                RowLayout {

                    spacing: Style.mediumSpacing

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
                            }

                            // BPLCON1 -- only PF2H (bits 7-4) and PF1H (bits
                            // 3-0) are ever written; bits 15-8 are unused on
                            // every chipset revision, shown as "-" rather
                            // than omitted, same as BPLCON3's own unassigned
                            // bits below.
                            ColumnLayout {

                                spacing: -1

                                Si16 { l: qsTr("BPLCON1"); lwidth: root.lw; value: denise.bplcon1 }
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
                            }

                            // BPLCON3 (AGA) -- bits 8, 3 and 2 carry no
                            // assigned function at all (see
                            // SiAmDeniseController's own field comment),
                            // shown as "-" for completeness.
                            ColumnLayout {

                                spacing: -1

                                Si16 { l: qsTr("BPLCON3"); lwidth: root.lw; value: denise.bplcon3 }
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
                            }

                            // BPLCON4 (AGA) -- BPLAM (bits 15-8), ESPRM
                            // (bits 7-4), OSPRM (bits 3-0); all 16 bits
                            // assigned, no gaps.
                            ColumnLayout {

                                spacing: -1

                                Si16 { l: qsTr("BPLCON4"); lwidth: root.lw; value: denise.bplcon4 }
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
                            }
                        }

                        VSpacer { }
                    }

                    //
                    // Display Window / Data -- stacked in one column on the
                    // right rather than sitting beside Control, so Control
                    // keeps the full remaining height for its own 2-column
                    // BPLCON grid instead of being squeezed to whatever a
                    // third side-by-side box leaves over.
                    //

                    ColumnLayout {

                        Layout.preferredWidth: 180
                        Layout.fillHeight: true
                        spacing: Style.mediumSpacing

                        // DIWSTRT/DIWSTOP/DIWHIGH and the pixel coordinates
                        // Denise derives from them. The Swift reference's
                        // little start/stop diagram is dropped: it added
                        // height this tab can't spare and the same
                        // information is already right there as numbers.
                        SiBox {

                            title: qsTr("Display Window")
                            Layout.fillWidth: true
                            spacing: Style.tinySpacing

                            GridLayout {

                                columns: 2
                                columnSpacing: Style.mediumSpacing
                                rowSpacing: 0

                                Si16 { lwidth: root.hlw; l: qsTr("DIWSTRT"); value: denise.diwstrt }
                                Si16 { lwidth: root.hlw; l: qsTr("DIWSTOP"); value: denise.diwstop }
                                Si16 { lwidth: root.hlw; l: qsTr("DIWHIGH"); value: denise.diwhigh }
                                Si16 { lwidth: root.hlw; l: qsTr("HSTRT"); value: denise.hstrt }
                                Si16 { lwidth: root.hlw; l: qsTr("VSTRT"); value: denise.vstrt }
                                Si16 { lwidth: root.hlw; l: qsTr("HSTOP"); value: denise.hstop }
                                Si16 { lwidth: root.hlw; l: qsTr("VSTOP"); value: denise.vstop }
                            }
                        }

                        // BPLDAT0..7, the latched bitplane data words (all
                        // 8 exist on every model; see SiAmDeniseController's
                        // bplData(n) comment).
                        SiBox {

                            title: qsTr("Data")
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: Style.tinySpacing

                            GridLayout {

                                columns: 2
                                columnSpacing: Style.mediumSpacing
                                rowSpacing: 0

                                Repeater {
                                    model: 8
                                    Si16 { required property int index; lwidth: root.hlw; l: qsTr("BPLDAT%1").arg(index); value: denise.bplData(index) }
                                }
                            }

                            VSpacer { }
                        }
                    }
                }

                //
                // Colors -- one box per AGA color bank (4 banks of 32
                // registers each; see SiAmDeniseController's own colorAt(n)
                // comment), same swatch-grid style as the single Colors box
                // this replaced, now with its own tab instead of sharing
                // the Registers page with Display window.
                //

                GridLayout {

                    columns: 2
                    columnSpacing: Style.mediumSpacing
                    rowSpacing: Style.mediumSpacing

                    Repeater {

                        model: 4

                        SiBox {

                            id: bankBox
                            required property int index

                            title: qsTr("Bank %1").arg(index)
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            GridLayout {

                                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                                columns: 8
                                columnSpacing: Style.smallSpacing
                                rowSpacing: Style.smallSpacing

                                Repeater {
                                    model: 32
                                    Swatch { required property int index; value: denise.colorAt(bankBox.index * 32 + index) }
                                }
                            }
                        }
                    }
                }

                //
                // Sprites
                //

                RowLayout {

                    spacing: Style.mediumSpacing

                    //
                    // Registers -- collision detection (CLXDAT/CLXCON/
                    // CLXCON2) lives here rather than on the Registers
                    // tab's Control box: a collision is inherently a
                    // sprite/playfield overlap, so it's sprite state, not
                    // bitplane state.
                    //

                    SiBox {

                        title: qsTr("Registers")
                        Layout.preferredWidth: 140
                        Layout.fillHeight: true
                        spacing: Style.tinySpacing

                        Si16 { l: qsTr("CLXDAT"); lwidth: 65; value: denise.clxdat }
                        Si16 { l: qsTr("CLXCON"); lwidth: 65; value: denise.clxcon }
                        Si16 { l: qsTr("CLXCON2"); lwidth: 65; value: denise.clxcon2 }

                        VSpacer { }
                    }

                    SiBox {

                        title: qsTr("Sprites")
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: Style.tinySpacing

                        RowLayout {

                            Layout.fillWidth: true
                            spacing: Style.tinySpacing

                            Repeater {
                                model: 8
                                SiCheckBoxControl { required property int index; readOnly: true; checked: denise.spriteArmed(index) }
                            }
                        }

                        RowLayout {

                            Layout.fillWidth: true
                            spacing: Style.tinySpacing

                            Repeater {
                                model: 8
                                Button {
                                    required property int index
                                    text: index
                                    checkable: true
                                    checked: denise.selectedSprite === index
                                    onClicked: denise.selectedSprite = index
                                }
                            }
                        }

                        Rectangle {

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.topMargin: Style.tinySpacing
                            color: "black"
                            border.width: 1
                            border.color: Palette.surfaceBorder
                            radius: Style.radius
                            clip: true

                            SiAmSpriteView {
                                anchors.fill: parent
                                anchors.margins: Style.radius
                                spriteNr: denise.selectedSprite
                            }
                        }

                        RowLayout {

                            Layout.topMargin: Style.tinySpacing
                            spacing: Style.smallSpacing

                            SiLabel { text: qsTr("VPOS") }
                            Si16 { controlWidth: 48; value: denise.sprVStart }
                            SiLabel { text: "-" }
                            Si16 { controlWidth: 48; value: denise.sprVStop }

                            SiLabel { text: qsTr("HPOS") }
                            Si16 { controlWidth: 48; value: denise.sprHStart }

                            HSpacer { }

                            SiLabel { text: qsTr("AT") }
                            SiCheckBoxControl { readOnly: true; checked: denise.sprAttach }
                        }
                    }
                }
            }
        }

        SiSegmentedControl {

            id: tabControl
            anchors.horizontalCenter: stackBox.horizontalCenter
            anchors.verticalCenter: stackBox.top

            model: [qsTr("Registers"), qsTr("Colors"), qsTr("Sprites")]
            segmentWidth: 90
            currentIndex: root.page
            onActivated: (index) => root.page = index
        }
    }
}
