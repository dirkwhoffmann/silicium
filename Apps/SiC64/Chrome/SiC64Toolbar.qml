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
import Silicium.Assets
import Silicium.Controllers
import Silicium.Preferences
import Silicium.Theme

//
// Combined toolbar / menubar
//

ToolBar {

    id: root

    required property C64Controller c64

    // Emitted when a menu item wants to open the Configurator on a specific page
    signal openConfigurator(int page)

    // Emitted by the C64 menu's "About" item
    signal openAbout()

    // The owning window supplies its single "actions" property (see
    // SiC64Window), which the toolbar buttons drive via window.actions.reset,
    // window.actions.pause, window.actions.config, etc. Passing the window
    // collapses what used to be a dozen individual Action properties into a
    // single injection point.
    required property SiC64Window window

    // Reflects the current visibility of the toolbar (which now includes the
    // menu row) and the status bar, so the View menu's checkable items can
    // show the right state. The window owns the actual visibility and
    // toggles it in response to the signals below.
    property bool toolbarVisible: true
    property bool statusBarVisible: true

    signal toggleToolbar()
    signal toggleStatusBar()

    // Compact-menu mode: Only one row (menu or icons) is shown at a time,
    // switched via the burger button embedded in each row.
    property bool compactMenu: false
    property bool menuRevealed: false
    onCompactMenuChanged: menuRevealed = false

    // Auto-hide (see Preferences.autoHideToolbar): the row content and
    // background fade in as soon as the mouse enters the toolbar area, and
    // fade out a short delay after it leaves (so briefly crossing the strip
    // doesn't cause flicker). Guarding every use of contentHidden with the
    // preference means turning it off always shows the toolbar, with no
    // extra reset logic.
    readonly property bool autoHideActive: Preferences.autoHideToolbar
    property bool revealed: true
    readonly property bool contentHidden: autoHideActive && !revealed

    // toolbarVisible is the single switch for the whole header: when false,
    // neither row shows. When true, both rows show in normal mode; in
    // compact mode they still alternate via menuRevealed.
    readonly property bool showMenu: root.toolbarVisible && (!root.compactMenu || root.menuRevealed)
    readonly property bool showToolbar: root.toolbarVisible && !(root.compactMenu && root.menuRevealed)
    readonly property bool showAny: showMenu || showToolbar

    topPadding: 0
    bottomPadding: 0
    leftPadding: 0
    rightPadding: 0

    height: (showMenu ? 28 : 0) + (showToolbar ? 28 : 0) + (showAny ? 1 : 0)

    background: Rectangle {

        color: Palette.toolbar
        opacity: root.contentHidden ? 0 : 1

        Behavior on opacity {
            NumberAnimation { duration: 300 }
        }

        Rectangle {

            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            height: 1
            color: Palette.toolbarBorder
        }
    }

    contentItem: ColumnLayout {

        // contentItem itself always stays visible/enabled -- only individual
        // rows below fade in and out -- so a HoverHandler placed directly
        // here (tracking the whole toolbar area) never sits behind an
        // invisible ancestor and always keeps working.
        spacing: 0

        HoverHandler {

            id: toolbarHover
            onHoveredChanged: if (hovered) root.revealed = true
        }

        // Delays fading out after the mouse leaves, so briefly crossing the
        // strip doesn't cause flicker. Declarative running (rather than
        // start()/stop() on the leave event) so it's correctly armed from
        // the very first frame too -- covers the case where the mouse never
        // enters the toolbar at all after launch.
        Timer {

            id: hideDelayTimer
            interval: 800
            running: root.autoHideActive && !toolbarHover.hovered && root.revealed
            onTriggered: root.revealed = false
        }

        RowLayout {

            Layout.fillWidth: true
            Layout.preferredHeight: 28
            Layout.leftMargin: 0 // Style.smallSpacing
            Layout.rightMargin: 0 // Style.smallSpacing
            visible: root.showMenu && opacity > 0
            opacity: root.contentHidden ? 0 : 1
            spacing: 0 // Style.tinySpacing

            Behavior on opacity {
                NumberAnimation { duration: 300 }
            }

            NavTextButtonFlat {

                visible: root.compactMenu
                // symbol: "menu"
                // awesome: "bars"
                phosphor: "list"
                text: qsTr("Show Toolbar")
                // checkable: true
                // checked: root.compactMenu
                onClicked: root.menuRevealed = false
            }

            NavDivider {

                visible: root.compactMenu
            }

            SiC64Menu {

                Layout.fillWidth: true
                // Layout.fillHeight: true
                Layout.alignment: Qt.AlignVCenter
                c64: root.c64
                window: root.window
                onOpenConfigurator: (page) => root.openConfigurator(page)
                onOpenAbout: root.openAbout()

                toolbarVisible: root.toolbarVisible
                statusBarVisible: root.statusBarVisible

                onToggleToolbar: root.toggleToolbar()
                onToggleStatusBar: root.toggleStatusBar()
            }
        }

        RowLayout {

            Layout.fillWidth: true
            Layout.preferredHeight: 28
            Layout.leftMargin: 0 // Style.smallSpacing
            Layout.rightMargin: 0 // Style.smallSpacing
            visible: root.showToolbar && opacity > 0
            opacity: root.contentHidden ? 0 : 1
            spacing: 0 // Style.tinySpacing

            Behavior on opacity {
                NumberAnimation { duration: 300 }
            }

            NavTextButtonFlat {

                visible: root.compactMenu
                // symbol: "menu"
                // awesome: "bars"
                phosphor: "list"
                text: qsTr("Show Menu")
                onClicked: root.menuRevealed = true
            }

            NavDivider {

                visible: root.compactMenu
            }

            NavTextButtonFlat {

                action: root.window.actions.config
                // symbol: "settings"
                // awesome: "gear"
                phosphor: "gear"
            }

            NavDivider {}

            NavTextButtonFlat {

                id: inspectButton
                // symbol: "search"
                // awesome: "magnifying-glass"
                phosphor: "magnifying-glass"
                text: qsTr("Inspector")
                onClicked: inspectMenu.open()

                SiMenu {

                    id: inspectMenu
                    y: inspectButton.height

                    SiMenuItem {
                        action: root.window.actions.openCPUInspector
                    }
                    SiMenuItem {
                        action: root.window.actions.openMemoryInspector
                    }
                    SiMenuItem {
                        action: root.window.actions.openBusInspector
                    }
                    SiMenuItem {
                        action: root.window.actions.openCIAInspector
                    }
                    SiMenuItem {
                        action: root.window.actions.openVICInspector
                    }
                    SiMenuItem {
                        action: root.window.actions.openSIDInspector
                    }
                    SiMenuItem {
                        action: root.window.actions.openEventsInspector
                    }
                }
            }

            NavDivider {}

            NavTextButtonFlat {

                action: root.window.actions.retroShell
                phosphor: "terminal-window"
                checkable: true
                checked: root.c64.retroShell
            }

            NavDivider {}

            NavTextButtonFlat {

                action: root.window.actions.logger
                phosphor: "clipboard"
                checkable: true
                checked: root.window.actions.logger.isOpen
            }

            NavDivider {}

            HSpacer {}

            NavDivider {}

            NavTextButtonFlat {
                phosphor: "database"
                action: root.window.actions.saveWorkspace
            }

            NavDivider {}

            NavTextButtonFlat {
                phosphor: "download-simple"
                action: root.window.actions.saveSnapshot
            }

            NavDivider {}

            NavTextButtonFlat {
                phosphor: "upload-simple"
                action: root.window.actions.loadSnapshot
            }

            NavDivider {}

            HSpacer {}

            NavDivider {}

            DeviceSelectorFlat {

                id: port0Selector
                port: "Control Port 1"
                deviceModel: AppController.inputManager.deviceList
                currentIndex: AppController.inputManager.port0
                onDeviceSelected: (index) => AppController.inputManager.port0 = index
            }

            NavDivider {}

            DeviceSelectorFlat {

                id: port1Selector
                port: "Control Port 2"
                deviceModel: AppController.inputManager.deviceList
                currentIndex: AppController.inputManager.port1
                onDeviceSelected: (index) => AppController.inputManager.port1 = index
            }

            NavDivider {}

            HSpacer {}

            NavDivider {}

            NavTextButtonFlat {
                phosphor: "keyboard"
                action: root.window.actions.keyboard
                checkable: true
                checked: root.window.actions.keyboard.isOpen
            }

            NavDivider {}

            HSpacer {}

            NavDivider {}

            NavTextButtonFlat {
                visible: Preferences.developerMode
                phosphor: "bug-beetle"
                action: root.window.actions.debug
                checkable: true
                checked: root.c64.debugPanel
            }

            NavDivider {}

            NavTextButtonFlat {
                phosphor: root.c64.isPaused ? "play-circle" : "pause-circle"
                action: root.window.actions.pause
            }

            NavDivider {}

            NavTextButtonFlat {
                phosphor: "arrows-clockwise"
                action: root.window.actions.reset
            }

            NavDivider {}

            NavTextButtonFlat {
                phosphor: "power"
                action: root.window.actions.power
            }
        }
    }
}
