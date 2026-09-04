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

// Port of vAmiga's own GUI/Inspector/CPUPanel.swift. Its own top-level
// window (see SiAmInspectorWindow.qml), mirroring SiC64CPUPanel.qml, so it
// can stay open alongside any of the other panels.
//
// Unlike SiC64CPUPanel.qml's two-way Program/Debug segmented control
// (Program showing disassembly and trace side by side), this uses a
// three-way Program/Trace/Debug tab bar -- the 68000's variable-length
// instructions make each disassembly/trace column wider than the 6510's, so
// there isn't room to show two of the three side by side the way SiC64 does.
SiAmInspectorWindow {

    id: root

    title: qsTr("CPU Inspector")
    currentController: controller.cpuController

    readonly property var cpu: controller.cpuController
    readonly property var cc: controller.configController
    readonly property var ic: controller.inspectorController
    readonly property int numBase: ic.hex ? 16 : 10
    readonly property bool numPadded: ic.padded

    // Which page the stack shows: 0 = Program, 1 = Trace, 2 = Debug.
    property int page: 0

    // CPU revision gates (mirrors CPUPanel.swift's below10/below20): the
    // 68000 has no VBR/SFC/DFC (added in the 68010) and no MSP/CACR/CAAR or
    // second trace bit T0/M (added in the 68020).
    readonly property int cpuRev: cc.CPU_REVISION
    readonly property bool below10: cpuRev === 0
    readonly property bool below20: cpuRev === 0 || cpuRev === 1

    component SiHex32: SiNumberViewControl {

        size: Size.small
        font.weight: 500
        controlWidth: 92
        bits: 32
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

    component FlagCheck: ColumnLayout {

        property bool on: false
        property string label: ""

        spacing: 1

        SiCheckBox {

            Layout.alignment: Qt.AlignHCenter
            checked: on
            readOnly: true
        }

        SiText {

            Layout.alignment: Qt.AlignHCenter
            text: label
            font.pixelSize: Style.tiny
            color: Palette.primary
        }
    }

    RowLayout {

        anchors.fill: parent
        anchors.margins: Style.mediumSpacing
        spacing: Style.mediumSpacing

        //
        // Program / Trace / Debug stack
        //

        Item {

            Layout.fillWidth: true
            Layout.fillHeight: true

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

                    SiAmCPUDasmView {

                        id: dasmView
                        cpu: root.cpu
                        cc: root.cc
                        numBase: root.numBase
                    }

                    SiAmCPUTraceView {

                        id: traceView
                        cpu: root.cpu
                    }

                    RowLayout {

                        spacing: Style.largeSpacing

                        SiAmCPUGuardView {

                            title: qsTr("Breakpoints")
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            numBase: root.numBase
                            model: cpu.breakpoints
                            onToggle: (row) => cpu.toggleBreakpointRow(row)
                            onRemove: (row) => cpu.removeBreakpointRow(row)
                            onMove: (row, addr) => cpu.moveBreakpointRow(row, addr)
                            onAdd: (addr) => cpu.addBreakpoint(addr)
                        }

                        SiAmCPUGuardView {

                            title: qsTr("Watchpoints")
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            numBase: root.numBase
                            model: cpu.watchpoints
                            onToggle: (row) => cpu.toggleWatchpointRow(row)
                            onRemove: (row) => cpu.removeWatchpointRow(row)
                            onMove: (row, addr) => cpu.moveWatchpointRow(row, addr)
                            onAdd: (addr) => cpu.addWatchpoint(addr)
                        }
                    }
                }
            }

            SiSegmentedControl {

                id: tabControl
                anchors.horizontalCenter: stackBox.horizontalCenter
                anchors.verticalCenter: stackBox.top

                model: [qsTr("Program"), qsTr("Trace"), qsTr("Debug")]
                segmentWidth: 90
                currentIndex: root.page
                onActivated: (index) => root.page = index
            }
        }

        //
        // Registers
        //

        SiBox {

            title: qsTr("Registers")
            Layout.preferredWidth: 300
            Layout.fillHeight: true
            spacing: Style.tinySpacing

            RowLayout {

                Layout.fillWidth: true
                spacing: Style.mediumSpacing

                SiHex32 { l: qsTr("PC"); lwidth: 24; value: controller.info.pc }
                SiHex16 { l: qsTr("IRD"); lwidth: 30; value: cpu.ird }
                SiHex16 { l: qsTr("IRC"); lwidth: 30; value: cpu.irc }
            }

            // D0..D7 / A0..A7 register file, plus the ISP/USP/MSP/VBR/
            // SFC/DFC/CACR/CAAR block -- laid out as a single 3-column
            // grid (address-space block, data registers, address
            // registers), matching CPUPanel.swift's three-column layout.
            GridLayout {

                Layout.fillWidth: true
                columns: 3
                columnSpacing: Style.mediumSpacing
                rowSpacing: Style.smallSpacing

                readonly property int lw: 32
                readonly property var info: controller.info

                SiHex32 { l: qsTr("ISP"); lwidth: parent.lw; value: cpu.isp }
                SiHex32 { l: qsTr("D0"); lwidth: 20; value: parent.info.dReg(0) }
                SiHex32 { l: qsTr("A0"); lwidth: 20; value: parent.info.aReg(0) }

                SiHex32 { l: qsTr("USP"); lwidth: parent.lw; value: cpu.usp }
                SiHex32 { l: qsTr("D1"); lwidth: 20; value: parent.info.dReg(1) }
                SiHex32 { l: qsTr("A1"); lwidth: 20; value: parent.info.aReg(1) }

                SiHex32 { l: qsTr("MSP"); lwidth: parent.lw; value: cpu.msp; visible: !root.below20 }
                SiHex32 { l: qsTr("D2"); lwidth: 20; value: parent.info.dReg(2) }
                SiHex32 { l: qsTr("A2"); lwidth: 20; value: parent.info.aReg(2) }

                SiHex32 { l: qsTr("VBR"); lwidth: parent.lw; value: cpu.vbr; visible: !root.below10 }
                SiHex32 { l: qsTr("D3"); lwidth: 20; value: parent.info.dReg(3) }
                SiHex32 { l: qsTr("A3"); lwidth: 20; value: parent.info.aReg(3) }

                SiHex16 { l: qsTr("SFC"); lwidth: parent.lw; value: cpu.sfc; visible: !root.below10 }
                SiHex32 { l: qsTr("D4"); lwidth: 20; value: parent.info.dReg(4) }
                SiHex32 { l: qsTr("A4"); lwidth: 20; value: parent.info.aReg(4) }

                SiHex16 { l: qsTr("DFC"); lwidth: parent.lw; value: cpu.dfc; visible: !root.below10 }
                SiHex32 { l: qsTr("D5"); lwidth: 20; value: parent.info.dReg(5) }
                SiHex32 { l: qsTr("A5"); lwidth: 20; value: parent.info.aReg(5) }

                SiHex32 { l: qsTr("CACR"); lwidth: parent.lw; value: cpu.cacr; visible: !root.below20 }
                SiHex32 { l: qsTr("D6"); lwidth: 20; value: parent.info.dReg(6) }
                SiHex32 { l: qsTr("A6"); lwidth: 20; value: parent.info.aReg(6) }

                SiHex32 { l: qsTr("CAAR"); lwidth: parent.lw; value: cpu.caar; visible: !root.below20 }
                SiHex32 { l: qsTr("D7"); lwidth: 20; value: parent.info.dReg(7) }
                SiHex32 { l: qsTr("A7"); lwidth: 20; value: parent.info.aReg(7) }
            }

            RowLayout {

                Layout.topMargin: Style.mediumSpacing
                Layout.alignment: Qt.AlignHCenter
                spacing: Style.mediumSpacing

                FlagCheck { on: cpu.t1; label: root.below20 ? "T" : "T1" }
                FlagCheck { on: cpu.t0; label: "T0"; visible: !root.below20 }
                FlagCheck { on: cpu.s;  label: "S" }
                FlagCheck { on: cpu.m;  label: "M"; visible: !root.below20 }
                FlagCheck { on: cpu.i2; label: "I2" }
                FlagCheck { on: cpu.i1; label: "I1" }
                FlagCheck { on: cpu.i0; label: "I0" }
                FlagCheck { on: cpu.x;  label: "X" }
                FlagCheck { on: cpu.n;  label: "N" }
                FlagCheck { on: cpu.z;  label: "Z" }
                FlagCheck { on: cpu.v;  label: "V" }
                FlagCheck { on: cpu.c;  label: "C" }
            }

            RowLayout {

                Layout.topMargin: Style.smallSpacing
                Layout.alignment: Qt.AlignHCenter
                spacing: Style.largeSpacing

                RowLayout {

                    spacing: Style.mediumSpacing
                    FlagCheck { on: cpu.ipl2; label: "IPL" }
                    FlagCheck { on: cpu.ipl1; label: "" }
                    FlagCheck { on: cpu.ipl0; label: "" }
                }

                RowLayout {

                    spacing: Style.mediumSpacing
                    FlagCheck { on: cpu.fc2; label: "FC" }
                    FlagCheck { on: cpu.fc1; label: "" }
                    FlagCheck { on: cpu.fc0; label: "" }
                }

                FlagCheck { on: controller.info.halt; label: "HLT" }
            }

            VSpacer { }
        }
    }

    Connections {

        target: cpu

        function onCpuChanged() {

            if (cpu.pcRow >= 0) {
                dasmView.listView.positionViewAtIndex(cpu.pcRow, ListView.Contain)
            }
            traceView.listView.positionViewAtEnd()
        }
    }
}
