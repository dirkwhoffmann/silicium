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
import Sulfur

SiC64InspectorWindow {

    id: root

    title: qsTr("VICII Inspector")
    currentController: controller.vicController

    readonly property var vic: controller.vicController
    readonly property int numBase: (controller.format === 0 || controller.format === 1) ? 16 : 10
    readonly property bool numPadded: controller.format === 1 || controller.format === 3
    readonly property int boxSpacing: 6 // Style.mediumSpacing

    // Shared width for every SiBox
    readonly property real columnWidth: Math.max(260,
        (scrollView.availableWidth - Style.largeSpacing * 2) / 3)

    component SuLabeledBinaryView: SuLabeledNumberView {

        size: Size.small
        font.bold: true
        controlWidth: 66
        bits: 8
        base: 2
        padded: true
    }

    component SuLabeledByteView: SuLabeledNumberView {

        size: Size.small
        font.weight: 500
        controlWidth: 32
        bits: 8
        base: root.numBase
        padded: root.numPadded
    }

    component SiLabeledExtByteView: SuLabeledNumberView {

        size: Size.small
        font.weight: 500
        controlWidth: 39
        bits: 12
        base: root.numBase
        padded: root.numPadded
    }

    component SuLabeledWordView: SuLabeledNumberView {

        size: Size.small
        font.weight: 500
        controlWidth: 48
        bits: 16
        base: root.numBase
        padded: root.numPadded
    }

    // One per-sprite "cut" checkbox in the Debugging box's sprite mask.
    component SpriteMaskCheck: SuLabeledCheckBox {

        required property int spriteNr

        size: Size.small
        checked: (vic.cutSpriteMask & (1 << spriteNr)) !== 0
        onClicked: vic.toggleCutSprite(spriteNr)
        r: spriteNr
    }

    //
    // Main
    //

    ColumnLayout {

        anchors.fill: parent
        anchors.margins: Style.mediumSpacing
        spacing: Style.mediumSpacing

        //
        // Content area
        //

        ScrollView {

            id: scrollView

            Layout.fillWidth: true
            Layout.fillHeight: true

            clip: true
            contentWidth: content.implicitWidth

            //
            // Grid
            //

            GridLayout {

                id: content

                columns: 3
                columnSpacing: Style.largeSpacing
                rowSpacing: Style.largeSpacing

                //
                // Counters
                //

                SiBox {

                    id: countersBox
                    title: qsTr("Counters")
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: root.columnWidth
                    spacing: root.boxSpacing

                    GridLayout {

                        Layout.alignment: Qt.AlignHCenter
                        columns: 2
                        columnSpacing: Style.smallSpacing
                        rowSpacing: root.boxSpacing

                        SiLabeledExtByteView { size: Size.small; lwidth: 65; l: qsTr("Y Counter:"); value: vic.yCounter }
                        SiLabeledExtByteView { size: Size.small; lwidth: 65; l: qsTr("X Counter:"); value: vic.xCounter }

                        SiLabeledExtByteView { size: Size.small; lwidth: 65; l: qsTr("VC:"); value: vic.vc }
                        SiLabeledExtByteView { size: Size.small; lwidth: 65; l: qsTr("VC Base:"); value: vic.vcBase }

                        SuLabeledByteView { size: Size.small; lwidth: 65; l: qsTr("RC:"); bits: 4; value: vic.rc }
                        SuLabeledByteView { size: Size.small; lwidth: 65; l: qsTr("VMLI:"); bits: 8; value: vic.vmli }

                        SuLabeledByteView { size: Size.small; lwidth: 65; l: qsTr("Raster IRQ:"); bits: 8; value: vic.irqRasterline }
                    }

                    VSpacer { }
                }

                //
                // Memory
                //

                SiBox {

                    id: memoryBox
                    title: qsTr("Memory")
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: root.columnWidth
                    spacing: root.boxSpacing

                    RowLayout {

                        SuLabeledByteView { size: Size.small; lwidth: 100; l: qsTr("Memory select"); value: vic.memSelect }
                        HSpacer { }
                        SuLabeledCheckBox { size: Size.small; checked: vic.ultimax; r: qsTr("Ultimax") }
                    }

                    // Bank / screen / char memory are shown, not edited
                    // here -- there's no live setter for them yet, so
                    // these combo boxes are disabled, single-option
                    // read-outs rather than functional selectors.
                    SuLabeledComboBox {

                        size: Size.small
                        lwidth: 100
                        l: qsTr("Memory bank")
                        readOnly: true
                        model: [vic.memoryBankAddr]
                        currentIndex: 0
                    }

                    SuLabeledComboBox {

                        size: Size.small
                        lwidth: 100
                        l: qsTr("Screen memory")
                        readOnly: true
                        model: [vic.screenMemoryAddr]
                        currentIndex: 0
                    }

                    SuLabeledComboBox {

                        size: Size.small
                        lwidth: 100
                        l: qsTr("Char memory")
                        readOnly: true
                        model: [vic.charMemoryAddr]
                        currentIndex: 0
                    }

                    VSpacer { }
                }

                //
                // Debugging
                //

                SiBox {

                    id: debugBox
                    title: qsTr("Debugging")
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: root.columnWidth
                    spacing: root.boxSpacing

                    SuLabeledCheckBox {

                        size: Size.small
                        checked: vic.cutEnable
                        onClicked: vic.cutEnable = checked
                        r: qsTr("Cut out layers")
                    }

                    RowLayout {

                        Layout.fillHeight: true
                        spacing: root.boxSpacing

                        SuSlider {

                            orientation: Qt.Vertical
                            Layout.preferredHeight: cutGrid.height
                            enabled: vic.cutEnable
                            from: 0; to: 255
                            boundValue: vic.cutOpacity
                            onMoved: vic.cutOpacity = value
                        }

                        ColumnLayout {

                            spacing: Style.tinySpacing
                            enabled: vic.cutEnable

                            GridLayout {

                                id: cutGrid
                                columns: 2
                                columnSpacing: Style.mediumSpacing
                                rowSpacing: Style.tinySpacing

                                SuLabeledCheckBox {

                                    size: Size.small
                                    checked: vic.cutBorder
                                    onClicked: vic.cutBorder = checked
                                    r: qsTr("Border")
                                }

                                SuLabeledCheckBox {

                                    size: Size.small
                                    checked: vic.cutSprites
                                    onClicked: vic.cutSprites = checked
                                    r: qsTr("Sprites")
                                }

                                SuLabeledCheckBox {

                                    size: Size.small
                                    checked: vic.cutForeground
                                    onClicked: vic.cutForeground = checked
                                    r: qsTr("Foreground")
                                }

                                RowLayout {

                                    Layout.leftMargin: 18
                                    spacing: Style.tinySpacing
                                    enabled: vic.cutSprites

                                    Repeater {

                                        model: 4
                                        delegate: SpriteMaskCheck {
                                            required property int index
                                            spriteNr: index
                                        }
                                    }
                                }

                                SuLabeledCheckBox {

                                    size: Size.small
                                    checked: vic.cutBackground
                                    onClicked: vic.cutBackground = checked
                                    r: qsTr("Background")
                                }

                                RowLayout {

                                    Layout.leftMargin: 18
                                    spacing: Style.tinySpacing
                                    enabled: vic.cutSprites

                                    Repeater {

                                        model: 4
                                        delegate: SpriteMaskCheck {
                                            required property int index
                                            spriteNr: index + 4
                                        }
                                    }
                                }
                            }
                        }
                    }

                    VSpacer { }
                }

                //
                // Display
                //

                SiBox {

                    id: displayBox
                    title: qsTr("Display")
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: root.columnWidth
                    spacing: root.boxSpacing

                    RowLayout {
                        SuLabeledByteView { size: Size.small; lwidth: 50; l: qsTr("Control:"); value: vic.ctrl1 }
                        SuLabeledByteView { size: Size.small; value: vic.ctrl2 }
                        HSpacer { }
                        SuLabeledByteView { size: Size.small; controlWidth: 24; lwidth: 20; l: qsTr("dX:"); bits: 4; value: vic.dx }
                        SuLabeledByteView { size: Size.small; controlWidth: 24; lwidth: 20; l: qsTr("dY:"); bits: 4; value: vic.dy }
                    }

                    GridLayout {

                        columns: 4
                        columnSpacing: Style.mediumSpacing
                        rowSpacing: Style.mediumSpacing

                        Item { Layout.preferredWidth: 50 }

                        SuLabeledCheckBox {
                            size: Size.small
                            checked: vic.denBit
                            r: qsTr("DEN")
                        }

                        SuLabeledCheckBox {
                            size: Size.small
                            checked: vic.badLine
                            r: qsTr("Bad")
                        }

                        SuLabeledCheckBox {
                            size: Size.small
                            checked: vic.displayState
                            r: qsTr("Disp")
                        }

                        Item { Layout.preferredWidth: 50 }

                        SuLabeledCheckBox {
                            size: Size.small
                            checked: vic.vblank
                            r: qsTr("VBL")
                        }

                        SuLabeledCheckBox {
                            size: Size.small
                            checked: vic.hFlop
                            r: qsTr("HFlop")
                        }

                        SuLabeledCheckBox {
                            size: Size.small
                            checked: vic.vFlop
                            r: qsTr("VFlop")
                        }
                    }

                    SuLabeledComboBox {
                        size: Size.small
                        lwidth: 50
                        l: qsTr("Canvas:")
                        readOnly: true
                        model: [vic.screenGeometry]
                        currentIndex: 0
                    }

                    SuLabeledComboBox {
                        size: Size.small
                        lwidth: 50
                        l: qsTr("Mode:")
                        readOnly: true
                        model: [vic.displayMode]
                        currentIndex: 0
                    }

                    RowLayout {

                        HSpacer { size: 50 }
                        spacing: Style.smallSpacing
                        SuColorWell { readOnly: true; value: vic.borderColor }
                        SuColorWell { readOnly: true; value: vic.bgColor0 }
                        SuColorWell { readOnly: true; value: vic.bgColor1 }
                        SuColorWell { readOnly: true; value: vic.bgColor2 }
                        SuColorWell { readOnly: true; value: vic.bgColor3 }
                        Item { Layout.fillWidth: true }
                    }

                    VSpacer { }
                }

                //
                // Interrupts and Lightpen
                //

                SiBox {

                    id: interruptsBox
                    title: qsTr("Interrupts and Lightpen")
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: root.columnWidth
                    spacing: root.boxSpacing

                    GridLayout {

                        columns: 2
                        columnSpacing: Style.mediumSpacing
                        rowSpacing: root.boxSpacing
                        Layout.alignment: Qt.AlignHCenter

                        SuLabeledByteView { size: Size.small; l: qsTr("Enable"); value: vic.imr; Layout.alignment: Qt.AlignRight }
                        SuLabeledByteView { size: Size.small; r: qsTr("Request"); value: vic.irr }

                        SuLabeledCheckBox { size: Size.small; checked: vic.imrLP; l: qsTr("Lightpen"); Layout.alignment: Qt.AlignRight }
                        SuLabeledCheckBox { size: Size.small; checked: vic.irrLP; r: qsTr("Lightpen") }

                        SuLabeledCheckBox { size: Size.small; checked: vic.imrSS; l: qsTr("SS Collision"); Layout.alignment: Qt.AlignRight }
                        SuLabeledCheckBox { size: Size.small; checked: vic.irrSS; r: qsTr("SS Collision") }

                        SuLabeledCheckBox { size: Size.small; checked: vic.imrSB; l: qsTr("SB Collision"); Layout.alignment: Qt.AlignRight }
                        SuLabeledCheckBox { size: Size.small; checked: vic.irrSB; r: qsTr("SB Collision") }

                        SuLabeledCheckBox { size: Size.small; checked: vic.imrRaster; l: qsTr("Raster"); Layout.alignment: Qt.AlignRight }
                        SuLabeledCheckBox { size: Size.small; checked: vic.irrRaster; r: qsTr("Raster") }

                        SuLabeledByteView { size: Size.small; l: qsTr("LP X latch"); value: vic.latchedLPX; Layout.alignment: Qt.AlignRight }
                        SuLabeledCheckBox { size: Size.small; checked: vic.lpLine; r: qsTr("LP line") }

                        SuLabeledByteView { size: Size.small; l: qsTr("LP Y latch"); value: vic.latchedLPY; Layout.alignment: Qt.AlignRight }
                        SuLabeledCheckBox { size: Size.small; checked: vic.lpIrqHasOccurred; r: qsTr("IRQ occurred") }
                    }

                    VSpacer { }
                }

                //
                // Sprites
                //

                ColumnLayout {

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: root.columnWidth
                    Layout.topMargin: 12
                    spacing: Style.mediumSpacing

                    SuSegmentedControl {

                        size: Size.small
                        Layout.alignment: Qt.AlignHCenter
                        model: ["0", "1", "2", "3", "4", "5", "6", "7"]
                        currentIndex: vic.selectedSprite
                        onActivated: (index) => vic.selectedSprite = index
                    }

                    SiBox {

                        id: spritesBox
                        title: qsTr("Sprites")
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: root.boxSpacing

                        GridLayout {

                            columns: 4
                            columnSpacing: Style.smallSpacing
                            rowSpacing: Style.mediumSpacing
                            Layout.alignment: Qt.AlignHCenter

                            SuLabeledCheckBox { size: Size.small; l: qsTr("Enabled:"); lwidth: 32; checked: vic.sprEnabled }
                            Item { Layout.columnSpan: 3 }

                            SuLabeledByteView { size: Size.small; l: qsTr("X:"); lwidth: 32; bits: 12; value: vic.sprX }
                            SuLabeledCheckBox { size: Size.small; checked: vic.sprExpandX; r: qsTr("Exp") }
                            Item { Layout.columnSpan: 2 }
                            // SuLabeledCheckBox { size: Size.small; checked: vic.sprPriority; r: qsTr("Pri") }
                            // SuLabeledCheckBox { size: Size.small; checked: vic.sprMulticolor; r: qsTr("MC") }

                            SuLabeledByteView { size: Size.small; l: qsTr("Y:"); lwidth: 32; bits: 8; value: vic.sprY }
                            SuLabeledCheckBox { size: Size.small; checked: vic.sprExpandY; r: qsTr("Exp") }
                            Item { Layout.columnSpan: 2 }

                            SuLabeledCheckBox { size: Size.small; l: qsTr("Flags:"); lwidth: 32; checked: vic.sprPriority; r: qsTr("Pri") }
                            SuLabeledCheckBox { size: Size.small; checked: vic.sprMulticolor; r: qsTr("MC") }
                            SuLabeledCheckBox { size: Size.small; checked: vic.sprSSCollision; r: qsTr("SS") }
                            SuLabeledCheckBox { size: Size.small; checked: vic.sprSBCollision; r: qsTr("SB") }

                            SuLabeledColorWell {

                                Layout.columnSpan: 4
                                l: qsTr("Colors:"); lwidth: 32; readOnly: true; value: vic.sprColor

                                SuColorWell {
                                    readOnly: true; value: vic.sprExtra1
                                }
                                SuColorWell {
                                    readOnly: true; value: vic.sprExtra2
                                }
                            }
                            Item {}
                        }

                        // VSpacer { }
                    }
                }
            }
        }
    }
}
