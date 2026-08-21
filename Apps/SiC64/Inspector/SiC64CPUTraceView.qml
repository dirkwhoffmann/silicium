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
    property alias listView: traceList

    title: qsTr("Trace")
    spacing: Style.mediumSpacing

    // Column widths, shared between the header row and the delegate row so
    // they always stay aligned.
    readonly property int addrColW: 56
    readonly property int flagsColW: 90
    readonly property int instrColW: 200

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

    //
    // Controls
    //

    RowLayout {

        Layout.fillWidth: true
        HSpacer { }

        SiButton {

            size: Size.small
            text: qsTr("Clear")
            onClicked: cpu.clearTrace()
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
                HeaderLabel { text: qsTr("Addr"); Layout.fillWidth: true; Layout.preferredWidth: root.addrColW }
                Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 26; color: Palette.surfaceBorder }
                HeaderLabel { text: qsTr("Flags"); Layout.fillWidth: true; Layout.preferredWidth: root.flagsColW }
                Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 26; color: Palette.surfaceBorder }
                HeaderLabel { text: qsTr("Instruction"); Layout.fillWidth: true; Layout.preferredWidth: root.instrColW }
            }

            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Palette.surfaceBorder }

            ListView {

                id: traceList
                Layout.leftMargin: Style.smallSpacing
                Layout.rightMargin: Style.smallSpacing
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: cpu.trace

                delegate: Rectangle {

                    width: ListView.view.width
                    implicitHeight: traceRow.implicitHeight
                    color: index % 2 === 0 ? Palette.control.lighter(1.025) : Palette.control.darker(1.025)

                    RowLayout {

                        id: traceRow
                        width: parent.width
                        spacing: Style.smallSpacing

                        Value { Layout.fillWidth: true; Layout.preferredWidth: root.addrColW; text: addr }
                        Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: Palette.surfaceBorder }
                        Value { Layout.fillWidth: true; Layout.preferredWidth: root.flagsColW; text: flags }
                        Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: Palette.surfaceBorder }
                        Value { Layout.fillWidth: true; Layout.preferredWidth: root.instrColW; text: instr }
                    }

                    // Jump the disassembler view to the address this trace
                    // entry was fetched from.
                    TapHandler {
                        onTapped: cpu.jumpTo(addrValue)
                    }
                }
            }
        }
    }
}
