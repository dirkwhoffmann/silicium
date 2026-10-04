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

    title: qsTr("CIA Inspector")
    currentController: controller.ciaController

    readonly property var cia: controller.ciaController
    readonly property int numBase: (controller.format === 0 || controller.format === 1) ? 16 : 10
    readonly property bool numPadded: controller.format === 1 || controller.format === 3

    // Shared width for every SiBox
    readonly property real columnWidth: Math.max(260,
        (scrollView.availableWidth - Style.largeSpacing * 2) / 3)

    component SiLabeledBinaryView: SiLabeledNumberView {

        size: Size.small
        font.weight: 500
        controlWidth: 66
        bits: 8
        base: 2
        padded: true
    }

    component SiLabeledByteView: SiLabeledNumberView {

        size: Size.small
        font.weight: 500
        controlWidth: 32
        bits: 8
        base: root.numBase
        padded: root.numPadded
    }

    component SiLabeledWordView: SiLabeledNumberView {

        size: Size.small
        font.weight: 500
        controlWidth: 48
        bits: 16
        base: root.numBase
        padded: root.numPadded
    }

    // A labeled row of the four TOD fields (hours, minutes, seconds,
    // tenths), each shown as a SiLabeledByteView.
    component SiLabeledTOD: SiLabeled {

        id: todControl

        property int hours: 0
        property int minutes: 0
        property int seconds: 0
        property int tenths: 0

        size: Size.small
        hasFlexControl: false

        control: [

            RowLayout {

                spacing: Style.smallSpacing

                SiLabeledByteView { value: todControl.hours }
                SiText { text: ":"; Layout.leftMargin: 1 }
                SiLabeledByteView { value: todControl.minutes }
                SiText { text: ":"; Layout.leftMargin: 1 }
                SiLabeledByteView { value: todControl.seconds }
                SiText { text: ":"; Layout.leftMargin: 1 }
                SiLabeledByteView { value: todControl.tenths }
            }
        ]
    }

    //
    // Timer
    //

    component Timer: ColumnLayout {

        property string label: ""
        property int countValue: 0
        property int latchValue: 0
        property bool running: false
        property bool toggle: false
        property bool pbout: false
        property bool oneShot: false

        spacing: Style.tinySpacing

        RowLayout {

            spacing: Style.largeSpacing

            ColumnLayout {

                SiLabeledWordView {

                    l: qsTr("Timer %1:").arg(label)
                    lwidth: 50
                    value: countValue
                }

                SiLabeledWordView {

                    l: qsTr("Latch %1:").arg(label)
                    lwidth: 50
                    value: latchValue
                }

                VSpacer { }
            }

            ColumnLayout {

                spacing: Style.tinySpacing

                SiLabeledBitView { checked: running; r: qsTr("Running") }
                SiLabeledBitView { checked: toggle; r: qsTr("Toggle") }
                SiLabeledBitView { checked: pbout; r: qsTr("PB out") }
                SiLabeledBitView { checked: oneShot; r: qsTr("One shot") }
            }
        }
    }

    //
    // Data Port
    //

    component Port: SiBox {

        id: portBox

        property int regValue: 0
        property int dirValue: 0
        property int portValue: 0
        property var labels: []

        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Style.tinySpacing

        RowLayout {

            spacing: Style.largeSpacing

            ColumnLayout {

                SiLabeledByteView {

                    size: Size.small
                    lwidth: 60
                    l: qsTr("Register:")
                    value: portBox.regValue
                }

                SiLabeledBinaryView {

                    size: Size.small
                    indent: 60
                    value: portBox.regValue
                }

                SiLabeledByteView {

                    size: Size.small
                    lwidth: 60
                    l: qsTr("Direction:")
                    value: portBox.dirValue
                }

                SiLabeledBinaryView {

                    size: Size.small
                    indent: 60
                    value: portBox.dirValue
                }

                VSpacer { }
            }

            ColumnLayout {

                spacing: Style.tinySpacing

                Repeater {

                    model: 8
                    delegate: SiLabeledBitView {

                        required property int index
                        readonly property int bitNr: 7 - index
                        checked: (portBox.portValue & (1 << bitNr)) !== 0
                        r: portBox.labels[bitNr]
                    }
                }
            }
        }
    }

    //
    // Main
    //

    ColumnLayout {

        anchors.fill: parent
        anchors.margins: Style.mediumSpacing
        spacing: Style.mediumSpacing

        //
        // Top row
        //

        RowLayout {

            Layout.fillWidth: true
            spacing: Style.mediumSpacing

            SiLabel {

                Layout.fillWidth: true
                Layout.preferredWidth: 200
                horizontalAlignment: Text.AlignLeft
                text: qsTr("Idle for %1 cycles.").arg(cia.idleCycles)
            }

            SiSegmentedControl {

                model: [qsTr("CIA 1"), qsTr("CIA 2")]
                currentIndex: cia.selectedCia
                onActivated: (index) => cia.selectedCia = index
            }

            RowLayout {

                Layout.fillWidth: true
                Layout.preferredWidth: 200
                spacing: 0

                HSpacer { }

                SiLabel {

                    Layout.alignment: Qt.AlignVCenter
                    text: qsTr("Overall active time:")
                }

                SiLabeledProgressBar {

                    l: qsTr("%1 %").arg(100 - cia.idlePercentage)
                    lwidth: 48
                    controlWidth: 80
                    from: 0
                    to: 100
                    value: 100 - cia.idlePercentage
                }
            }
        }

        //
        // Main
        //

        ScrollView {

            id: scrollView

            Layout.fillWidth: true
            Layout.fillHeight: true

            clip: true
            contentWidth: content.implicitWidth

            // A single 3-column grid holds all six boxes, wrapping into two
            // rows of three automatically. GridLayout has no per-column
            // stretch factor, so pin every cell's width to root.columnWidth
            // instead, so all three columns stay equal and track window
            // resizes together (see SiC64SIDPanel / SiC64VICPanel).
            GridLayout {

                id: content

                columns: 3
                columnSpacing: Style.largeSpacing
                rowSpacing: Style.largeSpacing

                //
                // Timers and Ports
                //

                    SiBox {

                        id: timersBox
                        title: qsTr("Timers")
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: root.columnWidth
                        spacing: Style.mediumSpacing

                        Timer {

                            label: qsTr("A")
                            Layout.alignment: Qt.AlignHCenter
                            countValue: cia.timerACount
                            latchValue: cia.timerALatch
                            running: cia.timerARunning
                            toggle: cia.timerAToggle
                            pbout: cia.timerAPbout
                            oneShot: cia.timerAOneShot
                        }

                        Timer {

                            label: qsTr("B")
                            Layout.alignment: Qt.AlignHCenter
                            countValue: cia.timerBCount
                            latchValue: cia.timerBLatch
                            running: cia.timerBRunning
                            toggle: cia.timerBToggle
                            pbout: cia.timerBPbout
                            oneShot: cia.timerBOneShot
                        }
                    }

                    Port {

                        id: portABox
                        title: qsTr("Data port A")
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: root.columnWidth
                        regValue: cia.portAReg
                        dirValue: cia.portADir
                        portValue: cia.portAPort
                        labels: cia.portALabels
                    }

                    Port {

                        id: portBBox
                        title: qsTr("Data port B")
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: root.columnWidth
                        regValue: cia.portBReg
                        dirValue: cia.portBDir
                        portValue: cia.portBPort
                        labels: cia.portBLabels
                    }

                //
                // Interrupts, TOD clock, Serial shift register
                //

                    SiBox {

                        id: interruptsBox
                        title: qsTr("Interrupts")
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: root.columnWidth
                        spacing: Style.tinySpacing

                        ColumnLayout {

                            Layout.alignment: Qt.AlignHCenter

                            SiLabeledByteView {

                                size: Size.small
                                lwidth: 100
                                l: qsTr("Mask Register:")
                                value: cia.imr

                                SiLabeledBinaryView {

                                    size: Size.small
                                    value: cia.imr
                                }

                                HSpacer {}
                            }

                            SiLabeledByteView {

                                size: Size.small
                                lwidth: 100
                                l: qsTr("Control Register:")
                                value: cia.icr

                                SiLabeledBinaryView {

                                    size: Size.small
                                    value: cia.icr
                                }
                            }

                            SiLabeledCheckBox {

                                indent: 100
                                size: Size.small
                                checked: cia.intLineLow
                                r: cia.intLineLabel
                            }
                        }
                    }

                    SiBox {

                        id: todBox
                        title: qsTr("Time of Day Clock")
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: root.columnWidth
                        spacing: Style.tinySpacing

                        ColumnLayout {

                            Layout.alignment: Qt.AlignHCenter

                            SiLabeledTOD {

                                l: qsTr("TOD:")
                                lwidth: 48
                                hours: cia.todHour
                                minutes: cia.todMin
                                seconds: cia.todSec
                                tenths: cia.todTenth
                            }

                            SiLabeledTOD {

                                l: qsTr("Alarm:")
                                lwidth: 48
                                hours: cia.todAlarmHour
                                minutes: cia.todAlarmMin
                                seconds: cia.todAlarmSec
                                tenths: cia.todAlarmTenth
                            }

                            SiLabeledCheckBox {

                                size: Size.small
                                indent: 48
                                checked: cia.todIntEnable
                                r: qsTr("IRQ Enabled")
                            }
                        }
                    }

                    SiBox {

                        id: sdrBox
                        title: qsTr("Serial Shift Register")
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: root.columnWidth
                        spacing: Style.tinySpacing

                        ColumnLayout {

                            Layout.alignment: Qt.AlignHCenter

                            SiLabeledByteView {

                                size: Size.small
                                lwidth: 90
                                l: qsTr("Shift Register:")
                                value: cia.ssr

                                SiLabeledBinaryView {

                                    size: Size.small
                                    value: cia.ssr
                                }
                            }

                            SiLabeledByteView {

                                size: Size.small
                                lwidth: 90
                                l: qsTr("Data Register:")
                                value: cia.sdr
                            }
                        }
                    }
            }
        }
    }
}
