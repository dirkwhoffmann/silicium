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

SiC64InspectorWindow {

    id: root

    title: qsTr("CPU Inspector")
    currentController: controller.cpuController

    readonly property var cpu: controller.cpuController
    // Register / flag / interrupt state comes from the shared info
    // controller; the CPU controller only owns the disassembly, trace and
    // breakpoint/watchpoint lists.
    readonly property var info: controller.info
    readonly property int numBase: (controller.format === 0 || controller.format === 1) ? 16 : 10
    readonly property bool numPadded: controller.format === 1 || controller.format === 3

    // Which page the main stack shows: 0 = Program (dasm + trace side by
    // side), 1 = Debug (breakpoints + watchpoints side by side).
    property int page: 0

    component SiByteViewControl: SiNumberViewControl {

        size: Size.small
        font.weight: 500
        controlWidth: 32
        bits: 8
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

    ColumnLayout {

        anchors.fill: parent
        anchors.margins: Style.mediumSpacing
        spacing: Style.mediumSpacing

        ScrollView {

            id: scrollView

            Layout.fillWidth: true
            Layout.fillHeight: true

            clip: true
            contentWidth: content.implicitWidth

            RowLayout {

                id: content

                // Fill the full viewport height -- unlike the width (which is
                // left to its natural/minimum size so a too-narrow window
                // gets a horizontal scrollbar instead), there's no reason for
                // these panels to ever be shorter than the window.
                height: scrollView.availableHeight
                spacing: Style.largeSpacing

                // The sidebar (Registers/Ports) is narrow and fixed; the
                // stack gets whatever's left, split between its two
                // side-by-side boxes. Freed up by the Program/Debug pages no
                // longer needing to coexist -- previously the disassembly,
                // trace and guard columns all had to share the same row.
                readonly property real sidebarWidth: 260
                readonly property real boxMinWidth: 260
                readonly property real boxWidth: Math.max(boxMinWidth,
                                                           (scrollView.availableWidth - sidebarWidth - spacing * 2) / 2)

                //
                // Program / Debug stack
                //

                Item {

                    Layout.preferredWidth: content.boxWidth * 2 + Style.largeSpacing
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    SiBox {

                        id: stackBox
                        anchors.fill: parent
                        anchors.topMargin: segControl.height / 2
                        spacing: Style.mediumSpacing

                        VSpacer { size: Style.tinySpacing }

                        StackLayout {

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            currentIndex: root.page

                            RowLayout {

                                spacing: Style.largeSpacing

                                SiC64CPUDasmView {

                                    id: dasmView
                                    cpu: root.cpu
                                    numBase: root.numBase
                                    Layout.preferredWidth: content.boxWidth
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                }

                                SiC64CPUTraceView {

                                    id: traceView
                                    cpu: root.cpu
                                    Layout.preferredWidth: content.boxWidth
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                }
                            }

                            RowLayout {

                                spacing: Style.largeSpacing

                                SiC64CPUGuardView {

                                    title: qsTr("Breakpoints")
                                    Layout.preferredWidth: content.boxWidth
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    numBase: root.numBase
                                    model: cpu.breakpoints
                                    onToggle: (nr) => cpu.toggleBreakpointNr(nr)
                                    onRemove: (nr) => cpu.removeBreakpointNr(nr)
                                    onMove: (nr, addr) => cpu.moveBreakpointNr(nr, addr)
                                    onAdd: (addr) => cpu.addBreakpoint(addr)
                                }

                                SiC64CPUGuardView {

                                    title: qsTr("Watchpoints")
                                    Layout.preferredWidth: content.boxWidth
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    numBase: root.numBase
                                    model: cpu.watchpoints
                                    onToggle: (nr) => cpu.toggleWatchpointNr(nr)
                                    onRemove: (nr) => cpu.removeWatchpointNr(nr)
                                    onMove: (nr, addr) => cpu.moveWatchpointNr(nr, addr)
                                    onAdd: (addr) => cpu.addWatchpoint(addr)
                                }
                            }
                        }
                    }

                    SiSegmentedControl {

                        id: segControl
                        anchors.horizontalCenter: stackBox.horizontalCenter
                        anchors.verticalCenter: stackBox.top

                        model: [qsTr("Program"), qsTr("Debug")]
                        segmentWidth: 100
                        currentIndex: root.page
                        onActivated: (index) => root.page = index
                    }
                }

                //
                // Registers, Ports
                //

                ColumnLayout {

                    Layout.preferredWidth: content.sidebarWidth
                    Layout.fillHeight: true
                    spacing: Style.largeSpacing

                    SiBox {

                        title: qsTr("Registers")
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: Style.tinySpacing

                        RowLayout {

                            Layout.fillWidth: true

                            SiByteViewControl { l: qsTr("PC:"); lwidth: grid.lw; bits: 16; controlWidth: 46; value: info.pc }

                            SiText {

                                Layout.columnSpan: 2
                                // visible: info.pcWarning
                                text: qsTr("PC not in Fetch phase!")
                                color: Palette.warning
                                opacity: info.pcWarning ? 1.0 : 0.0
                                font.pixelSize: Style.small
                            }
                        }

                        GridLayout {

                            id: grid
                            Layout.fillWidth: true
                            // Layout.alignment: Qt.AlignHCenter
                            columns: 3
                            columnSpacing: Style.mediumSpacing
                            rowSpacing: Style.smallSpacing

                            readonly property int lw: 28

                            /*
                            SiByteViewControl { l: qsTr("PC:"); lwidth: grid.lw; bits: 16; controlWidth: 46; value: info.pc }

                            SiText {

                                Layout.columnSpan: 2
                                // visible: info.pcWarning
                                text: qsTr("PC not in Fetch phase!")
                                color: Palette.warning
                                opacity: info.pcWarning ? 1.0 : 0.0
                                font.pixelSize: Style.small
                            }

                             */

                            SiByteViewControl { l: qsTr("A:"); lwidth: grid.lw; value: info.a }
                            SiByteViewControl { l: qsTr("X:"); lwidth: grid.lw; value: info.x }
                            SiByteViewControl { l: qsTr("Y:"); lwidth: grid.lw; value: info.y }

                            SiByteViewControl { l: qsTr("SP:"); lwidth: grid.lw; value: info.sp }
                            SiByteViewControl { l: qsTr("PP:"); lwidth: grid.lw; value: info.portReg }
                            SiByteViewControl { l: "↔:"; lwidth: grid.lw; value: info.portDir }

                            Item { }

                            RowLayout {

                                Layout.columnSpan: 3
                                Layout.leftMargin: grid.lw
                                // Layout.alignment: Qt.AlignRight
                                spacing: Style.mediumSpacing

                                FlagCheck { on: info.flagN; label: "N" }
                                FlagCheck { on: info.flagV; label: "V" }
                                FlagCheck { on: info.flagB; label: "B" }
                                FlagCheck { on: info.flagD; label: "D" }
                                FlagCheck { on: info.flagI; label: "I" }
                                FlagCheck { on: info.flagZ; label: "Z" }
                                FlagCheck { on: info.flagC; label: "C" }
                                HSpacer {}
                                FlagCheck { on: info.jammed; label: "JAM" }
                            }
                        }

                        VSpacer { }
                    }

                    SiBox {

                        title: qsTr("Ports")
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: Style.tinySpacing

                        // The IRQ/NMI source breakdown mirrors real C64
                        // wiring: CIA1's IRQ line feeds the CPU's IRQ input,
                        // CIA2's feeds NMI; VICII only raises IRQ, the
                        // keyboard's RESTORE key only raises NMI; the
                        // expansion port can drive either.
                        GridLayout {

                            columns: 4
                            Layout.alignment: Qt.AlignHCenter
                            columnSpacing: Style.mediumSpacing
                            rowSpacing: Style.smallSpacing

                            SiCheckBoxControl { size: Size.small; readOnly: true; checked: info.irq; r: qsTr("IRQ") }
                            SiCheckBoxControl { size: Size.tiny; indent: 2; readOnly: true; checked: info.irqCIA; r: qsTr("CIA 1") }
                            SiCheckBoxControl { size: Size.tiny; indent: 2; readOnly: true; checked: info.irqVIC; r: qsTr("VICII") }
                            SiCheckBoxControl { size: Size.tiny; indent: 2; readOnly: true; checked: info.irqEXP; r: qsTr("EPort") }

                            SiCheckBoxControl { size: Size.small; readOnly: true; checked: info.nmi; r: qsTr("NMI") }
                            SiCheckBoxControl { size: Size.tiny; indent: 2; readOnly: true; checked: info.nmiCIA; r: qsTr("CIA 2") }
                            SiCheckBoxControl { size: Size.tiny; indent: 2; readOnly: true; checked: info.nmiKBD; r: qsTr("Keyboard") }
                            SiCheckBoxControl { size: Size.tiny; indent: 2; readOnly: true; checked: info.nmiEXP; r: qsTr("EPort") }

                            SiCheckBoxControl { size: Size.small; readOnly: true; checked: info.rdy; r: qsTr("RDY") }
                        }

                        VSpacer { }
                    }

                    // Item { Layout.fillHeight: true }
                }
            }
        }
    }

    Connections {

        target: cpu

        function onCpuChanged() {

            if (!controller.isRunning) return

            if (cpu.pcRow >= 0) {
                dasmView.listView.positionViewAtIndex(cpu.pcRow, ListView.Contain)
            }
            traceView.listView.positionViewAtEnd()
        }
    }
}
