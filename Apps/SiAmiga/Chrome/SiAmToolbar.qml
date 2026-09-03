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
// Combined toolbar / menubar. Port of SiC64Toolbar.qml, trimmed the same way
// SiAmMenu.qml was trimmed relative to SiC64Menu.qml: the workspace/snapshot
// save/load buttons aren't wired to anything because that subsystem doesn't
// exist in SiAmiga yet. The Configurator/Inspector/RetroShell/Logger buttons
// are wired, in the same grouping and order as SiC64Toolbar's. There's also
// no per-button "actions" object to inject (see SiC64Toolbar's
// window.actions.* calls) -- buttons call SiAmController (and, for the
// RetroShell/Logger mutual-exclusion, root.window) directly instead, the
// same choice SiAmMenu.qml made.
//

ToolBar {

    id: root

    required property SiAmController amiga

    // Emitted when a menu item wants to open the Configurator on a specific page
    signal openConfigurator(int page)

    // Emitted by the Amiga menu's "About" item
    signal openAbout()

    // Emitted by the Keyboard menu's/button's "Show..." item -- see
    // SiAmMenu.qml and SiAmWindow.qml for why there's no window to show yet.
    signal openKeyboard()

    // Emitted by the Debug menu's/button's "Show Inspector..." item.
    signal openInspector()

    required property SiAmWindow window

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
            Layout.leftMargin: 0
            Layout.rightMargin: 0
            visible: root.showMenu && opacity > 0
            opacity: root.contentHidden ? 0 : 1
            spacing: 0

            Behavior on opacity {
                NumberAnimation { duration: 300 }
            }

            NavTextButtonFlat {

                visible: root.compactMenu
                phosphor: "list"
                text: qsTr("Show Toolbar")
                onClicked: root.menuRevealed = false
            }

            NavDivider {

                visible: root.compactMenu
            }

            SiAmMenu {

                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                amiga: root.amiga
                window: root.window
                onOpenConfigurator: (page) => root.openConfigurator(page)
                onOpenAbout: root.openAbout()
                onOpenKeyboard: root.openKeyboard()
                onOpenInspector: root.openInspector()

                toolbarVisible: root.toolbarVisible
                statusBarVisible: root.statusBarVisible

                onToggleToolbar: root.toggleToolbar()
                onToggleStatusBar: root.toggleStatusBar()
            }
        }

        RowLayout {

            Layout.fillWidth: true
            Layout.preferredHeight: 28
            Layout.leftMargin: 0
            Layout.rightMargin: 0
            visible: root.showToolbar && opacity > 0
            opacity: root.contentHidden ? 0 : 1
            spacing: 0

            Behavior on opacity {
                NumberAnimation { duration: 300 }
            }

            NavTextButtonFlat {

                visible: root.compactMenu
                phosphor: "list"
                text: qsTr("Show Menu")
                onClicked: root.menuRevealed = true
            }

            NavDivider {

                visible: root.compactMenu
            }

            NavTextButtonFlat {

                phosphor: "gear"
                text: qsTr("Settings...")
                onClicked: root.openConfigurator(0)
            }

            NavDivider {}

            NavTextButtonFlat {

                phosphor: "magnifying-glass"
                text: qsTr("Inspector")
                onClicked: root.openInspector()
            }

            NavDivider {}

            NavTextButtonFlat {

                phosphor: "terminal-window"
                text: qsTr("RetroShell")
                checkable: true
                checked: root.amiga.retroShell
                onClicked: {
                    if (root.amiga.retroShell) {
                        root.amiga.retroShell = false
                    } else {
                        root.window.loggerOpen = false
                        root.amiga.retroShell = true
                    }
                }
            }

            NavDivider {}

            NavTextButtonFlat {

                phosphor: "clipboard"
                text: qsTr("Logger")
                checkable: true
                checked: root.window.loggerOpen
                onClicked: {
                    if (root.window.loggerOpen) {
                        root.window.loggerOpen = false
                    } else {
                        root.amiga.retroShell = false
                        root.window.loggerOpen = true
                    }
                }
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
                text: qsTr("Keyboard")
                onClicked: root.openKeyboard()
            }

            NavDivider {}

            HSpacer {}

            NavDivider {}

            NavTextButtonFlat {
                visible: Preferences.developerMode
                phosphor: "bug-beetle"
                text: qsTr("Debug Panel")
                checkable: true
                checked: root.amiga.debugPanel
                onClicked: root.amiga.toggleDebugPanel()
            }

            NavDivider {}

            NavTextButtonFlat {
                phosphor: root.amiga.isPaused ? "play-circle" : "pause-circle"
                text: root.amiga.isPaused ? qsTr("Run") : qsTr("Pause")
                onClicked: root.amiga.runOrPause()
            }

            NavDivider {}

            NavTextButtonFlat {
                phosphor: "arrows-clockwise"
                text: qsTr("Reset")
                onClicked: root.amiga.reset()
            }

            NavDivider {}

            NavTextButtonFlat {
                phosphor: "power"
                text: root.amiga.isPoweredOn ? qsTr("Power Off") : qsTr("Power On")
                onClicked: root.amiga.powerOnOrOff()
            }
        }
    }
}
