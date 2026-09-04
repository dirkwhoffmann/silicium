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

// Port of SiC64EventsPanel.qml. Its own top-level window (see
// SiAmInspectorWindow.qml), same as SiC64's per-panel inspector windows.
//
// The progress-counter row is reshaped for the Amiga's own event scheduler
// rather than the C64's. C64Info's four counters (CPU/VICII/CIA1/CIA2) are
// each a single already-scaled cycle count; vAmiga's SiAmEventController
// instead mirrors vAmiga's own GUI/Inspector/EventPanel.swift, exposing raw
// master-cycle counts for CPU/Agnus/CIA A/CIA B *and* each one's converted
// pace (CPU cycles, DMA cycles, CIA cycles) -- see that controller's class
// comment for the exact divisors. So each box here shows two value/unit
// pairs instead of C64's one, and Agnus (the DMA controller whose dmaClock
// is being tracked) takes VICII's box, since there's no frame-progress
// counter in this row on the Amiga side.
SiAmInspectorWindow {

    id: root

    title: qsTr("Events Inspector")
    currentController: controller.eventController

    readonly property var ec: controller.eventController

    ColumnLayout {

        anchors.fill: parent
        anchors.margins: Style.largeSpacing
        spacing: Style.largeSpacing

        //
        // Progress counters
        //

        RowLayout {

            spacing: Style.mediumSpacing

            component ProgressBox : SiBox {

                default property alias content: grid.data

                Layout.fillWidth: true
                // Narrower than SiC64EventsPanel's 260 -- four boxes have to
                // share this window's content area alongside the sidebar,
                // where SiC64's four fill a whole window with no sidebar.
                Layout.preferredWidth: 155
                spacing: Style.mediumSpacing
                color: Palette.control
                borderColor: Palette.controlBorder

                GridLayout {

                    id: grid
                    columns: 2
                    columnSpacing: Style.smallSpacing
                    Layout.alignment: Qt.AlignCenter
                }
            }

            ProgressBox {

                title: qsTr("CPU Progress")
                SiText { text: ec.cpuProgress; font.family: Fonts.mono }
                SiText { text: qsTr("Master Cycles") }
                SiText { text: ec.cpuProgress2; font.family: Fonts.mono }
                SiText { text: qsTr("CPU Cycles") }
            }

            ProgressBox {

                title: qsTr("Agnus Progress")
                SiText { text: ec.agnusProgress; font.family: Fonts.mono }
                SiText { text: qsTr("Master Cycles") }
                SiText { text: ec.agnusProgress2; font.family: Fonts.mono }
                SiText { text: qsTr("DMA Cycles") }
            }

            ProgressBox {

                title: qsTr("CIA A Progress")
                SiText { text: ec.ciaAProgress; font.family: Fonts.mono }
                SiText { text: qsTr("Master Cycles") }
                SiText { text: ec.ciaAProgress2; font.family: Fonts.mono }
                SiText { text: qsTr("CIA Cycles") }
            }

            ProgressBox {

                title: qsTr("CIA B Progress")
                SiText { text: ec.ciaBProgress; font.family: Fonts.mono }
                SiText { text: qsTr("Master Cycles") }
                SiText { text: ec.ciaBProgress2; font.family: Fonts.mono }
                SiText { text: qsTr("CIA Cycles") }
            }
        }

        //
        // Event table
        //

        QtObject {

            id: widths
            readonly property int slot: 70
            readonly property int event: 150
            readonly property int trigger: 110
            readonly property int frame: 110
            readonly property int vpos: 70
            readonly property int hpos: 70
        }

        component HeaderLabel: SiLabel {

            topPadding: 2
            bottomPadding: 2
            font.bold: false
            elide: Text.ElideRight
        }

        component Cell: SiLabel {

            property bool pending: true

            topPadding: 4
            bottomPadding: 4
            color: pending ? Palette.primary : Palette.tertiary
            elide: Text.ElideRight
        }

        Rectangle {

            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Palette.control
            border.color: Palette.controlBorder
            border.width: 1
            radius: Style.radius

            ColumnLayout {

                anchors.fill: parent
                anchors.margins: Style.smallSpacing
                spacing: 0

                RowLayout {

                    Layout.fillWidth: true
                    spacing: Style.smallSpacing

                    HeaderLabel { text: "Slot"; Layout.preferredWidth: widths.slot; Layout.leftMargin: Style.smallSpacing }
                    Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 24; color: Palette.surfaceBorder }
                    HeaderLabel { text: "Event"; Layout.preferredWidth: widths.event }
                    Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 24; color: Palette.surfaceBorder }
                    HeaderLabel { text: "Trigger"; Layout.preferredWidth: widths.trigger }
                    Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 24; color: Palette.surfaceBorder }
                    HeaderLabel { text: "Frame"; Layout.preferredWidth: widths.frame }
                    Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 24; color: Palette.surfaceBorder }
                    HeaderLabel { text: "Vpos"; Layout.preferredWidth: widths.vpos }
                    Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 24; color: Palette.surfaceBorder }
                    HeaderLabel { text: "Hpos"; Layout.preferredWidth: widths.hpos }
                    Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 24; color: Palette.surfaceBorder }
                    HeaderLabel { text: "Remark"; Layout.fillWidth: true; Layout.rightMargin: Style.smallSpacing }
                }

                Rectangle {

                    Layout.fillWidth: true
                    height: 1
                    color: Palette.surfaceBorder
                }

                ListView {

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: ec.events

                    delegate: Rectangle {

                        width: ListView.view.width
                        implicitHeight: rowLayout.implicitHeight
                        color: model.due ? Qt.alpha(Palette.tint, 0.75)
                            : index % 2 === 0 ? Palette.control.lighter(1.025) : Palette.control.darker(1.025)

                        RowLayout {

                            id: rowLayout
                            width: parent.width
                            spacing: Style.smallSpacing

                            Cell { text: slot; pending: model.pending; Layout.preferredWidth: widths.slot; Layout.leftMargin: Style.smallSpacing }
                            Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: Palette.surfaceBorder }
                            Cell { text: event; pending: model.pending; Layout.preferredWidth: widths.event }
                            Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: Palette.surfaceBorder }
                            Cell { text: trigger; pending: model.pending; Layout.preferredWidth: widths.trigger }
                            Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: Palette.surfaceBorder }
                            Cell { text: frame; pending: model.pending; Layout.preferredWidth: widths.frame }
                            Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: Palette.surfaceBorder }
                            Cell { text: vpos; pending: model.pending; Layout.preferredWidth: widths.vpos }
                            Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: Palette.surfaceBorder }
                            Cell { text: hpos; pending: model.pending; Layout.preferredWidth: widths.hpos }
                            Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: Palette.surfaceBorder }
                            Cell { text: remark; pending: model.pending; Layout.fillWidth: true; Layout.rightMargin: Style.smallSpacing }
                        }
                    }
                }
            }
        }
    }
}
