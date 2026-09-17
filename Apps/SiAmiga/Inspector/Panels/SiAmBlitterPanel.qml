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

// Port of vAmiga's own GUI/Inspector/BlitterPanel.swift -- there is no C64
// counterpart to port from (the Blitter is Amiga-only). Its own top-level
// window (see SiAmInspectorWindow.qml).
//
// One deliberate departure from every other ported panel here: number
// formatting does NOT follow controller.inspectorController's shared hex/
// decimal toggle. The Swift reference doesn't have (or want) a shared
// toggle either -- every field has its own fixed formatter (fmt4/fmt8 for
// BLTCON0/1's sub-fields and the barrel shifters' shift amounts, fmt16 hex
// for the Blitter Data box's Hold/Old/New registers, fmt16b *binary* for
// everything in the Mask/Shift/Fill Circuitries and Minterm Generator
// boxes) -- because for a bit-logic circuit view, the actual bit pattern
// matters more than whatever base the user happens to have the rest of
// the Inspector set to. This file reproduces that fixed-format-per-field
// scheme exactly rather than wiring these to root.numBase like
// SiAmCIAPanel/SiAmCopperPanel do.
SiAmInspectorWindow {

    id: root

    title: qsTr("Blitter Inspector")
    currentController: controller.blitterController

    readonly property var blitter: controller.blitterController

    // Shared width for every SiBox (see SiAmCIAPanel)
    readonly property real columnWidth: Math.max(260,
        (scrollView.availableWidth - Style.largeSpacing * 2) / 3)

    // Shared label width for every field in this panel
    readonly property int labelWidth: 64

    // BLTCON0/1's ash/bsh + sub-field bytes, and the barrel shifters' shift
    // amounts -- fmt4/fmt8 in the Swift reference (fixed hex, not tied to
    // the shared format setting -- see the class comment).
    component SiHex4: SiNumberViewControl {
        size: Size.small
        font.weight: 500
        controlWidth: 32
        bits: 4
        base: 16
        padded: true
    }

    // SiByteViewControl's default width (32) is a bit tight for this
    // panel's sub-byte fields.
    component SiHex8: SiByteViewControl {
        controlWidth: 44
    }

    // Blitter Data's Hold/Old/New registers -- fmt16 hex in the Swift
    // reference. SiWordViewControl's own default width fits, so it's used
    // directly (no local alias) everywhere below.

    // Mask/Shift/Fill Circuitry and Minterm Generator values -- fmt16b
    // binary in the Swift reference.
    component SiBin16: SiNumberViewControl {

        size: Size.small
        font.weight: 500
        controlWidth: 140
        bits: 16
        base: 2
        padded: true
    }

    ScrollView {

        id: scrollView

        anchors.fill: parent
        anchors.margins: Style.mediumSpacing

        clip: true
        contentWidth: content.width
        contentHeight: content.height

        // A single 3-column grid holds all three boxes (see SiAmCIAPanel).
        // GridLayout has no per-column stretch factor, so pin every cell's
        // width to root.columnWidth instead, so all three columns stay
        // equal and track window resizes together.
        //
        // A Flickable's content item always sizes to its own implicitWidth/
        // implicitHeight, so a GridLayout inside a ScrollView never grows
        // past what its children need, even when the window is bigger than
        // that. To have the grid (and every Layout.fillWidth/fillHeight cell
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
            // Blitter Control + Blitter Data
            //

            ColumnLayout {

                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: root.columnWidth
                spacing: Style.mediumSpacing

                SiBox {

                    title: qsTr("Blitter Control")
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: Style.mediumSpacing

                    ColumnLayout {

                        Layout.alignment: Qt.AlignHCenter
                        spacing: Style.tinySpacing

                        SiHex4 {

                            lwidth: root.labelWidth
                            l: qsTr("BLTCON0:")
                            value: blitter.bltcon0A

                            SiHex4 { value: blitter.bltcon0B }
                            SiHex8 { value: blitter.bltcon0C }
                        }

                        SiHex4 {

                            lwidth: root.labelWidth
                            l: qsTr("BLTCON1:")
                            value: blitter.bltcon1A

                            SiHex4 { value: blitter.bltcon1B }
                            SiHex8 { value: blitter.bltcon1C }
                        }

                        SiCheckBoxControl { size: Size.small; lwidth: root.labelWidth; readOnly: true; checked: blitter.exclusiveFill; r: qsTr("Exclusive Fill") }
                        SiCheckBoxControl { size: Size.small; lwidth: root.labelWidth; readOnly: true; checked: blitter.inclusiveFill; r: qsTr("Inclusive Fill") }
                        SiCheckBoxControl { size: Size.small; lwidth: root.labelWidth; readOnly: true; checked: blitter.fillCarry; r: qsTr("Fill Carry") }
                        SiCheckBoxControl { size: Size.small; lwidth: root.labelWidth; readOnly: true; checked: blitter.descending; r: qsTr("Descending") }
                        SiCheckBoxControl { size: Size.small; lwidth: root.labelWidth; readOnly: true; checked: blitter.lineMode; r: qsTr("Line Mode") }

                        SiCheckBoxControl {

                            size: Size.small
                            lwidth: root.labelWidth
                            l: qsTr("BBUSY:")
                            readOnly: true
                            checked: blitter.bbusy
                        }
                    }
                }

                SiBox {

                    title: qsTr("Blitter Data")
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: Style.mediumSpacing

                    GridLayout {

                        Layout.alignment: Qt.AlignHCenter
                        columns: 4
                        columnSpacing: Style.smallSpacing
                        rowSpacing: Style.tinySpacing

                        Item { Layout.preferredWidth: 70 }
                        SiLabel { size: Size.small; text: qsTr("Hold"); horizontalAlignment: Text.AlignHCenter; Layout.preferredWidth: 52 }
                        SiLabel { size: Size.small; text: qsTr("Old"); horizontalAlignment: Text.AlignHCenter; Layout.preferredWidth: 52 }
                        SiLabel { size: Size.small; text: qsTr("New"); horizontalAlignment: Text.AlignHCenter; Layout.preferredWidth: 52 }

                        SiCheckBoxControl { size: Size.small; readOnly: true; checked: blitter.useA; l: qsTr("Channel A") }
                        SiWordViewControl { value: blitter.aHold }
                        SiWordViewControl { value: blitter.aOld }
                        SiWordViewControl { value: blitter.aNew }

                        SiCheckBoxControl { size: Size.small; readOnly: true; checked: blitter.useB; l: qsTr("Channel B") }
                        SiWordViewControl { value: blitter.bHold }
                        SiWordViewControl { value: blitter.bOld }
                        SiWordViewControl { value: blitter.bNew }

                        SiCheckBoxControl { size: Size.small; readOnly: true; checked: blitter.useC; l: qsTr("Channel C") }
                        SiWordViewControl { value: blitter.cHold }
                        Item { }
                        Item { }

                        SiCheckBoxControl { size: Size.small; readOnly: true; checked: blitter.useD; l: qsTr("Channel D") }
                        SiWordViewControl { value: blitter.dHold }
                        Item { }
                        SiCheckBoxControl { size: Size.small; readOnly: true; checked: blitter.bzero; r: qsTr("BZERO") }
                    }
                }
            }

            //
            // Mask, Shift, and Fill Circuitries
            //

            ColumnLayout {

                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: root.columnWidth
                spacing: Style.mediumSpacing

                SiBox {

                    title: qsTr("Mask")
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: Style.smallSpacing

                    ColumnLayout {

                        Layout.alignment: Qt.AlignHCenter
                        spacing: Style.tinySpacing

                        SiBin16 { l: qsTr("Unmasked:"); lwidth: root.labelWidth; value: blitter.unmasked }

                        SiBin16 {

                            l: qsTr("First word:"); lwidth: root.labelWidth; value: blitter.afwm
                            SiCheckBoxControl { size: Size.small; readOnly: true; checked: blitter.firstWord }
                        }

                        SiBin16 {

                            l: qsTr("Last word:"); lwidth: root.labelWidth; value: blitter.alwm
                            SiCheckBoxControl { size: Size.small; readOnly: true; checked: blitter.lastWord }
                        }

                        SiBin16 { l: qsTr("Masked:"); lwidth: root.labelWidth; value: blitter.masked }
                    }
                }

                SiBox {

                    title: qsTr("Shift:")
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: Style.smallSpacing

                    ColumnLayout {

                        Layout.alignment: Qt.AlignHCenter
                        spacing: Style.tinySpacing

                        SiBin16 {
                            l: qsTr("Barrel A In:"); lwidth: root.labelWidth; value: blitter.barrelAIn
                            SiCheckBoxControl { size: Size.small; hide: true }
                        }

                        SiHex4 {

                            lwidth: root.labelWidth
                            l: qsTr("<<")
                            value: blitter.barrelAShift }

                        SiBin16 {

                            lwidth: root.labelWidth
                            l: "="
                            value: blitter.barrelAOut
                        }

                        SiBin16 { l: qsTr("Barrel B In:"); lwidth: root.labelWidth; value: blitter.barrelBIn
                        }

                        SiHex4 {

                            lwidth: root.labelWidth
                            l: qsTr("<<")
                            value: blitter.barrelBShift }

                        SiBin16 {

                            lwidth: root.labelWidth
                            l: "="
                            value: blitter.barrelBOut
                        }
                    }
                }

                SiBox {

                    title: qsTr("Fill")
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: Style.smallSpacing

                    ColumnLayout {

                        Layout.alignment: Qt.AlignHCenter
                        spacing: Style.tinySpacing

                        SiBin16 {
                            l: qsTr("Fill in:"); lwidth: root.labelWidth; value: blitter.fillIn
                            SiCheckBoxControl { size: Size.small; hide: true }
                        }
                        SiBin16 {
                            l: qsTr("Fill out:"); lwidth: root.labelWidth; value: blitter.fillOut
                        }
                    }
                }
            }

            //
            // Minterm Generator
            //

            SiBox {

                title: qsTr("Minterm Generator")
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: root.columnWidth
                spacing: Style.smallSpacing

                ColumnLayout {

                    Layout.alignment: Qt.AlignHCenter
                    spacing: Style.tinySpacing

                    SiBin16 { l: qsTr("A:"); lwidth: 40; value: blitter.mintermA }
                    SiBin16 { l: qsTr("B:"); lwidth: 40; value: blitter.mintermB }
                    SiBin16 { l: qsTr("C:"); lwidth: 40; value: blitter.mintermC }

                    Repeater {

                        model: 8

                        SiBin16 {

                            required property int index
                            lwidth: 40
                            l: blitter.lfLabel(index) + ":"
                            value: blitter.lfValue(index)

                            SiCheckBoxControl {

                                size: Size.small
                                readOnly: true
                                checked: blitter.lfEnabled(index)
                            }
                        }
                    }

                    SiBin16 { l: qsTr("Out:"); lwidth: 40; value: blitter.lfOut }
                }
            }
        }
    }
}
