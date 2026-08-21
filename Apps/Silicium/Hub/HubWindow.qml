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
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Effects
import Silicium.Controllers
import Silicium.Preferences
import Silicium.Theme
import siliciumUI

ApplicationWindow {

    id: root

    readonly property string devTitle: (HubController.vInfo.uuid ?? "No UUID") + " | " + (HubController.sInfo.uuid ?? "No UUID")

    property bool closeApproved: false

    title: Preferences.developerMode ? devTitle : "Silicium Retro Emulator"
    visible: true
    width: 896
    height: 480
    // flags: Qt.Window | Qt.CustomizeWindowHint | Qt.WindowTitleHint

    Palette.appearance: Preferences.appearance
    Palette.theme: Preferences.colorTheme

    //
    // Lifetime
    //

    Component.onCompleted: {

        HubController.start()
    }

    Component.onDestruction: {

        HubController.stop()
    }

    onClosing: function(closeEvent) {

        if (HubController.numOpen === 0 || closeApproved) {

            Qt.quit()

        } else {

            closeEvent.accepted = false
            dialogs.close.open()
        }
    }

    //
    // Controllers
    //

    readonly property HubSidebarController sc: HubController.sidebarController

    OnboardingController {

        id: oc
    }

    //
    // Auxiliary windows
    //

    PrefWindow {

        id: preferences
    }

    //
    // Actions and Dialogs
    //

    HubDialogs {

        id: dialogs
        hc: HubController
        window: root
    }

    HubActions {

        id: actions
        hc: HubController
        sc: HubController.sidebarController
        oc: oc
        preferencesWindow: preferences
        openSvmFileDialog: dialogs.openSvmFile
        cloneDialog: dialogs.clone
    }

    //
    // Main
    //

    SplitView {

        anchors.fill: parent
        spacing: 0

        // background: Rectangle { color: Palette.surface }

        handle: Item {

            implicitWidth: 2

            Row {
                anchors.centerIn: parent
                spacing: 0

                Rectangle {
                    width: 1
                    height: parent.parent.height
                    color: Palette.surface.lighter(1.15)
                }

                Rectangle {
                    width: 1
                    height: parent.parent.height
                    color: Palette.surface.darker(1.15)
                }
            }
        }

        HubSidebar {

            id: mySidebar
            sidebarController: sc
            actions: actions
            SplitView.preferredWidth: 256
            SplitView.minimumWidth: 200
            SplitView.fillHeight: true
        }

        HubCanvas {

            id: canvas
            sidebarController: sc
            onboardingController: oc
        }
    }

    //
    // Experimental
    //

}