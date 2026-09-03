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
// and audio DMA state machines have no C64 equivalent). A plain page
// inside SiAmInspectorWindow's sidebar StackLayout (see that file), not
// its own window; SiAmInspectorWindow.updateActiveController() drives
// controller.paulaController.active for it, the same way it already does
// for the other panels.
//
// The four "State machine N" diagrams use the same five bitmap assets the
// Swift reference does (Resources/Assets.xcassets/Audio/state0Template.pdf
// .. state5Template.pdf there, registered here as Assets.State0..State5 --
// see Assets.h/.cpp), each already drawing the 5-node graph with one node
// filled in. StateDiagram below just swaps between them by index, keyed
// off SiAmPaulaController::displayState() -- see that controller's class
// comment for the transition table deciding which one shows.
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

    // Five-node DMA state-machine diagram -- one of five pre-rendered
    // template images (see the class comment), picked by currentState (0,
    // 1, 2, 3 or 5 -- anything else falls back to the idle/state0 image).
    // SiTemplateImage (not a plain Image) so the line art tints with
    // Palette.primary the same way the toolbar's MousePress/MousePush
    // icons already do, instead of showing whatever raw color the PNGs
    // happen to be.
    component StateDiagram: SiTemplateImage {

        property int currentState: 0

        implicitWidth: 150
        implicitHeight: 150

        source: Assets.iconUrl(
            currentState === 0 ? Assets.State0 :
            currentState === 1 ? Assets.State1 :
            currentState === 2 ? Assets.State2 :
            currentState === 3 ? Assets.State3 :
            currentState === 5 ? Assets.State5 :
            Assets.State0)
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
