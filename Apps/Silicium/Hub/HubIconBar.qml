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
import Silicium.Assets
import Silicium.Preferences
import Silicium.Theme

ToolBar {

    id: root

    required property HubActions actions

    topPadding: Style.mediumSpacing
    bottomPadding: Style.mediumSpacing
    implicitHeight: contentRow.implicitHeight + topPadding + bottomPadding

    background: Rectangle {

        color: Palette.surfaceElevated
        radius: Style.borderRadius
    }

    contentItem: RowLayout {

        id: contentRow
        anchors.fill: parent
        anchors.topMargin: Style.mediumSpacing
        anchors.bottomMargin: Style.mediumSpacing
        anchors.leftMargin: Style.mediumSpacing
        anchors.rightMargin: Style.mediumSpacing
        spacing: Style.smallSpacing

        NavBarGroup {

            // label: "Preferences"

            NavTextButton {

                action: actions.preferences
                symbol: "settings"
                SiToolTip {
                    text: qsTr("Open Preferences")
                }
            }
        }

        HSpacer {
        }

        NavBarGroup {

            // label: "Machines"

            NavTextButton {

                action: actions.open
                symbol: "folder"
                SiToolTip {
                    text: "Open Virtual Machine"
                }
            }
        }

        NavBarGroup {


            NavTextButton {

                action: actions.onboardingToggle
                symbol: "add"
                checkable: true
                checked: HubController.panel == "assistant"
                SiToolTip {
                    text: qsTr("New Virtual Machine")
                }
            }
        }

        HSpacer {
        }

        NavBarGroup {


            NavTextButton {

                id: infoButton
                action: actions.info
                enabled: HubController.selected !== ""
                symbol: "info"
                checkable: true
                checked: HubController.overlay == "info"
                SiToolTip {
                    text: infoButton.checked ? "Hide Info" : "Show Info"
                }
            }

            NavTextButton {

                id: loggerButton
                action: actions.logger
                // symbol: "list_alt"
                phosphor: "clipboard"
                checkable: true
                checked: HubController.overlay == "logger"
                SiToolTip {
                    text: loggerButton.checked ? "Close Logger" : "Open Logger"
                }
            }
        }
    }
}