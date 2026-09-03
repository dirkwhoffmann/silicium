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
import Silicium.Theme

// Port of vAmiga's own InstrTableView.swift -- the 256-entry disassembly
// window (see SiAmCPUController::disassembleWindow()), plus the Search
// field and the Syntax/CPU-revision disassembler pickers CPUPanel.swift
// keeps right beside it (cpuGotoAction/cpuSyntaxAction/cpuDasmRevAction).
SiBox {

    id: root

    required property var cpu
    required property var cc
    required property int numBase
    property alias listView: instrList

    title: qsTr("Program")
    spacing: Style.mediumSpacing

    readonly property int markerColW: 20
    readonly property int addrColW: 70
    readonly property int dataColW: 110
    readonly property int instrColW: 220

    readonly property var syntaxNames: [qsTr("Motorola"), qsTr("Motorola (MIT)"), qsTr("GNU"), qsTr("GNU (MIT)"), qsTr("Musashi")]
    readonly property var revisionNames: ["68000", "68010", "68EC020", "68020", "68EC030", "68030", "68EC040", "68LC040", "68040"]

    component Value: SiLabel {

        size: Size.small
        font.weight: 500
        topPadding: 1
        bottomPadding: 1
        font.family: Fonts.mono
        elide: Text.ElideRight
    }

    component HeaderLabel: SiLabel {

        topPadding: 2
        bottomPadding: 2
        font.weight: 500
        elide: Text.ElideRight
    }

    //
    // Controls
    //

    RowLayout {

        Layout.fillWidth: true
        spacing: Style.smallSpacing

        SiSearchControl {

            controlWidth: 100
            size: Size.small
            base: root.numBase
            onAccepted: {
                if (!isNaN(value)) cpu.jumpTo(value)
                text = ""
            }
        }

        HSpacer { }

        SiLabel { text: qsTr("Syntax:") }

        SiComboBoxControl {

            size: Size.small
            model: root.syntaxNames
            currentIndex: cc.CPU_DASM_SYNTAX
            onCurrentIndexChanged: cc.CPU_DASM_SYNTAX = currentIndex
        }

        SiComboBoxControl {

            size: Size.small
            model: root.revisionNames
            currentIndex: cc.CPU_DASM_REVISION
            onCurrentIndexChanged: cc.CPU_DASM_REVISION = currentIndex
        }
    }

    //
    // Data View
    //

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

                Layout.leftMargin: Style.smallSpacing
                Layout.rightMargin: Style.smallSpacing
                Layout.fillWidth: true
                spacing: Style.smallSpacing
                HeaderLabel { text: ""; Layout.preferredWidth: root.markerColW }
                Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 24; color: Palette.surfaceBorder }
                HeaderLabel { text: qsTr("Address"); Layout.fillWidth: true; Layout.preferredWidth: root.addrColW }
                Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 24; color: Palette.surfaceBorder }
                HeaderLabel { text: qsTr("Data"); Layout.fillWidth: true; Layout.preferredWidth: root.dataColW }
                Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 24; color: Palette.surfaceBorder }
                HeaderLabel { text: qsTr("Instruction"); Layout.fillWidth: true; Layout.preferredWidth: root.instrColW }
            }

            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Palette.surfaceBorder }

            ListView {

                id: instrList
                Layout.leftMargin: Style.smallSpacing
                Layout.rightMargin: Style.smallSpacing
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: cpu.instructions

                delegate: Rectangle {

                    id: instrDelegate

                    required property int index
                    required property int addrValue
                    required property string addr
                    required property string bytes
                    required property string instr
                    required property int breakpoint
                    required property bool isPC

                    width: ListView.view.width
                    implicitHeight: instrRow.implicitHeight
                    color: isPC ? Palette.accent
                        : index % 2 === 0 ? Palette.control.lighter(1.025) : Palette.control.darker(1.025)
                    radius: isPC ? Style.radius : 0

                    RowLayout {

                        id: instrRow
                        width: parent.width
                        spacing: Style.smallSpacing

                        SiSymbol {

                            Layout.preferredWidth: root.markerColW
                            Layout.alignment: Qt.AlignVCenter
                            enabled: true
                            size: Size.tiny
                            awesome: instrDelegate.breakpoint === 1 ? "circle-pause"
                                : instrDelegate.breakpoint === 2 ? "circle-pause"
                                : instrDelegate.isPC ? "caret-right" : ""
                            color: instrDelegate.isPC ? Palette.accentText
                                : instrDelegate.breakpoint === 1 ? Palette.accent
                                : instrDelegate.breakpoint === 2 ? Palette.disabled : Palette.primary

                            onClicked: cpu.cycleBreakpoint(instrDelegate.addrValue)
                        }

                        Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: instrDelegate.isPC ? Palette.accentElevated : Palette.surfaceBorder }
                        Value { Layout.fillWidth: true; Layout.preferredWidth: root.addrColW; text: instrDelegate.addr; color: instrDelegate.isPC ? Palette.accentText : Palette.primary }
                        Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: instrDelegate.isPC ? Palette.accentElevated : Palette.surfaceBorder }
                        Value { Layout.fillWidth: true; Layout.preferredWidth: root.dataColW; text: instrDelegate.bytes; color: instrDelegate.isPC ? Palette.accentText : Palette.primary }
                        Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: instrDelegate.isPC ? Palette.accentElevated : Palette.surfaceBorder }
                        Value { Layout.fillWidth: true; Layout.preferredWidth: root.instrColW; text: instrDelegate.instr; color: instrDelegate.isPC ? Palette.accentText : Palette.primary }
                    }

                    TapHandler {

                        acceptedButtons: Qt.LeftButton
                        onDoubleTapped: cpu.toggleBreakpoint(instrDelegate.addrValue)
                    }
                }
            }
        }
    }
}
