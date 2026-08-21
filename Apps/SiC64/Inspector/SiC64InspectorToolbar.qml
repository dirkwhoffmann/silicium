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

ToolBar {

    id: root

    required property C64Controller controller
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

            NavBarGroup {

                NavTextButton {

                    action: root.actions.pause
                    symbol: root.controller.isPaused ? "play_circle" : "pause_circle"
                }
            }

            NavBarGroup {

                NavTextButton {

                    action: root.actions.stepInto
                    symbol: "step_into"
                }

                NavDivider {
                }

                NavTextButton {

                    action: root.actions.stepOver
                    symbol: "step_over"
                }
            }

            NavBarGroup {

                NavTextButton {

                    action: root.actions.stepCycle
                    symbol: "vital_signs"
                }

                NavDivider {
                }

                NavTextButton {

                    action: root.actions.finishLine
                    symbol: "text_select_move_down"
                    rotate: -90
                }

                NavDivider {
                }

                NavTextButton {

                    action: root.actions.finishFrame
                    symbol: "text_select_move_down"
                }
            }

            HSpacer { }

            Rectangle {

                Layout.preferredWidth: 128
                Layout.preferredHeight: 26
                color: Palette.control
                border.width: 1
                border.color: Palette.controlBorder
                radius: 12

                SiText {

                    anchors.centerIn: parent
                    text: root.inspectorController.beamPosition
                    font.family: Fonts.mono
                    Layout.preferredWidth: 110
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            NavBarGroup {

                NavTextButton {

                    id: formatButton
                    symbol: "list"
                    SiToolTip {
                        text: "Number Format"
                    }

                    onClicked: formatMenu.open()

                    SiMenu {

                        id: formatMenu
                        y: formatButton.height

                        SiMenuItem {
                            action: root.actions.formatHex
                        }
                        SiMenuItem {
                            action: root.actions.formatHexPadded
                        }
                        SiMenuItem {
                            action: root.actions.formatDecimal
                        }
                        SiMenuItem {
                            action: root.actions.formatDecimalPadded
                        }
                    }
                }
            }
        }
    }
}
