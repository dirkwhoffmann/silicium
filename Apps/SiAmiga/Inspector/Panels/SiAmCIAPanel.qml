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

// Port of SiC64CIAPanel.qml. Its own top-level window (see
// SiAmInspectorWindow.qml), same as SiC64's per-panel inspector windows.
//
// Three real differences from the C64 version, all traced back to
// SiAmCIAController's own class comment:
//
//  - The chip selector reads "CIA A"/"CIA B", not "CIA 1"/"CIA 2".
//  - The Time of Day box shows three raw 24-bit counters (TOD/Latch/Alarm)
//    instead of two BCD hour:min:sec.tenth clocks -- the Amiga CIA's TOD is
//    a plain cycle counter, not a real-time clock (see CIAController's
//    'todValue'/'todLatch'/'todAlarm').
//  - Number formatting reads controller.inspectorController's hex/padded
//    booleans instead of C64Controller's single 0..3 'format' enum (see
//    SiAmInspectorController).
SiAmInspectorWindow {

    id: root

    title: qsTr("CIA Inspector")
    currentController: controller.ciaController

    readonly property var cia: controller.ciaController
    readonly property var ic: controller.inspectorController
    readonly property int numBase: ic.hex ? 16 : 10
    readonly property bool numPadded: ic.padded

    // Shared width for every SiBox
    readonly property real columnWidth: Math.max(260,
        (scrollView.availableWidth - Style.largeSpacing * 2) / 3)

    component SiBitViewControl: SiNumberViewControl {

        size: Size.small
        font.weight: 500
        controlWidth: 66
        bits: 8
        base: 2
        padded: true
    }

    component SiByteViewControl: SiNumberViewControl {

        size: Size.small
        font.weight: 500
        controlWidth: 32
        bits: 8
        base: root.numBase
        padded: root.numPadded
    }

    component SiWordViewControl: SiNumberViewControl {

        size: Size.small
        font.weight: 500
        controlWidth: 48
        bits: 16
        base: root.numBase
        padded: root.numPadded
    }

    // A single row of a raw 24-bit CIA TOD counter (value/latch/alarm --
    // there is no BCD hour:min:sec.tenth breakdown on the Amiga, see the
    // class comment).
    component SiTODControl: SiNumberViewControl {

        size: Size.small
        font.weight: 500
        controlWidth: 64
        bits: 24
        base: root.numBase
        padded: root.numPadded
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

                SiWordViewControl {

                    l: qsTr("Timer %1:").arg(label)
                    lwidth: 50
                    value: countValue
                }

                SiWordViewControl {

                    l: qsTr("Latch %1:").arg(label)
                    lwidth: 50
                    value: latchValue
                }

                VSpacer { }
            }

            ColumnLayout {

                spacing: Style.tinySpacing

                SiCheckBoxControl { size: Size.small; bitStyle: true; readOnly: true; checked: running; r: qsTr("Running") }
                SiCheckBoxControl { size: Size.small; bitStyle: true; readOnly: true; checked: toggle; r: qsTr("Toggle") }
                SiCheckBoxControl { size: Size.small; bitStyle: true; readOnly: true; checked: pbout; r: qsTr("PB out") }
                SiCheckBoxControl { size: Size.small; bitStyle: true; readOnly: true; checked: oneShot; r: qsTr("One shot") }
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

                SiByteViewControl {

                    size: Size.small
                    lwidth: 60
                    l: qsTr("Register:")
                    value: portBox.regValue
                }

                SiBitViewControl {

                    size: Size.small
                    indent: 60
                    value: portBox.regValue
                }

                SiByteViewControl {

                    size: Size.small
                    lwidth: 60
                    l: qsTr("Direction:")
                    value: portBox.dirValue
                }

                SiBitViewControl {

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
                    delegate: SiCheckBoxControl {

                        size: Size.small
                        bitStyle: true
                        readOnly: true
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
                text: qsTr("Idle for %1.").arg(cia.idleCycles)
            }

            SiSegmentedControl {

                model: [qsTr("CIA A"), qsTr("CIA B")]
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

                SiProgressBarControl {

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

                            SiByteViewControl {

                                size: Size.small
                                lwidth: 100
                                l: qsTr("Mask Register:")
                                value: cia.imr

                                SiBitViewControl {

                                    size: Size.small
                                    value: cia.imr
                                }

                                HSpacer {}
                            }

                            SiByteViewControl {

                                size: Size.small
                                lwidth: 100
                                l: qsTr("Control Register:")
                                value: cia.icr

                                SiBitViewControl {

                                    size: Size.small
                                    value: cia.icr
                                }
                            }

                            SiCheckBoxControl {

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

                            SiTODControl {

                                l: qsTr("TOD:")
                                lwidth: 48
                                value: cia.todValue
                            }

                            SiTODControl {

                                l: qsTr("Latch:")
                                lwidth: 48
                                value: cia.todLatch
                            }

                            SiTODControl {

                                l: qsTr("Alarm:")
                                lwidth: 48
                                value: cia.todAlarm
                            }

                            SiCheckBoxControl {

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

                            SiByteViewControl {

                                size: Size.small
                                lwidth: 90
                                l: qsTr("Shift Register:")
                                value: cia.ssr

                                SiBitViewControl {

                                    size: Size.small
                                    value: cia.ssr
                                }
                            }

                            SiByteViewControl {

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
