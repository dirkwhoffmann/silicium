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

// Port of SiC64InspectorToolbar.qml. SiC64 gives each panel its own
// top-level window, picked from a dropdown on the main toolbar's Inspector
// button. SiAmiga instead hosts every panel in one window (see
// SiAmInspectorWindow.qml), so the equivalent picker lives here instead --
// the panel combo box below replaces that former sidebar, letting this one
// toolbar (rather than the main window's toolbar) select which panel the
// window's StackLayout shows. Now that SiAmActions exists, this forwards
// its buttons to it (root.actions.pause, ...) the same way SiC64's toolbar
// does, instead of calling SiAmController directly. The beam-position
// readout is wired the same way SiC64's is: inspectorController.beamPosition
// comes from SiAmInspectorController::refresh() sampling AmigaInfo's
// frame/vpos/hpos through SiAmInfoController.

ToolBar {

    id: root

    required property SiAmController amiga
    required property SiAmActions actions

    // Untyped: SiAmInspectorController isn't registered as a QML type
    // (unlike SiC64InspectorController), matching how SiAmiga's other
    // subcontrollers (e.g. SiAmKeyboardController) are passed around as
    // plain 'var' -- see SiAmKeyboardPanel.qml's 'kc' property.
    required property var inspectorController

    // Selected page. Must match the order of panelModel below and of
    // SiAmInspectorWindow's Page enum / StackLayout children.
    property int currentIndex: 0

    // Same name/symbol pairs the old sidebar ListView used.
    readonly property var panelModel: [
        {name: "CPU", symbol: "memory"},
        {name: "Bus", symbol: "cable"},
        {name: "CIA", symbol: "developer_board"},
        {name: "Memory", symbol: "memory_alt"},
        {name: "Agnus", symbol: "hub"},
        {name: "Copper", symbol: "content_copy"},
        {name: "Blitter", symbol: "bolt"},
        {name: "Paula", symbol: "music_note_2"},
        {name: "Denise", symbol: "monitor"},
        {name: "Ports", symbol: "usb"},
        {name: "Events", symbol: "schedule"},
    ]

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

            SiComboBox {

                id: panelCombo

                Layout.preferredWidth: 160
                model: root.panelModel
                textRole: "name"
                iconRole: "symbol"
                currentIndex: root.currentIndex
                onCurrentIndexChanged: root.currentIndex = currentIndex
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
