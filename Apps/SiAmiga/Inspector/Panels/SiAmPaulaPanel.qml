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
import Silicium.Assets
import Silicium.Controllers
import Silicium.Theme

// Port of vAmiga's own GUI/Inspector/PaulaPanel.swift -- there is no C64
// counterpart to port from (Paula's interrupt controller, disk controller
// and audio DMA state machines have no C64 equivalent). Its own top-level
// window (see SiAmInspectorWindow.qml).
//
// The four "State machine N" diagrams use the same five bitmap assets the
// Swift reference does (Resources/Assets.xcassets/Audio/state0Template.pdf
// .. state5Template.pdf there, registered here as Assets.State0..State5 --
// see Assets.h/.cpp), each already drawing the 5-node graph with one node
// filled in. StateDiagram below just swaps between them by index, keyed
// off SiAmPaulaController::displayState() -- see that controller's class
// comment for the transition table deciding which one shows.
SiAmInspectorWindow {

    id: root

    title: qsTr("Paula Inspector")
    currentController: controller.paulaController

    readonly property var paula: controller.paulaController
    readonly property var ic: controller.inspectorController
    readonly property int numBase: ic.hex ? 16 : 10
    readonly property bool numPadded: ic.padded

    // Shared width for every SiBox (see SiAmCIAPanel)
    readonly property real columnWidth: Math.max(260,
        (scrollView.availableWidth - Style.largeSpacing * 2) / 3)

    // SiByteViewControl/SiWordViewControl (Apps/Shared/QML/Compounds) hold
    // the structural bits; this panel only adds the width override and the
    // hex/decimal toggle binding. The word-view wrapper is named SiHex16
    // rather than SiWordViewControl (unlike this panel's previous local
    // version) to avoid colliding with the shared component of that name.
    component SiHex8: SiByteViewControl {

        // controlWidth: 44
        base: root.numBase
        padded: root.numPadded
    }

    component SiHex16: SiWordViewControl {

        // controlWidth: 64
        base: root.numBase
        padded: root.numPadded
    }

    component SiBitViewControl: SiCheckBoxControl {

        size: Size.small
        bitStyle: true
        readOnly: true
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

    // Five-node DMA state-machine diagram -- one of five pre-rendered
    // template images (see the class comment), picked by currentState (0,
    // 1, 2, 3 or 5 -- anything else falls back to the idle/state0 image).
    // SiTemplateImage (not a plain Image) so the line art tints with
    // Palette.primary the same way the toolbar's MousePress/MousePush
    // icons already do, instead of showing whatever raw color the PNGs
    // happen to be.
    component StateDiagram: SiTemplateImage {

        property int currentState: 0

        implicitWidth: 0 // 150
        implicitHeight: 0 // 150
        Layout.fillWidth: true
        Layout.fillHeight: true

        source: Assets.iconUrl(
            currentState === 0 ? Assets.State0 :
            currentState === 1 ? Assets.State1 :
            currentState === 2 ? Assets.State2 :
            currentState === 3 ? Assets.State3 :
            currentState === 5 ? Assets.State5 :
            Assets.State0)
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
            // Interrupts
            //

            SiBox {

                title: qsTr("Interrupts")
                Layout.preferredWidth: root.columnWidth
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Style.tinySpacing

                // One row per interrupt bit (14 down to 0) -- listed
                // explicitly rather than via a Repeater, so each row reads
                // directly off the source (see SiC64VICPanel's Interrupts
                // box for the same explicit-grid shape). Column 1 (INTENA)
                // is right-aligned, column 2 (INTREQ) left-aligned.
                GridLayout {

                    Layout.alignment: Qt.AlignHCenter
                    columns: 2
                    columnSpacing: Style.largeSpacing
                    rowSpacing: Style.tinySpacing

                    // INTENA/INTREQ header, embedded into a single
                    // SiHex16 the same way SiAmCIAPanel's Mask/
                    // Control Register rows embed a second value as an
                    // accessory -- and placed as the grid's own first row
                    // (spanning both columns) rather than a separate
                    // RowLayout above it.
                    SiHex16 {
                        l: qsTr("INTENA"); lwidth: 55; value: paula.intena; Layout.alignment: Qt.AlignRight
                    }
                    SiHex16 {
                        r: qsTr("INTREQ"); rwidth: 55; value: paula.intreq; Layout.alignment: Qt.AlignLeft
                    }

                    SiBitViewControl {
                        readOnly: true; checked: paula.intenaBit(14); l: paula.intBitLabel(14); lwidth: 55; Layout.alignment: Qt.AlignRight
                    }
                    SiBitViewControl {
                        readOnly: true; checked: paula.intreqBit(14); r: paula.intBitLabel(14); rwidth: 55; Layout.alignment: Qt.AlignLeft
                    }

                    SiBitViewControl {
                        readOnly: true; checked: paula.intenaBit(13); l: paula.intBitLabel(13); lwidth: 55; Layout.alignment: Qt.AlignRight
                    }
                    SiBitViewControl {
                        readOnly: true; checked: paula.intreqBit(13); r: paula.intBitLabel(13); rwidth: 55; Layout.alignment: Qt.AlignLeft
                    }

                    SiBitViewControl {
                        readOnly: true; checked: paula.intenaBit(12); l: paula.intBitLabel(12); lwidth: 55; Layout.alignment: Qt.AlignRight
                    }
                    SiBitViewControl {
                        readOnly: true; checked: paula.intreqBit(12); r: paula.intBitLabel(12); rwidth: 55; Layout.alignment: Qt.AlignLeft
                    }

                    SiBitViewControl {
                        readOnly: true; checked: paula.intenaBit(11); l: paula.intBitLabel(11); lwidth: 55; Layout.alignment: Qt.AlignRight
                    }
                    SiBitViewControl {
                        readOnly: true; checked: paula.intreqBit(11); r: paula.intBitLabel(11); rwidth: 55; Layout.alignment: Qt.AlignLeft
                    }

                    SiBitViewControl {
                        readOnly: true; checked: paula.intenaBit(10); l: paula.intBitLabel(10); lwidth: 55; Layout.alignment: Qt.AlignRight
                    }
                    SiBitViewControl {
                        readOnly: true; checked: paula.intreqBit(10); r: paula.intBitLabel(10); rwidth: 55; Layout.alignment: Qt.AlignLeft
                    }

                    SiBitViewControl {
                        readOnly: true; checked: paula.intenaBit(9); l: paula.intBitLabel(9); lwidth: 55; Layout.alignment: Qt.AlignRight
                    }
                    SiBitViewControl {
                        readOnly: true; checked: paula.intreqBit(9); r: paula.intBitLabel(9); rwidth: 55; Layout.alignment: Qt.AlignLeft
                    }

                    SiBitViewControl {
                        readOnly: true; checked: paula.intenaBit(8); l: paula.intBitLabel(8); lwidth: 55; Layout.alignment: Qt.AlignRight
                    }
                    SiBitViewControl {
                        readOnly: true; checked: paula.intreqBit(8); r: paula.intBitLabel(8); rwidth: 55; Layout.alignment: Qt.AlignLeft
                    }

                    SiBitViewControl {
                        readOnly: true; checked: paula.intenaBit(7); l: paula.intBitLabel(7); lwidth: 55; Layout.alignment: Qt.AlignRight
                    }
                    SiBitViewControl {
                        readOnly: true; checked: paula.intreqBit(7); r: paula.intBitLabel(7); rwidth: 55; Layout.alignment: Qt.AlignLeft
                    }

                    SiBitViewControl {
                        readOnly: true; checked: paula.intenaBit(6); l: paula.intBitLabel(6); lwidth: 55; Layout.alignment: Qt.AlignRight
                    }
                    SiBitViewControl {
                        readOnly: true; checked: paula.intreqBit(6); r: paula.intBitLabel(6); rwidth: 55; Layout.alignment: Qt.AlignLeft
                    }

                    SiBitViewControl {
                        readOnly: true; checked: paula.intenaBit(5); l: paula.intBitLabel(5); lwidth: 55; Layout.alignment: Qt.AlignRight
                    }
                    SiBitViewControl {
                        readOnly: true; checked: paula.intreqBit(5); r: paula.intBitLabel(5); rwidth: 55; Layout.alignment: Qt.AlignLeft
                    }

                    SiBitViewControl {
                        readOnly: true; checked: paula.intenaBit(4); l: paula.intBitLabel(4); lwidth: 55; Layout.alignment: Qt.AlignRight
                    }
                    SiBitViewControl {
                        readOnly: true; checked: paula.intreqBit(4); r: paula.intBitLabel(4); rwidth: 55; Layout.alignment: Qt.AlignLeft
                    }

                    SiBitViewControl {
                        readOnly: true; checked: paula.intenaBit(3); l: paula.intBitLabel(3); lwidth: 55; Layout.alignment: Qt.AlignRight
                    }
                    SiBitViewControl {
                        readOnly: true; checked: paula.intreqBit(3); r: paula.intBitLabel(3); rwidth: 55; Layout.alignment: Qt.AlignLeft
                    }

                    SiBitViewControl {
                        readOnly: true; checked: paula.intenaBit(2); l: paula.intBitLabel(2); lwidth: 55; Layout.alignment: Qt.AlignRight
                    }
                    SiBitViewControl {
                        readOnly: true; checked: paula.intreqBit(2); r: paula.intBitLabel(2); rwidth: 55; Layout.alignment: Qt.AlignLeft
                    }

                    SiBitViewControl {
                        readOnly: true; checked: paula.intenaBit(1); l: paula.intBitLabel(1); lwidth: 55; Layout.alignment: Qt.AlignRight
                    }
                    SiBitViewControl {
                        readOnly: true; checked: paula.intreqBit(1); r: paula.intBitLabel(1); rwidth: 55; Layout.alignment: Qt.AlignLeft
                    }

                    SiBitViewControl {
                        readOnly: true; checked: paula.intenaBit(0); l: paula.intBitLabel(0); lwidth: 55; Layout.alignment: Qt.AlignRight
                    }
                    SiBitViewControl {
                        readOnly: true; checked: paula.intreqBit(0); r: paula.intBitLabel(0); rwidth: 55; Layout.alignment: Qt.AlignLeft
                    }
                }
            }

            //
            // Disk Controller
            //

            SiBox {

                title: qsTr("Disk Controller")
                Layout.preferredWidth: root.columnWidth
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Style.mediumSpacing

                ColumnLayout {

                    Layout.alignment: Qt.AlignHCenter
                    spacing: Style.tinySpacing

                    RowLayout {
                        spacing: Style.smallSpacing
                        SiLabel {
                            text: qsTr("Selected Drive:")
                        }
                        Repeater {
                            model: 4
                            RowLayout {
                                required property int index
                                spacing: 2
                                SiLabel {
                                    text: index
                                }
                                SiBitViewControl {
                                    readOnly: true; checked: paula.selectedDrive === index
                                }
                            }
                        }
                    }

                    RowLayout {
                        spacing: Style.smallSpacing
                        SiLabel {
                            text: qsTr("State:")
                        }
                        SiLabel {
                            text: paula.dcStateText; font.weight: 500
                        }
                    }

                    GridLayout {

                        Layout.topMargin: Style.smallSpacing
                        columns: 2
                        columnSpacing: Style.largeSpacing
                        rowSpacing: Style.tinySpacing

                        SiHex16 {
                            l: qsTr("DSKLEN"); lwidth: 90; value: paula.dsklen
                        }
                        SiHex8 {
                            l: qsTr("ADKCON HI"); lwidth: 90; value: paula.adkconHi
                        }

                        SiBitViewControl {
                            readOnly: true; checked: paula.dmaen; l: qsTr("DMAEN"); lwidth: 90
                        }
                        SiBitViewControl {
                            readOnly: true; checked: paula.precomp1; l: qsTr("PRECOMP1"); lwidth: 90
                        }

                        SiBitViewControl {
                            readOnly: true; checked: paula.write; l: qsTr("WRITE"); lwidth: 90
                        }
                        SiBitViewControl {
                            readOnly: true; checked: paula.precomp0; l: qsTr("PRECOMP0"); lwidth: 90
                        }

                        SiHex16 {
                            l: qsTr("DSKBYTE"); lwidth: 90; value: paula.dskbytr
                        }
                        SiBitViewControl {
                            readOnly: true; checked: paula.mfmprec; l: qsTr("MFMPREC"); lwidth: 90
                        }

                        SiBitViewControl {
                            readOnly: true; checked: paula.byteready; l: qsTr("BYTEREADY"); lwidth: 90
                        }
                        SiBitViewControl {
                            readOnly: true; checked: paula.uartbrk; l: qsTr("UARTBRK"); lwidth: 90
                        }

                        SiBitViewControl {
                            readOnly: true; checked: paula.dmaon; l: qsTr("DMAON"); lwidth: 90
                        }
                        SiBitViewControl {
                            readOnly: true; checked: paula.wordsync; l: qsTr("WORDSYNC"); lwidth: 90
                        }

                        SiBitViewControl {
                            readOnly: true; checked: paula.diskwrite; l: qsTr("DISKWRITE"); lwidth: 90
                        }
                        SiBitViewControl {
                            readOnly: true; checked: paula.msbsync; l: qsTr("MSBSYNC"); lwidth: 90
                        }

                        SiBitViewControl {
                            readOnly: true; checked: paula.wordequal; l: qsTr("WORDEQUAL"); lwidth: 90
                        }
                        SiBitViewControl {
                            readOnly: true; checked: paula.fast; l: qsTr("FAST"); lwidth: 90
                        }
                    }

                    RowLayout {

                        Layout.topMargin: Style.smallSpacing
                        spacing: Style.tinySpacing

                        SiHex16 {
                            l: qsTr("DSKSYNC"); lwidth: 65; value: paula.dsksync
                        }

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

                            SiText {
                                text: "→"
                            }

                            Repeater {
                                model: 6
                                FifoCell {
                                    required property int index
                                    value: paula.fifoAt(index)
                                }
                            }

                            SiText {
                                text: "→"
                            }
                        }
                    }
                }
            }

            //
            // Audio
            //

            SiBox {

                title: qsTr("Audio")
                Layout.preferredWidth: root.columnWidth
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Style.mediumSpacing

                ColumnLayout {

                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: Style.mediumSpacing

                    GridLayout {

                        Layout.alignment: Qt.AlignHCenter
                        columns: 5
                        columnSpacing: Style.tinySpacing
                        rowSpacing: Style.tinySpacing

                        // Transposed from the register-per-row layout this
                        // used to have: channel index (0-3) down the first
                        // column, register name across the header row --
                        // this way the grid only needs 5 narrow columns
                        // instead of 5 wide ones, saving horizontal space.
                        Item {
                        } // Layout.preferredWidth: 24 }
                        SiLabel {
                            size: Size.small; text: qsTr("AUDxLEN"); horizontalAlignment: Text.AlignHCenter
                        } // ;Layout.preferredWidth: 48 }
                        SiLabel {
                            size: Size.small; text: qsTr("AUDxPER"); horizontalAlignment: Text.AlignHCenter
                        } // ; Layout.preferredWidth: 48 }
                        SiLabel {
                            size: Size.small; text: qsTr("AUDxVOL"); horizontalAlignment: Text.AlignHCenter
                        } // ; Layout.preferredWidth: 48 }
                        SiLabel {
                            size: Size.small; text: qsTr("AUDxDAT"); horizontalAlignment: Text.AlignHCenter
                        } // ; Layout.preferredWidth: 48 }

                        SiLabel {
                            size: Size.small; text: "0"; horizontalAlignment: Text.AlignHCenter
                        }
                        SiHex16 {
                            value: paula.audioLen(0)
                        }
                        SiHex16 {
                            value: paula.audioPer(0)
                        }
                        SiHex16 {
                            value: paula.audioVol(0)
                        }
                        SiHex16 {
                            value: paula.audioDat(0)
                        }

                        SiLabel {
                            size: Size.small; text: "1"; horizontalAlignment: Text.AlignHCenter
                        }
                        SiHex16 {
                            value: paula.audioLen(1)
                        }
                        SiHex16 {
                            value: paula.audioPer(1)
                        }
                        SiHex16 {
                            value: paula.audioVol(1)
                        }
                        SiHex16 {
                            value: paula.audioDat(1)
                        }

                        SiLabel {
                            size: Size.small; text: "2"; horizontalAlignment: Text.AlignHCenter
                        }
                        SiHex16 {
                            value: paula.audioLen(2)
                        }
                        SiHex16 {
                            value: paula.audioPer(2)
                        }
                        SiHex16 {
                            value: paula.audioVol(2)
                        }
                        SiHex16 {
                            value: paula.audioDat(2)
                        }

                        SiLabel {
                            size: Size.small; text: "3"; horizontalAlignment: Text.AlignHCenter
                        }
                        SiHex16 {
                            value: paula.audioLen(3)
                        }
                        SiHex16 {
                            value: paula.audioPer(3)
                        }
                        SiHex16 {
                            value: paula.audioVol(3)
                        }
                        SiHex16 {
                            value: paula.audioDat(3)
                        }
                    }

                    // A plain ColumnLayout of two RowLayouts instead of a
                    // 2-column GridLayout: GridLayout only sizes a column/row to
                    // the largest cell's own preferred size and never redistributes
                    // extra space to a fillWidth/fillHeight cell beyond that, so
                    // the four StateDiagram images stayed pinned to their 150x150
                    // implicit size instead of growing with the box. Row/Column
                    // Layout does propagate fillWidth/fillHeight down to a child,
                    // so this stretches properly.
                    ColumnLayout {

                        Layout.topMargin: Style.mediumSpacing
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: Style.mediumSpacing

                        RowLayout {

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: Style.mediumSpacing

                            SiBox {
                                title: qsTr("State machine 0")
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                StateDiagram {
                                    currentState: paula.displayState(0)
                                }
                            }

                            SiBox {
                                title: qsTr("State machine 1")
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                StateDiagram {
                                    currentState: paula.displayState(1)
                                }
                            }
                        }

                        RowLayout {

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: Style.mediumSpacing

                            SiBox {
                                title: qsTr("State machine 2")
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                StateDiagram {
                                    currentState: paula.displayState(2)
                                }
                            }

                            SiBox {
                                title: qsTr("State machine 3")
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                StateDiagram {
                                    currentState: paula.displayState(3)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
