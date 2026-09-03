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
// modem control lines, and the outgoing/incoming byte logs).
Item {

    id: root

    required property SiAmController controller

    readonly property var po: controller.portController
    readonly property var ic: controller.inspectorController
    readonly property int numBase: ic.hex ? 16 : 10
    readonly property bool numPadded: ic.padded

    // Which serial log the log box shows: 0 = Outgoing, 1 = Incoming.
    property int logPage: 0

    component SiHex16: SiNumberViewControl {

        size: Size.small
        font.weight: 500
        controlWidth: 64
        bits: 16
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
            Layout.preferredWidth: 340
            Layout.fillHeight: true
            spacing: Style.mediumSpacing

            RowLayout {

                Layout.fillWidth: true
                spacing: Style.largeSpacing

                Repeater {

                    model: 2

                    ColumnLayout {

                        required property int index
                        spacing: Style.tinySpacing

                        SiHex16 { l: qsTr("JOY%1DAT").arg(parent.index); lwidth: 64; value: po.joydat(parent.index) }

                        SiCheckBoxControl { readOnly: true; checked: po.m0v(parent.index); l: qsTr("M0V"); lwidth: 34 }
                        SiCheckBoxControl { readOnly: true; checked: po.m1v(parent.index); l: qsTr("M1V"); lwidth: 34 }
                        SiCheckBoxControl { readOnly: true; checked: po.m0h(parent.index); l: qsTr("M0H"); lwidth: 34 }
                        SiCheckBoxControl { readOnly: true; checked: po.m1h(parent.index); l: qsTr("M1H"); lwidth: 34 }
                    }
                }

                HSpacer { }
            }

            VSpacer { size: Style.mediumSpacing }

            RowLayout {

                Layout.fillWidth: true
                spacing: Style.tinySpacing
                SiHex16 { l: qsTr("POTGO"); lwidth: 55; value: po.potgo }
                SiHex16 { l: qsTr("POTGOR"); lwidth: 60; value: po.potgor }
            }

            GridLayout {

                Layout.topMargin: Style.smallSpacing
                columns: 6
                columnSpacing: Style.smallSpacing
                rowSpacing: Style.tinySpacing

                SiLabel { text: qsTr("OUTRY") }
                Bit { checked: po.outry }
                Bit { checked: po.datry }
                SiLabel { text: qsTr("DATRY") }
                Bit { checked: po.datryr }
                Item { }

                SiLabel { text: qsTr("OUTRX") }
                Bit { checked: po.outrx }
                Bit { checked: po.datrx }
                SiLabel { text: qsTr("DATRX") }
                Bit { checked: po.datrxr }
                Item { }

                SiLabel { text: qsTr("OUTLY") }
                Bit { checked: po.outly }
                Bit { checked: po.datly }
                SiLabel { text: qsTr("DATLY") }
                Bit { checked: po.datlyr }
                Item { }

                SiLabel { text: qsTr("OUTLX") }
                Bit { checked: po.outlx }
                Bit { checked: po.datlx }
                SiLabel { text: qsTr("DATLX") }
                Bit { checked: po.datlxr }
                Item { }
            }

            VSpacer { size: Style.mediumSpacing }

            RowLayout {

                Layout.fillWidth: true
                spacing: Style.largeSpacing

                SiHex16 { l: qsTr("POT0DAT"); lwidth: 60; value: po.potdat(0) }
                SiHex16 { l: qsTr("POT1DAT"); lwidth: 60; value: po.potdat(1) }
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

            RowLayout {

                Layout.fillWidth: true
                spacing: Style.largeSpacing

                RowLayout {
                    spacing: Style.tinySpacing
                    SiHex16 { l: qsTr("SERDAT"); lwidth: 55; value: po.serper }
                    SiCheckBoxControl { readOnly: true; checked: po.long_ }
                    SiLabel { text: qsTr("LONG, %1 Baud").arg(po.baudRate) }
                }

                HSpacer { }

                GridLayout {
                    columns: 4
                    columnSpacing: Style.mediumSpacing
                    rowSpacing: Style.tinySpacing
                    SiCheckBoxControl { readOnly: true; checked: po.txd; r: qsTr("TXD") }
                    SiCheckBoxControl { readOnly: true; checked: po.dsr; r: qsTr("DSR") }
                    SiCheckBoxControl { readOnly: true; checked: po.rxd; r: qsTr("RXD") }
                    SiCheckBoxControl { readOnly: true; checked: po.cd;  r: qsTr("CD") }
                    SiCheckBoxControl { readOnly: true; checked: po.cts; r: qsTr("CTS") }
                    SiCheckBoxControl { readOnly: true; checked: po.dtr; r: qsTr("DTR") }
                }
            }

            RowLayout {

                Layout.fillWidth: true
                spacing: Style.largeSpacing

                RowLayout {
                    spacing: Style.tinySpacing
                    SiLabel { text: qsTr("Receive shift register") }
                    SiHex16 { value: po.receiveShiftReg }
                    SiText { text: "→" }
                    SiHex16 { value: po.receiveBuffer }
                    SiLabel { text: qsTr("Receive buffer") }
                }
            }

            RowLayout {

                Layout.fillWidth: true
                spacing: Style.tinySpacing

                SiLabel { text: qsTr("Transmit buffer") }
                SiHex16 { value: po.transmitBuffer }
                SiText { text: "→" }
                SiHex16 { value: po.transmitShiftReg }
                SiLabel { text: qsTr("Transmit shift register") }
            }

            SiSegmentedControl {

                Layout.topMargin: Style.smallSpacing
                Layout.alignment: Qt.AlignLeft
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
                    anchors.margins: 1
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
