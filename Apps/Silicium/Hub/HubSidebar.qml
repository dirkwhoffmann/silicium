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
import Silicium.Preferences
import Silicium.Theme

Item {

    id: root
    height: parent.height

    required property HubSidebarController sidebarController
    required property HubActions actions

    //
    // Connections
    //

    Connections {

        target: HubController

        function onSnapshotSaved(vUUID, sUUID) {

            // Jump to the new snapshot and highlight it
            sidebarController.sidebarModel.expand(vUUID)
            HubController.select(sUUID)
        }
    }

    Connections {

        target: Preferences

        function onGeneralPrefsChanged() {
            sidebarController.refresh()
        }
    }

    Component.onCompleted: {
        sidebarController.expandCategories()
    }

    //
    // Timers (used to classify mouse clicks)
    //

    Timer {
        id: doubleClickTimer
        interval: Qt.styleHints.mouseDoubleClickInterval
        repeat: false
    }

    Timer {
        id: slowClickTimer
        interval: 2000
        repeat: false

        // The item this window was opened for. One timer is shared by every
        // delegate, so without this a click that arms it on one item could be
        // consumed as a rename by another -- reachable whenever something
        // moves the selection on its own (see HubController's snapshotSaved
        // handling), which is not a gesture the user made.
        property string armedFor: ""
    }

    //
    // Main
    //

    Rectangle {

        anchors.fill: parent
        color: Palette.surface
    }

    ColumnLayout {

        anchors.fill: parent
        spacing: 0

        //
        // Icon section
        //

        Pane {

            Layout.fillWidth: true
            background: Rectangle {
                color: Palette.surface
            }
            padding: Style.mediumSpacing

            HubIconBar {

                anchors.fill: parent
                actions: root.actions
            }
        }

        //
        // Virtual Machine Library
        //

        Rectangle {

            id: sidebarRect
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Palette.surface

            HubSidebarDrop {

            }

            ListView {

                id: treeView
                anchors.fill: parent
                anchors.topMargin: Style.smallSpacing
                anchors.bottomMargin: Style.smallSpacing
                anchors.rightMargin: Style.smallSpacing
                anchors.leftMargin: Style.smallSpacing
                spacing: 0
                clip: true

                model: sidebarDelegateModel

                remove: Transition {
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; to: 0; duration: 200; easing.type: Easing.Linear }
                        NumberAnimation { property: "height"; to: 0; duration: 400; easing.type: Easing.Linear }
                    }
                }

                removeDisplaced: Transition {
                    NumberAnimation { property: "y"; duration: 400; easing.type: Easing.Linear }
                }
            }
        }

        DelegateModel {

            id: sidebarDelegateModel

            model: sidebarController.sidebarModel

            // 2. Define your filtering/sorting groups
            groups: [

                DelegateModelGroup {

                    id: visibleItems
                    name: "visible"
                    includeByDefault: true // Start with everything visible initially
                }
            ]

            // 3. Define the actual visual delegate
            delegate: HubSidebarDelegate { }
        }

        //
        // Info section
        //

        HubDebugInfo {

            visible: false // Preferences.developerMode
        }

        HubVersionInfo {

        }
    }
}