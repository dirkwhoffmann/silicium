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

// Port of vAmiga's own GUI/Inspector/PortPanel.swift: the two control ports
// (joystick/mouse quadrature signals + the shared POTGO/POTGOR
// paddle-control bits) and the serial port (UART shift registers/buffers,
// modem control lines, and the outgoing/incoming byte logs). Its own
// top-level window (see SiAmInspectorWindow.qml).
SiAmInspectorWindow {

    id: root

    title: qsTr("Ports Inspector")
    currentController: controller.portController

    readonly property var po: controller.portController
    readonly property var ic: controller.inspectorController
    readonly property int numBase: ic.hex ? 16 : 10
    readonly property bool numPadded: ic.padded

    // Which serial log the log box shows: 0 = Outgoing, 1 = Incoming.
    property int logPage: 0

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


    // SiWordViewControl (Apps/Shared/QML/Compounds) holds the structural
    // bits; this panel only adds the width override and the hex/decimal
    // toggle binding.
    component SiHex16: SiWordViewControl {

        controlWidth: 64
        base: root.numBase
        padded: root.numPadded
    }

    // A single potgo/potgor bit -- a bare, unlabeled checkbox (the row's own
    // SiLabel carries the name), matching PortPanel.swift's compact
    // OUTxy/DATxy/DATxyR triplets.
    component Bit: SiCheckBoxControl {

        readOnly: true
        implicitWidth: Size.controlHeight(Size.regular)
    }

    RowLayout {

        anchors.fill: parent
        anchors.margins: Style.mediumSpacing
        spacing: Style.mediumSpacing

        //
        // Control Ports
        //

        SiBox {

            title: qsTr("Control Ports")
            // Layout.preferredWidth: 340
            Layout.fillHeight: true
            spacing: Style.mediumSpacing

            GridLayout {

                Layout.topMargin: Style.smallSpacing
                columns: 2
                columnSpacing: Style.largeSpacing
                rowSpacing: Style.largeSpacing

                //
                // JOY0DAT
                //

                ColumnLayout {

                    Si16 {
                        l: qsTr("JOY0DAT"); lwidth: 64; value: po.joydat(parent.index)
                    }
                    Si1 {
                        checked: po.m0v(0); l: qsTr("M0V"); lwidth: 34
                    }
                    Si1 {
                        checked: po.m1v(0); l: qsTr("M1V"); lwidth: 34
                    }
                    Si1 {
                        checked: po.m0h(0); l: qsTr("M0H"); lwidth: 34
                    }
                    Si1 {
                        checked: po.m1h(0); l: qsTr("M1H"); lwidth: 34
                    }
                }

                //
                // JOY1DAT
                //

                ColumnLayout {

                    Si16 {
                        l: qsTr("JOY1DAT"); lwidth: 64; value: po.joydat(parent.index)
                    }
                    Si1 {
                        checked: po.m0v(1); l: qsTr("M0V"); lwidth: 34
                    }
                    Si1 {
                        checked: po.m1v(1); l: qsTr("M1V"); lwidth: 34
                    }
                    Si1 {
                        checked: po.m0h(1); l: qsTr("M0H"); lwidth: 34
                    }
                    Si1 {
                        checked: po.m1h(1); l: qsTr("M1H"); lwidth: 34
                    }
                }

                //
                // POTGO
                //

                ColumnLayout {

                    Si16 {
                        l: qsTr("POTGO"); lwidth: 55; value: po.potgo
                    }
                    Si1 {
                        l: qsTr("OUTRY"); lwidth: 55; checked: po.outry
                        Si1 {
                            r: qsTr("DATRY"); checked: po.outry
                        }
                    }
                    Si1 {
                        l: qsTr("OUTRX"); lwidth: 55; checked: po.outrx
                        Si1 {
                            r: qsTr("DATRX"); checked: po.outrx
                        }
                    }
                    Si1 {
                        l: qsTr("OUTLY"); lwidth: 55; checked: po.outly
                        Si1 {
                            r: qsTr("DATLY"); checked: po.outly
                        }
                    }
                    Si1 {
                        l: qsTr("OUTLX"); lwidth: 55; checked: po.outlx
                        Si1 {
                            r: qsTr("DATLX"); checked: po.outlx
                        }
                    }
                }

                //
                // POTGOR
                //

                ColumnLayout {

                    Si16 {
                        l: qsTr("POTGOR"); lwidth: 55; value: po.potgor
                    }
                    Si1 {
                        l: qsTr("DATRY"); lwidth: 55; checked: po.outry
                    }
                    Si1 {
                        l: qsTr("DATRX"); lwidth: 55; checked: po.outrx
                    }
                    Si1 {
                        l: qsTr("DATLY"); lwidth: 55; checked: po.outly
                    }
                    Si1 {
                        l: qsTr("DATLX"); lwidth: 55; checked: po.outlx
                    }
                }

                //
                // POT0DAT, POT1DAT
                //

                Si16 {
                    l: qsTr("POT0DAT"); lwidth: 60; value: po.potdat(0)
                }
                Si16 {
                    l: qsTr("POT1DAT"); lwidth: 60; value: po.potdat(1)
                }
            }

            VSpacer { }
        }

        //
        // Serial Port
        //

        SiBox {

            title: qsTr("Serial Port")
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Style.mediumSpacing

            ColumnLayout {

                Layout.fillWidth: true
                spacing: Style.smallSpacing

                RowLayout {

                    Si16 {
                        size: Size.small; l: qsTr("SERDAT"); lwidth: 128; value: po.serper
                    }
                    SiText {
                        text: ""; Layout.preferredWidth: 32
                    }
                    SiCheckBoxControl {
                        size: Size.small; readOnly: true; checked: po.long_; r: qsTr("LONG, %1 Baud").arg(po.baudRate)
                    }
                    HSpacer {
                    }
                    Si1 {
                        size: Size.small; checked: po.txd; lwidth: 48; l: qsTr("TXD")
                    }
                    Si1 {
                        size: Size.small; checked: po.dsr; lwidth: 48; l: qsTr("DSR")
                    }
                }

                RowLayout {

                    Si16 {
                        size: Size.small; l: qsTr("Receive shift register"); lwidth: 128; value: po.receiveShiftReg
                    }
                    SiText {
                        text: "→"; Layout.preferredWidth: 32
                    }
                    Si16 {
                        size: Size.small; r: qsTr("Receive buffer"); value: po.receiveBuffer
                    }
                    HSpacer {
                    }
                    Si1 {
                        size: Size.small; checked: po.rxd; lwidth: 48; l: qsTr("RXD")
                    }
                    Si1 {
                        size: Size.small; checked: po.cd; lwidth: 48; l: qsTr("CD")
                    }
                }

                RowLayout {

                    Si16 {
                        size: Size.small; l: qsTr("Transmit shift register"); lwidth: 128; value: po.transmitShiftReg
                    }
                    SiText {
                        text: "→"; Layout.preferredWidth: 32
                    }
                    Si16 {
                        size: Size.small; r: qsTr("Transmit buffer"); value: po.transmitBuffer
                    }
                    HSpacer {
                    }
                    Si1 {
                        size: Size.small; checked: po.cts; lwidth: 48; l: qsTr("CTS")
                    }
                    Si1 {
                        size: Size.small; checked: po.dtr; lwidth: 48; l: qsTr("DTR")
                    }
                }
            }

            SiSegmentedControl {

                Layout.topMargin: Style.smallSpacing
                Layout.alignment: Qt.AlignHCenter // Left
                model: [qsTr("Outgoing"), qsTr("Incoming")]
                segmentWidth: 110
                currentIndex: root.logPage
                onActivated: (index) => root.logPage = index
            }

            Rectangle {

                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Palette.control
                border.width: 1
                border.color: Palette.controlBorder
                radius: Style.radius
                clip: true

                ScrollView {

                    anchors.fill: parent
                    anchors.topMargin: Style.tinySpacing
                    anchors.leftMargin: Style.tinySpacing
                    anchors.rightMargin: Style.tinySpacing
                    anchors.bottomMargin: Style.tinySpacing

                    clip: true

                    TextArea {

                        readOnly: true
                        wrapMode: TextArea.Wrap
                        text: root.logPage === 0 ? po.serialOut : po.serialIn
                        font.family: Fonts.mono
                        color: Palette.primary
                        selectByMouse: true
                        background: null

                        onTextChanged: cursorPosition = length
                    }
                }
            }
        }
    }
}
