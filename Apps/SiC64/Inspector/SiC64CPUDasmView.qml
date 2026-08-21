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

SiBox {

    id: root

    required property var cpu
    required property int numBase
    property alias listView: instrList

    title: qsTr("Program")
    spacing: Style.mediumSpacing

    readonly property int markerColW: 20
    readonly property int addrColW: 56
    readonly property int dataColW: 90
    readonly property int instrColW: 200

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

    SiSearchControl {

        controlWidth: 100
        size: Size.small
        base: root.numBase
        Layout.alignment: Qt.AlignRight

        onAccepted: {

            if (!isNaN(value)) cpu.jumpTo(value)
            text = ""
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
                HeaderLabel { text: qsTr("Addr"); Layout.fillWidth: true; Layout.preferredWidth: root.addrColW }
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
                            awesome: breakpoint === 1 ? "circle-pause"
                                : breakpoint === 2 ? "circle-pause"
                                : isPC ? "caret-right" : ""
                            color: isPC ? Palette.accentText
                                : breakpoint === 1 ? Palette.accent
                                : breakpoint === 2 ? Palette.disabled : Palette.primary

                            onClicked: cpu.cycleBreakpoint(addrValue)
                        }

                        Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: isPC ? Palette.accentElevated : Palette.surfaceBorder }
                        Value { Layout.fillWidth: true; Layout.preferredWidth: root.addrColW; text: addr; color: isPC ? Palette.accentText : Palette.primary }
                        Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: isPC ? Palette.accentElevated : Palette.surfaceBorder }
                        Value { Layout.fillWidth: true; Layout.preferredWidth: root.dataColW; text: bytes; color: isPC ? Palette.accentText : Palette.primary }
                        Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: isPC ? Palette.accentElevated : Palette.surfaceBorder }
                        Value { Layout.fillWidth: true; Layout.preferredWidth: root.instrColW; text: instr; color: isPC ? Palette.accentText : Palette.primary }
                    }

                    TapHandler {

                        acceptedButtons: Qt.LeftButton
                        onDoubleTapped: cpu.toggleBreakpoint(addrValue)
                    }
                }
            }
        }
    }
}
