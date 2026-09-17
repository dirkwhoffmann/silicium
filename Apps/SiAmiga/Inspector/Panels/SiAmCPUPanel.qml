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

    // SiWord32ViewControl/SiWordViewControl (Apps/Shared/QML/Compounds) hold
    // the structural bits (size/weight/bits/default width) shared with every
    // other panel; this panel only adds the hex/decimal toggle binding local
    // wrappers like this let every usage below stay untouched.
    component SiHex32: SiWord32ViewControl {

        base: root.numBase
        padded: root.numPadded
    }

    component SiHex16: SiWordViewControl {

        controlWidth: 64
        base: root.numBase
        padded: root.numPadded
    }

    // One status-register bit's checkbox (row 0/2 of the Flags grid below).
    // Some SR bits don't exist on every 68k model (T0/M were added in the
    // 68020) and four more are permanently unused padding on every model --
    // 'unused' hides the checkbox but keeps the cell (and its width) so the
    // grid stays aligned column by column.
    component FlagBit: Item {

        property bool on: false
        property bool unused: false

        Layout.preferredWidth: 15
        Layout.preferredHeight: check.implicitHeight
        Layout.alignment: Qt.AlignHCenter

        SiCheckBox {

            id: check
            size: Size.small
            checked: parent.on
            readOnly: true
            visible: !parent.unused
        }
        DebugRect {}
    }

    // The label underneath a FlagBit (or a group of them). Every cell --
    // checkbox or label -- shares the same Layout.preferredWidth, so all 16
    // grid columns come out equally wide regardless of what's in them.
    component FlagLabel: SiText {

        property string label: ""
        property bool unused: false

        Layout.preferredWidth: 15
        Layout.alignment: Qt.AlignHCenter
        horizontalAlignment: Text.AlignHCenter
        text: unused ? "-" : label
        font.pixelSize: Style.tiny
        color: unused ? Palette.disabled : Palette.primary
        DebugRect{}
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
        // Registers / Flags
        //

        ColumnLayout {

            // A ColumnLayout whose only children are SiBoxes/Rectangles has
            // no implicit width of its own (their content sizes independent
            // of it), and Qt Quick Layouts defaults Layout.fillWidth to true
            // for exactly that case -- so without fillWidth:false pinning it
            // down, this column doesn't stay at its preferredWidth, it grabs
            // a share of the RowLayout's left-over space instead, growing
            // well past 300px and squeezing the Program/Trace/Debug stack.
            Layout.preferredWidth: 300
            Layout.fillWidth: false
            Layout.fillHeight: true
            spacing: Style.mediumSpacing

            // All CPU registers as a single, flat two-column grid instead of
            // the previous PC/IRD/IRC row plus a separate 3-column ISP/D/A
            // block -- simpler to read top to bottom, and scrollable (same
            // ScrollView-around-a-Layout trick as SiAmXRayPanel's Channels
            // box) so a 68020's extra MSP/VBR/SFC/DFC/CACR/CAAR rows never
            // force the window taller than it should be. Stretches to fill
            // whatever vertical space the Flags box below doesn't need.
            SiScrollBox {

                title: qsTr("Registers")
                Layout.fillWidth: true
                Layout.fillHeight: true

                GridLayout {

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    columns: 2
                    columnSpacing: Style.mediumSpacing
                    rowSpacing: Style.smallSpacing

                    readonly property int lw: 32
                    readonly property var info: controller.info

                    SiHex32 { l: qsTr("PC"); lwidth: parent.lw; value: controller.info.pc }
                    Item { }

                    SiHex16 { l: qsTr("IRD"); lwidth: parent.lw; value: cpu.ird }
                    SiHex16 { l: qsTr("IRC"); lwidth: parent.lw; value: cpu.irc }
                    SiHex32 { l: qsTr("ISP"); lwidth: parent.lw; value: cpu.isp }
                    SiHex32 { l: qsTr("USP"); lwidth: parent.lw; value: cpu.usp }

                    SiHex32 { l: qsTr("MSP"); lwidth: parent.lw; value: cpu.msp; visible: !root.below20 }
                    Item { visible: !root.below20 }

                    SiHex32 { l: qsTr("VBR"); lwidth: parent.lw; value: cpu.vbr; visible: !root.below10 }
                    SiHex16 { l: qsTr("SFC"); lwidth: parent.lw; value: cpu.sfc; visible: !root.below10 }
                    SiHex16 { l: qsTr("DFC"); lwidth: parent.lw; value: cpu.dfc; visible: !root.below10 }
                    Item { visible: !root.below10 }

                    SiHex32 { l: qsTr("CACR"); lwidth: parent.lw; value: cpu.cacr; visible: !root.below20 }
                    SiHex32 { l: qsTr("CAAR"); lwidth: parent.lw; value: cpu.caar; visible: !root.below20 }

                    SiHex32 { l: qsTr("D0"); lwidth: parent.lw; value: parent.info.dReg(0) }
                    SiHex32 { l: qsTr("D1"); lwidth: parent.lw; value: parent.info.dReg(1) }
                    SiHex32 { l: qsTr("D2"); lwidth: parent.lw; value: parent.info.dReg(2) }
                    SiHex32 { l: qsTr("D3"); lwidth: parent.lw; value: parent.info.dReg(3) }
                    SiHex32 { l: qsTr("D4"); lwidth: parent.lw; value: parent.info.dReg(4) }
                    SiHex32 { l: qsTr("D5"); lwidth: parent.lw; value: parent.info.dReg(5) }
                    SiHex32 { l: qsTr("D6"); lwidth: parent.lw; value: parent.info.dReg(6) }
                    SiHex32 { l: qsTr("D7"); lwidth: parent.lw; value: parent.info.dReg(7) }

                    SiHex32 { l: qsTr("A0"); lwidth: parent.lw; value: parent.info.aReg(0) }
                    SiHex32 { l: qsTr("A1"); lwidth: parent.lw; value: parent.info.aReg(1) }
                    SiHex32 { l: qsTr("A2"); lwidth: parent.lw; value: parent.info.aReg(2) }
                    SiHex32 { l: qsTr("A3"); lwidth: parent.lw; value: parent.info.aReg(3) }
                    SiHex32 { l: qsTr("A4"); lwidth: parent.lw; value: parent.info.aReg(4) }
                    SiHex32 { l: qsTr("A5"); lwidth: parent.lw; value: parent.info.aReg(5) }
                    SiHex32 { l: qsTr("A6"); lwidth: parent.lw; value: parent.info.aReg(6) }
                    SiHex32 { l: qsTr("A7"); lwidth: parent.lw; value: parent.info.aReg(7) }
                }
            }

            //
            // Flags -- the 16-bit status register (MSB to LSB: [T/T1] T0 S
            // M - I2 I1 I0 - - - X N Z V C, the dashes being padding bits
            // that read as 0 on every 68k model), plus the IPL/FC bus pins
            // and the HLT signal below, positioned under the SR columns
            // they relate to. T0 and M only exist from the 68020 onward
            // (root.below20), shown as an always-hidden-checkbox dash
            // otherwise; the four dash-only columns are unused on every
            // model.
            //

            SiBox {

                title: qsTr("Flags")
                Layout.fillWidth: true
                spacing: Style.tinySpacing

                // Four flat rows -- checkboxes, their labels, checkboxes
                // again, their labels again -- instead of a checkbox+label
                // pair per cell: every item (FlagBit or FlagLabel) shares
                // the same Layout.preferredWidth, so all 16 columns come
                // out equally wide and stay aligned across all four rows.
                //
                // Row 0/1: the 16-bit status register (MSB to LSB: [T/T1]
                // T0 S M - I2 I1 I0 - - - X N Z V C, the dashes being
                // padding bits that read as 0 on every 68k model). T0 and M
                // only exist from the 68020 onward (root.below20).
                //
                // Row 2/3: the IPL/FC bus pins and the HLT signal, exactly
                // as wide as the cells above, positioned under the SR
                // columns they relate to -- these exist on every 68k model.
                GridLayout {

                    Layout.alignment: Qt.AlignHCenter
                    columns: 16
                    columnSpacing: Style.tinySpacing
                    rowSpacing: Style.tinySpacing

                    // No explicit Layout.row/Layout.column: with exactly 16
                    // items per row, GridLayout's normal left-to-right,
                    // top-to-bottom flow already lands each one in the
                    // right cell -- an Item filler (same width as
                    // FlagBit/FlagLabel) stands in wherever a column has no
                    // flag of its own.
                    FlagBit { on: cpu.t1 }
                    FlagBit { on: cpu.t0; unused: root.below20 }
                    FlagBit { on: cpu.s }
                    FlagBit { on: cpu.m;  unused: root.below20 }
                    FlagBit { unused: true }
                    FlagBit { on: cpu.i2 }
                    FlagBit { on: cpu.i1 }
                    FlagBit { on: cpu.i0 }
                    FlagBit { unused: true }
                    FlagBit { unused: true }
                    FlagBit { unused: true }
                    FlagBit { on: cpu.x }
                    FlagBit { on: cpu.n }
                    FlagBit { on: cpu.z }
                    FlagBit { on: cpu.v }
                    FlagBit { on: cpu.c }

                    FlagLabel { label: root.below20 ? "T" : "T1" }
                    FlagLabel { label: "T0"; unused: root.below20 }
                    FlagLabel { label: "S" }
                    FlagLabel { label: "M"; unused: root.below20 }
                    FlagLabel { unused: true }
                    FlagLabel { label: "I2" }
                    FlagLabel { label: "I1" }
                    FlagLabel { label: "I0" }
                    FlagLabel { unused: true }
                    FlagLabel { unused: true }
                    FlagLabel { unused: true }
                    FlagLabel { label: "X" }
                    FlagLabel { label: "N" }
                    FlagLabel { label: "Z" }
                    FlagLabel { label: "V" }
                    FlagLabel { label: "C" }

                    Item { Layout.preferredWidth: 15 }
                    Item { Layout.preferredWidth: 15 }
                    Item { Layout.preferredWidth: 15 }
                    Item { Layout.preferredWidth: 15 }
                    Item { Layout.preferredWidth: 15 }
                    FlagBit { on: cpu.ipl2 }
                    FlagBit { on: cpu.ipl1 }
                    FlagBit { on: cpu.ipl0 }
                    Item { Layout.preferredWidth: 15 }
                    Item { Layout.preferredWidth: 15 }
                    Item { Layout.preferredWidth: 15 }
                    FlagBit { on: cpu.fc2 }
                    FlagBit { on: cpu.fc1 }
                    FlagBit { on: cpu.fc0 }
                    Item { Layout.preferredWidth: 15 }
                    FlagBit { on: controller.info.halt }

                    Item { Layout.preferredWidth: 15 }
                    Item { Layout.preferredWidth: 15 }
                    Item { Layout.preferredWidth: 15 }
                    Item { Layout.preferredWidth: 15 }
                    Item { Layout.preferredWidth: 15 }
                    FlagLabel { Layout.columnSpan: 3; label: "IPL" }
                    Item { Layout.preferredWidth: 15 }
                    Item { Layout.preferredWidth: 15 }
                    Item { Layout.preferredWidth: 15 }
                    FlagLabel { Layout.columnSpan: 3; label: "FC" }
                    Item { Layout.preferredWidth: 15 }
                    FlagLabel { label: "HLT" }
                }

                VSpacer { }
            }
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
