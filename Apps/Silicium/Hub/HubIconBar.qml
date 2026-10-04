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
import Sulfur

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

        SuButton {

            action: actions.preferences
            symbol: "settings"
            tooltip: qsTr("Open Preferences")
        }

        HSpacer {
        }

        SuButton {

            action: actions.open
            symbol: "folder"
            tooltip: "Open Virtual Machine"
        }

        SuButton {

            action: actions.onboardingToggle
            symbol: "add"
            checkable: true
            checked: HubController.panel == "assistant"
            tooltip: qsTr("New Virtual Machine")
        }

        HSpacer {
        }

        SuSegmentedControl {

            minSegmentWidth: 34
            model: [
                {
                    symbol: "info",
                    enabled: HubController.selected !== "",
                    tooltip: HubController.overlay === "info" ? qsTr("Hide Info") : qsTr("Show Info")
                },
                {
                    phosphor: "clipboard",
                    tooltip: HubController.overlay === "logger" ? qsTr("Close Logger") : qsTr("Open Logger")
                }
            ]
            currentIndex: HubController.overlay === "info" ? 0
                : HubController.overlay === "logger" ? 1 : -1
            onActivated: (index) => (index === 0 ? actions.info : actions.logger).trigger()
        }
    }
}