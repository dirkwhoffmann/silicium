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

    component SiHex8: SiNumberViewControl {
        size: Size.small
        font.weight: 500
        controlWidth: 44
        bits: 8
        base: 16
        padded: true
    }

    // Blitter Data's Hold/Old/New registers -- fmt16 hex in the Swift
    // reference.
    component SiHex16: SiNumberViewControl {
        size: Size.small
        font.weight: 500
        controlWidth: 64
        bits: 16
        base: 16
        padded: true
    }

    // Mask/Shift/Fill Circuitry and Minterm Generator values -- fmt16b
    // binary in the Swift reference.
    component SiBin16: SiNumberViewControl {
        size: Size.small
        font.weight: 500
        controlWidth: 180
        bits: 16
        base: 2
        padded: true
    }

    RowLayout {

        anchors.fill: parent
        anchors.margins: Style.mediumSpacing
        spacing: Style.mediumSpacing

        //
        // Blitter Control + Blitter Data
        //

        ColumnLayout {

            Layout.preferredWidth: 260
            spacing: Style.mediumSpacing

            SiBox {

                title: qsTr("Blitter Control")
                Layout.fillWidth: true
                spacing: Style.mediumSpacing

                ColumnLayout {

                    Layout.alignment: Qt.AlignHCenter
                    spacing: Style.smallSpacing

                    RowLayout {
                        spacing: Style.tinySpacing
                        SiLabel { text: qsTr("BLTCON0"); Layout.preferredWidth: 65; horizontalAlignment: Text.AlignRight }
                        SiHex4 { value: blitter.bltcon0A }
                        SiHex4 { value: blitter.bltcon0B }
                        SiHex8 { value: blitter.bltcon0C }
                    }

                    RowLayout {
                        spacing: Style.tinySpacing
                        SiLabel { text: qsTr("BLTCON1"); Layout.preferredWidth: 65; horizontalAlignment: Text.AlignRight }
                        SiHex4 { value: blitter.bltcon1A }
                        SiHex4 { value: blitter.bltcon1B }
                        SiHex8 { value: blitter.bltcon1C }
                    }

                    RowLayout {

                        Layout.topMargin: Style.smallSpacing
                        spacing: Style.mediumSpacing

                        SiCheckBoxControl {
                            Layout.alignment: Qt.AlignBottom
                            readOnly: true
                            checked: blitter.bbusy
                            r: qsTr("BBUSY")
                        }

                        HSpacer { }

                        ColumnLayout {

                            spacing: Style.tinySpacing

                            SiCheckBoxControl { readOnly: true; checked: blitter.exclusiveFill; r: qsTr("Exclusive Fill") }
                            SiCheckBoxControl { readOnly: true; checked: blitter.inclusiveFill; r: qsTr("Inclusive Fill") }
                            SiCheckBoxControl { readOnly: true; checked: blitter.fillCarry; r: qsTr("Fill Carry") }
                            SiCheckBoxControl { readOnly: true; checked: blitter.descending; r: qsTr("Descending") }
                            SiCheckBoxControl { readOnly: true; checked: blitter.lineMode; r: qsTr("Line Mode") }
                        }
                    }
                }
            }

            SiBox {

                title: qsTr("Blitter Data")
                Layout.fillWidth: true
                spacing: Style.mediumSpacing

                GridLayout {

                    Layout.alignment: Qt.AlignHCenter
                    columns: 4
                    columnSpacing: Style.smallSpacing
                    rowSpacing: Style.tinySpacing

                    Item { Layout.preferredWidth: 90 }
                    SiLabel { text: qsTr("Hold"); horizontalAlignment: Text.AlignHCenter; Layout.preferredWidth: 64 }
                    SiLabel { text: qsTr("Old"); horizontalAlignment: Text.AlignHCenter; Layout.preferredWidth: 64 }
                    SiLabel { text: qsTr("New"); horizontalAlignment: Text.AlignHCenter; Layout.preferredWidth: 64 }

                    SiCheckBoxControl { readOnly: true; checked: blitter.useA; r: qsTr("Channel A") }
                    SiHex16 { value: blitter.aHold }
                    SiHex16 { value: blitter.aOld }
                    SiHex16 { value: blitter.aNew }

                    SiCheckBoxControl { readOnly: true; checked: blitter.useB; r: qsTr("Channel B") }
                    SiHex16 { value: blitter.bHold }
                    SiHex16 { value: blitter.bOld }
                    SiHex16 { value: blitter.bNew }

                    SiCheckBoxControl { readOnly: true; checked: blitter.useC; r: qsTr("Channel C") }
                    SiHex16 { value: blitter.cHold }
                    Item { }
                    Item { }

                    SiCheckBoxControl { readOnly: true; checked: blitter.useD; r: qsTr("Channel D") }
                    SiHex16 { value: blitter.dHold }
                    Item { }
                    SiCheckBoxControl { readOnly: true; checked: blitter.bzero; r: qsTr("BZERO") }
                }
            }

            Item { Layout.fillHeight: true }
        }

        //
        // Mask, Shift, and Fill Circuitries
        //

        SiBox {

            title: qsTr("Mask, Shift, and Fill Circuitries")
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Style.smallSpacing

            ColumnLayout {

                Layout.alignment: Qt.AlignHCenter
                spacing: Style.tinySpacing

                SiBin16 { l: qsTr("Unmasked"); lwidth: 90; value: blitter.unmasked }

                RowLayout {
                    spacing: Style.tinySpacing
                    SiCheckBoxControl { readOnly: true; checked: blitter.firstWord; l: qsTr("First word"); lwidth: 90 }
                    SiBin16 { value: blitter.afwm }
                }

                RowLayout {
                    spacing: Style.tinySpacing
                    SiCheckBoxControl { readOnly: true; checked: blitter.lastWord; l: qsTr("Last word"); lwidth: 90 }
                    SiBin16 { value: blitter.alwm }
                }

                SiBin16 { l: qsTr("Masked"); lwidth: 90; value: blitter.masked }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; Layout.topMargin: Style.smallSpacing; Layout.bottomMargin: Style.smallSpacing; color: Palette.surfaceBorder }

                SiBin16 { l: qsTr("Barrel A In"); lwidth: 90; value: blitter.barrelAIn }

                RowLayout {
                    spacing: Style.tinySpacing
                    SiLabel { text: qsTr("<<"); Layout.preferredWidth: 90; horizontalAlignment: Text.AlignRight }
                    SiHex4 { value: blitter.barrelAShift }
                    SiLabel { text: "=" }
                    SiBin16 { value: blitter.barrelAOut }
                }

                SiBin16 { l: qsTr("Barrel B In"); lwidth: 90; value: blitter.barrelBIn }

                RowLayout {
                    spacing: Style.tinySpacing
                    SiLabel { text: qsTr("<<"); Layout.preferredWidth: 90; horizontalAlignment: Text.AlignRight }
                    SiHex4 { value: blitter.barrelBShift }
                    SiLabel { text: "=" }
                    SiBin16 { value: blitter.barrelBOut }
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; Layout.topMargin: Style.smallSpacing; Layout.bottomMargin: Style.smallSpacing; color: Palette.surfaceBorder }

                SiBin16 { l: qsTr("Fill in"); lwidth: 90; value: blitter.fillIn }
                SiBin16 { l: qsTr("Fill out"); lwidth: 90; value: blitter.fillOut }
            }
        }

        //
        // Minterm Generator
        //

        SiBox {

            title: qsTr("Minterm Generator")
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Style.smallSpacing

            ColumnLayout {

                Layout.alignment: Qt.AlignHCenter
                spacing: Style.tinySpacing

                SiBin16 { l: qsTr("A"); lwidth: 40; value: blitter.mintermA }
                SiBin16 { l: qsTr("B"); lwidth: 40; value: blitter.mintermB }
                SiBin16 { l: qsTr("C"); lwidth: 40; value: blitter.mintermC }

                Repeater {

                    model: 8

                    RowLayout {

                        required property int index
                        spacing: Style.tinySpacing

                        SiCheckBoxControl {
                            readOnly: true
                            checked: blitter.lfEnabled(index)
                            l: blitter.lfLabel(index)
                            lwidth: 40
                        }

                        SiBin16 { value: blitter.lfValue(index) }
                    }
                }

                SiBin16 { l: qsTr("Out"); lwidth: 40; value: blitter.lfOut }
            }
        }
    }
}
