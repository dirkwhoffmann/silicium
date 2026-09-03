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

// Port of vAmiga's own GUI/Inspector/CopperPanel.swift, CopperTableView.swift
// and GuardTableView.swift's CopperBreakTableView -- there is no C64
// counterpart to port from (the Copper is Amiga-only). A plain page inside
// SiAmInspectorWindow's sidebar StackLayout (see that file), not its own
// window; SiAmInspectorWindow.updateActiveController() drives
// controller.copperController.active for it, the same way it already does
// for the other panels. The two disassembly tables and the breakpoint
// table below all reuse SiAmMemoryPanel's plain header-row-plus-ListView
// table style (colored header, alternating row shading, a thin
// Palette.surfaceBorder rule between columns) rather than inventing a new
// look, per the explicit ask.
//
// SiAmCopperController's own class comment covers the real behavioral
// differences from the Swift reference (breakpoint editing simplified to
// tap-to-cycle plus a delete affordance, no inline "type an address" add
// row); this file just lays out three boxes matching vAmiga's own
// Inspector layout: Copper List 1, Copper List 2, and a right column with
// Registers above Breakpoints.
Item {

    id: root

    required property SiAmController controller

    readonly property var copper: controller.copperController
    readonly property var ic: controller.inspectorController
    readonly property int numBase: ic.hex ? 16 : 10
    readonly property bool numPadded: ic.padded

    component SiWordViewControl: SiNumberViewControl {

        size: Size.small
        font.weight: 500
        controlWidth: 56
        bits: 16
        base: root.numBase
        padded: root.numPadded
    }

    // COPPC/COPxLC are 24-bit (a Copper list pointer is a chip-RAM
    // address), unlike CIA's 8/16-bit registers -- see SiAmCIAPanel's own
    // SiTODControl for the same bits:24 pattern.
    component SiLongViewControl: SiNumberViewControl {

        size: Size.small
        font.weight: 500
        controlWidth: 72
        bits: 24
        base: root.numBase
        padded: root.numPadded
    }

    component HeaderLabel: SiLabel {

        topPadding: 2
        bottomPadding: 2
        font.weight: 500
        elide: Text.ElideRight
    }

    component Value: SiLabel {

        size: Size.small
        topPadding: 1
        bottomPadding: 1
        font.family: Fonts.mono
        font.weight: 500
        elide: Text.ElideRight
    }

    // Small breakpoint indicator shared by both Copper lists and the
    // Breakpoints box -- a filled dot for an enabled breakpoint, a hollow
    // ring for a disabled one, nothing otherwise. Mirrors the Swift
    // reference's "⛔"/"⚪" glyphs as a plain drawn shape instead of emoji.
    component BreakDot: Rectangle {

        id: dot

        property int breakState: 0 // 0 = none, 1 = enabled, 2 = disabled

        implicitWidth: 12
        implicitHeight: 12
        radius: width / 2
        color: breakState === 1 ? "#E04040" : "transparent"
        border.width: breakState !== 0 ? 1.5 : 0
        border.color: breakState === 2 ? Palette.tertiary : "#E04040"
    }

    // One Copper list box: Binary/Symbolic toggle, disassembly table,
    // expand/shrink buttons.
    component CopperListBox: SiBox {

        id: listBox

        property alias symbolic: seg.currentIndex
        property var listModel: null
        property int listNr: 1

        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Style.mediumSpacing

        title: listNr === 1 ? qsTr("Copper List 1") : qsTr("Copper List 2")

        ColumnLayout {

            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Style.mediumSpacing

            SiSegmentedControl {

                id: seg
                Layout.alignment: Qt.AlignHCenter
                model: [qsTr("Binary"), qsTr("Symbolic")]
                onActivated: (index) => {
                    if (listNr === 1) copper.symbolic1 = index === 1
                    else copper.symbolic2 = index === 1
                }
            }

            Rectangle {

                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Palette.control
                border.color: Palette.controlBorder
                border.width: 1
                radius: Style.radius
                clip: true

                ColumnLayout {

                    anchors.fill: parent
                    anchors.margins: 1
                    spacing: 0

                    RowLayout {

                        Layout.fillWidth: true
                        spacing: Style.smallSpacing

                        HeaderLabel { Layout.preferredWidth: 24 }
                        HeaderLabel { text: qsTr("Address"); Layout.preferredWidth: 70 }
                        Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 26; color: Palette.surfaceBorder }
                        HeaderLabel { text: qsTr("Instruction"); Layout.fillWidth: true }
                    }

                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Palette.surfaceBorder }

                    ListView {

                        id: listView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        model: listModel

                        delegate: Rectangle {

                            width: ListView.view.width
                            implicitHeight: rowLayout.implicitHeight
                            color: model.current ? Qt.alpha(Palette.tint, 0.75)
                                : index % 2 === 0 ? Palette.control.lighter(1.025) : Palette.control.darker(1.025)

                            RowLayout {

                                id: rowLayout
                                width: parent.width
                                spacing: Style.smallSpacing

                                Item {

                                    Layout.preferredWidth: 24
                                    Layout.fillHeight: true

                                    BreakDot {
                                        anchors.centerIn: parent
                                        breakState: model.breakState
                                    }

                                    TapHandler {
                                        onTapped: listNr === 1 ? copper.toggleBreakpoint1(index) : copper.toggleBreakpoint2(index)
                                    }
                                }

                                Value {
                                    Layout.preferredWidth: 70
                                    text: model.addr
                                    color: model.extra ? Palette.tertiary : Palette.primary
                                }

                                Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: Palette.surfaceBorder }

                                Value {
                                    Layout.fillWidth: true
                                    text: model.instr
                                    color: model.extra ? Palette.tertiary : model.illegal ? "#E0A030" : Palette.primary
                                }
                            }
                        }
                    }
                }
            }

            RowLayout {

                Layout.alignment: Qt.AlignRight
                spacing: Style.smallSpacing

                SiSymbolButton {
                    symbol: "remove"
                    onClicked: listNr === 1 ? copper.shrinkList1() : copper.shrinkList2()
                }
                SiSymbolButton {
                    symbol: "add"
                    onClicked: listNr === 1 ? copper.expandList1() : copper.expandList2()
                }
            }
        }

        Connections {

            target: copper

            function onJumpRequested(list, row) {

                if (list === listNr) listView.positionViewAtIndex(row, ListView.Center)
            }
        }
    }

    RowLayout {

        anchors.fill: parent
        anchors.margins: Style.mediumSpacing
        spacing: Style.mediumSpacing

        CopperListBox {

            listNr: 1
            listModel: copper.list1
            symbolic: copper.symbolic1 ? 1 : 0
        }

        CopperListBox {

            listNr: 2
            listModel: copper.list2
            symbolic: copper.symbolic2 ? 1 : 0
        }

        ColumnLayout {

            Layout.preferredWidth: 260
            Layout.fillHeight: true
            spacing: Style.mediumSpacing

            //
            // Registers
            //

            SiBox {

                title: qsTr("Registers")
                Layout.fillWidth: true
                spacing: Style.tinySpacing

                ColumnLayout {

                    Layout.alignment: Qt.AlignHCenter

                    RowLayout {

                        spacing: Style.smallSpacing

                        SiLongViewControl {
                            l: qsTr("COPPC:")
                            lwidth: 55
                            value: copper.coppc0
                        }

                        SiSymbolButton {
                            symbol: "search"
                            onClicked: copper.jumpToPC()
                        }
                    }

                    RowLayout {

                        spacing: Style.smallSpacing

                        SiLongViewControl { l: qsTr("COPxLC:"); lwidth: 55; value: copper.cop1lc }
                        SiLongViewControl { value: copper.cop2lc }
                    }

                    RowLayout {

                        spacing: Style.smallSpacing

                        SiWordViewControl { l: qsTr("COPxINS:"); lwidth: 55; value: copper.cop1ins }
                        SiWordViewControl { value: copper.cop2ins }
                    }

                    SiCheckBoxControl {

                        size: Size.small
                        indent: 55
                        readOnly: true
                        checked: copper.cdang
                        r: qsTr("CDANG")
                    }
                }
            }

            //
            // Breakpoints
            //

            SiBox {

                title: qsTr("Breakpoints")
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Style.mediumSpacing

                Rectangle {

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: Palette.control
                    border.color: Palette.controlBorder
                    border.width: 1
                    radius: Style.radius
                    clip: true

                    ColumnLayout {

                        anchors.fill: parent
                        anchors.margins: 1
                        spacing: 0

                        RowLayout {

                            Layout.fillWidth: true
                            spacing: Style.smallSpacing

                            HeaderLabel { Layout.preferredWidth: 24 }
                            HeaderLabel { text: qsTr("Address"); Layout.fillWidth: true }
                            HeaderLabel { Layout.preferredWidth: 24 }
                        }

                        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Palette.surfaceBorder }

                        ListView {

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            model: copper.breakpoints

                            delegate: Rectangle {

                                width: ListView.view.width
                                implicitHeight: bpRow.implicitHeight
                                color: index % 2 === 0 ? Palette.control.lighter(1.025) : Palette.control.darker(1.025)

                                RowLayout {

                                    id: bpRow
                                    width: parent.width
                                    spacing: Style.smallSpacing

                                    Item {

                                        Layout.preferredWidth: 24
                                        Layout.fillHeight: true

                                        BreakDot {
                                            anchors.centerIn: parent
                                            breakState: model.enabled ? 1 : 2
                                        }

                                        TapHandler {
                                            onTapped: copper.toggleGuardEnabled(index)
                                        }
                                    }

                                    Value {
                                        Layout.fillWidth: true
                                        text: model.addr
                                    }

                                    SiSymbolButton {

                                        Layout.preferredWidth: 24
                                        symbol: "delete"
                                        onClicked: copper.removeGuard(index)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
