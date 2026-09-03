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

// Port of SiC64InspectorToolbar.qml, shared by every panel behind
// SiAmInspectorWindow's sidebar (see that file). Now that SiAmActions
// exists, this forwards its buttons to it (root.actions.pause, ...) the
// same way SiC64's toolbar does, instead of calling SiAmController
// directly. The beam-position readout is wired the same way SiC64's is:
// inspectorController.beamPosition comes from
// SiAmInspectorController::refresh() sampling AmigaInfo's frame/vpos/hpos
// through SiAmInfoController.

ToolBar {

    id: root

    required property SiAmController amiga
    required property SiAmActions actions

    // Untyped: SiAmInspectorController isn't registered as a QML type
    // (unlike SiC64InspectorController), matching how SiAmiga's other
    // subcontrollers (e.g. SiAmKeyboardController) are passed around as
    // plain 'var' -- see SiAmKeyboardPanel.qml's 'kc' property.
    required property var inspectorController

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
                    symbol: root.amiga.isPaused ? "play_circle" : "pause_circle"
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
