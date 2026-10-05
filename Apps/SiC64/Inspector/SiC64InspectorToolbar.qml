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

ToolBar {

    id: root

    readonly property C64Controller controller: C64Controller
    required property SiC64InspectorController inspectorController

    // The main window's shared action set (SiC64Window.actions) -- buttons
    // below trigger these instead of calling into root.controller directly,
    // so the inspector stays in sync with the main toolbar/menu.
    required property SiC64Actions actions

    topPadding: Style.mediumSpacing
    bottomPadding: Style.mediumSpacing
    leftPadding: Style.mediumSpacing
    rightPadding: Style.mediumSpacing

    implicitHeight: contentRow.implicitHeight + 4 * Style.mediumSpacing

    background: Rectangle {

        color: "transparent"
    }

    Item {

        anchors.fill: parent

        Rectangle {

            anchors.fill: parent
            color: Palette.surface
            radius: Style.radius
        }

        RowLayout {

            id: contentRow
            anchors.fill: parent
            anchors.topMargin: Style.mediumSpacing
            anchors.bottomMargin: Style.mediumSpacing
            anchors.leftMargin: Style.mediumSpacing
            anchors.rightMargin: Style.mediumSpacing
            spacing: Style.smallSpacing

            SuButton {

                action: root.actions.pause
                symbol: root.controller.isPaused ? "play_circle" : "pause_circle"
            }

            SuSegmentedControl {

                minSegmentWidth: 34
                currentIndex: -1   // momentary: nothing stays selected
                model: [
                    { action: root.actions.stepInto, symbol: "step_into" },
                    { action: root.actions.stepOver, symbol: "step_over" }
                ]
            }

            SuSegmentedControl {

                minSegmentWidth: 34
                currentIndex: -1   // momentary: nothing stays selected
                model: [
                    { action: root.actions.stepCycle, symbol: "vital_signs" },
                    { action: root.actions.finishLine, symbol: "text_select_move_down", rotate: -90 },
                    { action: root.actions.finishFrame, symbol: "text_select_move_down" }
                ]
            }

            HSpacer { }

            Rectangle {

                Layout.preferredWidth: 128
                Layout.preferredHeight: 26
                color: Palette.inset
                border.width: 1
                border.color: Palette.insetBorder
                radius: 12

                SuText {

                    anchors.centerIn: parent
                    text: root.inspectorController.beamPosition
                    font.family: Fonts.data
                    Layout.preferredWidth: 110
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            SuButton {

                id: formatButton
                symbol: "list"
                tooltip: "Number Format"

                onClicked: formatMenu.open()

                SuMenu {

                    id: formatMenu
                    y: formatButton.height

                    SuMenuItem {
                        action: root.actions.formatHex
                    }
                    SuMenuItem {
                        action: root.actions.formatHexPadded
                    }
                    SuMenuItem {
                        action: root.actions.formatDecimal
                    }
                    SuMenuItem {
                        action: root.actions.formatDecimalPadded
                    }
                }
            }
        }
    }
}
