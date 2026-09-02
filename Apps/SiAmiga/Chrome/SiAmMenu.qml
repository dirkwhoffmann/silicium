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
// Port of SiC64Menu.qml for the Amiga. The C64 menu becomes "Amiga"; Edit and
// View keep the same items (rewired to SiAmController's equivalents -- see
// that class for stepOver/stepInto/toggleWarp/captureOrReleaseMouse and
// friends, added there for this menu). There's no Datasette or Expansion Port
// on an Amiga, so those menus are dropped; a Keyboard menu is kept, trimmed
// to what vAmiga's own menu offers (MainMenu.xib has no C64-style "type this
// string" shortcuts -- there's no BASIC to type into). The Inspector/
// RetroShell/Logger items from the C64 menu, and the file-dialog-backed
// actions the drive/hard-drive menus trigger (New/Insert/Attach/Export...),
// aren't wired to a window yet -- SiAmWindow.qml has none of that
// infrastructure built out yet, same as the Configurator/About windows.
//

SiMenuBar {

    id: root

    required property SiAmController amiga
    required property SiAmWindow window
    readonly property SiAmConfigController config: amiga.configController

    // Emitted when a menu item wants to open the Configurator on a specific
    // page (see SiAmConfigWindow.Page). The window handles the actual display.
    signal openConfigurator(int page)

    // Emitted by the Amiga menu's "About" item. The window handles the
    // actual display (see SiAmAbout.qml).
    signal openAbout()

    // Emitted by the Keyboard menu's "Show..." item. There's no virtual
    // keyboard window yet -- this is here so the window can wire one up
    // without touching this menu again.
    signal openKeyboard()

    // Reflects the current visibility of the toolbar (which now includes the
    // menu row) and the status bar, so the View menu's checkable items can
    // show the right state. The window owns the actual visibility and
    // toggles it in response to the signals below.
    property bool toolbarVisible: true
    property bool statusBarVisible: true

    signal toggleToolbar()
    signal toggleStatusBar()

    //
    // Amiga menu
    //

    SiMenu {
        title: qsTr("Amiga")

        Action {
            text: qsTr("About")
            onTriggered: openAbout()
        }

        SiMenuSeparator { }

        Action {
            text: qsTr("Settings...")
            shortcut: StandardKey.Preferences
            onTriggered: openConfigurator(0)
        }

        SiMenuSeparator { }

        Action {
            text: qsTr("&Quit");
            shortcut: StandardKey.Quit
            onTriggered: Qt.quit()
        }
    }

    //
    // Edit Menu (unchanged from SiC64Menu, rewired to SiAmController)
    //

    SiMenu {
        title: qsTr("&Edit")

        Action {
            text: amiga.mouseCaptured ? qsTr("Release Mouse") : qsTr("Capture Mouse")
            shortcut: Preferences.mouseHotkey
            onTriggered: amiga.captureOrReleaseMouse()
        }

        SiMenuSeparator { }

        Action {
            text: amiga.isPaused ? qsTr("Run") : qsTr("Pause")
            onTriggered: amiga.runOrPause()
        }
        Action {
            text: qsTr("Hard Reset")
            shortcut: "Ctrl+Meta+R"
            onTriggered: amiga.reset()
        }
        Action {
            text: qsTr("Soft Reset")
            onTriggered: amiga.softReset()
        }
        Action {
            text: amiga.isPoweredOn ? qsTr("Power Off") : qsTr("Power On")
            onTriggered: amiga.powerOnOrOff()
        }
        Action {
            text: qsTr("BRK")
            onTriggered: amiga.brk()
        }

        SiMenuSeparator { }

        Action {
            text: qsTr("Step Over")
            enabled: amiga.isPaused
            onTriggered: amiga.stepOver()
        }
        Action {
            text: qsTr("Step Into")
            enabled: amiga.isPaused
            onTriggered: amiga.stepInto()
        }
        Action {
            text: qsTr("Finish Line")
            enabled: amiga.isPaused
            onTriggered: amiga.finishLine()
        }
        Action {
            text: qsTr("Finish Frame")
            enabled: amiga.isPaused
            onTriggered: amiga.finishFrame()
        }

        SiMenuSeparator { }

        Action {
            text: qsTr("Toggle Warp Mode")
            shortcut: "Meta+Tab"
            onTriggered: amiga.toggleWarp()
        }
    }

    //
    // View Menu (unchanged from SiC64Menu)
    //

    SiMenu {
        title: qsTr("&View")

        Action {
            text: qsTr("Toolbar")
            shortcut: window.toolbarShortcut
            checkable: true
            checked: toolbarVisible
            onTriggered: toggleToolbar()
        }
        Action {
            text: qsTr("Status Bar")
            shortcut: "Ctrl+Alt+B"
            checkable: true
            checked: statusBarVisible
            onTriggered: toggleStatusBar()
        }
    }

    //
    // Floppy Drive Menu (reusable inline component, instantiated for df0..df3)
    //

    component DriveMenu: SiMenu {

        id: driveMenu

        required property int driveNr   // 0..3

        readonly property bool connected: config.driveConnected(driveNr)
        readonly property bool hasDisk: amiga.driveHasDisk(driveNr)
        readonly property bool writeProtected: amiga.driveWriteProtected(driveNr)

        // While disconnected, there's nothing to insert/eject/export for
        // hardware that isn't part of the current setup, so every other item
        // is hidden and only the toggle remains -- mirrors DriveMenu in
        // SiC64Menu.qml. df0 (see updatePeripheralMenus below) is the one
        // drive that stays in the bar regardless of this toggle.
        SiMenuItem {
            text: connected ? qsTr("Disconnect") : qsTr("Connect")
            onTriggered: config.setDriveConnected(driveNr, !connected)
        }

        SiMenuSeparator { visible: connected }

        // No FileDialog wiring yet -- SiAmWindow.qml doesn't have
        // insertDiskAction/newDiskAction/exportDiskAction (see SiC64Window.qml
        // for what these eventually look like).
        SiMenuItem {
            text: qsTr("New")
            visible: connected
            onTriggered: amiga.newDisk(driveNr)
        }
        SiMenuItem {
            text: qsTr("Insert...")
            visible: connected
            onTriggered: window.insertDiskAction(driveNr)
        }
        SiMenuSeparator { visible: connected }
        SiMenuItem {
            text: qsTr("Eject")
            visible: connected
            enabled: hasDisk
            onTriggered: amiga.ejectDisk(driveNr)
        }
        SiMenuItem {
            text: qsTr("Export...")
            visible: connected
            enabled: hasDisk
            onTriggered: window.exportDiskAction(driveNr)
        }
        SiMenuSeparator { visible: connected }
        SiMenuItem {
            text: qsTr("Write Protected")
            checkable: true
            visible: connected
            enabled: hasDisk
            checked: writeProtected
            onTriggered: amiga.toggleWriteProtection(driveNr)
        }
    }

    //
    // Hard Drive Menu (reusable inline component, instantiated for hd0..hd3)
    //
    // Mirrors the Hd0..Hd3 menus in vAmiga's own MainMenu.xib: New..., Attach...,
    // Attach Recent, Detach, Export..., Export To, Properties..., Bootable,
    // Write Protected. "Properties..." (a geometry/format dialog) and
    // "Bootable" (no public getter/setter on HardDriveAPI, only on the core's
    // internal HardDrive class) have no controller-side support yet, so
    // they're left out rather than wired to nothing; "Attach Recent" and
    // "Export To" need a recent-files list this stub doesn't have either
    // (see SiC64Menu's insertRecentComponent for what that eventually looks
    // like).
    //

    component HardDriveMenu: SiMenu {

        id: hdMenu

        required property int driveNr   // 0..3

        readonly property bool connected: config.hdConnected(driveNr)
        readonly property bool hasDisk: amiga.hdHasDisk(driveNr)

        SiMenuItem {
            text: connected ? qsTr("Detach") : qsTr("Connect")
            onTriggered: connected ? amiga.detachHd(driveNr) : config.setHdConnected(driveNr, true)
        }

        SiMenuSeparator { visible: connected }

        SiMenuItem {
            text: qsTr("Attach...")
            visible: connected
            onTriggered: window.attachHdAction(driveNr)
        }
        SiMenuSeparator { visible: connected }
        SiMenuItem {
            text: qsTr("Export...")
            visible: connected
            enabled: hasDisk
            onTriggered: window.exportHdAction(driveNr)
        }
    }

    // The drive/hard-drive menus are added to / removed from the bar
    // explicitly via insertMenu()/removeMenu(): MenuBar doesn't react to a
    // child Menu's own `visible` property (see SiC64Menu.qml, which hit the
    // same thing). df0 is always present -- it's the Amiga's built-in drive,
    // not something a user unplugs -- while df1..df3 and hd0..hd3 come and
    // go with their DRIVE_CONNECT/HDC_CONNECT config state.

    Component { id: df0Component; DriveMenu { title: qsTr("Df&0"); driveNr: 0 } }
    Component { id: df1Component; DriveMenu { title: qsTr("Df&1"); driveNr: 1 } }
    Component { id: df2Component; DriveMenu { title: qsTr("Df&2"); driveNr: 2 } }
    Component { id: df3Component; DriveMenu { title: qsTr("Df&3"); driveNr: 3 } }
    Component { id: hd0Component; HardDriveMenu { title: qsTr("Hd&0"); driveNr: 0 } }
    Component { id: hd1Component; HardDriveMenu { title: qsTr("Hd&1"); driveNr: 1 } }
    Component { id: hd2Component; HardDriveMenu { title: qsTr("Hd&2"); driveNr: 2 } }
    Component { id: hd3Component; HardDriveMenu { title: qsTr("Hd&3"); driveNr: 3 } }

    property Menu df0MenuItem: null
    property Menu df1MenuItem: null
    property Menu df2MenuItem: null
    property Menu df3MenuItem: null
    property Menu hd0MenuItem: null
    property Menu hd1MenuItem: null
    property Menu hd2MenuItem: null
    property Menu hd3MenuItem: null

    // Amiga, Edit and View always precede these menus, so the peripheral
    // menus occupy consecutive slots starting here in the order Df0..Df3,
    // Hd0..Hd3. insertMenu() shifts whatever's at/after an index up by one,
    // so inserting a missing menu at the running index keeps them ordered
    // without manual reindexing.
    readonly property int peripheralMenuBaseIndex: 3

    function updatePeripheralMenus() {

        let index = peripheralMenuBaseIndex

        // Df0 -- always shown
        if (!df0MenuItem) {
            df0MenuItem = df0Component.createObject(root)
            root.insertMenu(index, df0MenuItem)
        }
        index++

        // Df1..Df3 -- shown while connected
        const dfComponents = [df1Component, df2Component, df3Component]
        for (let d = 1; d <= 3; d++) {

            const show = config.driveConnected(d)
            const key = "df" + d + "MenuItem"

            if (show && !root[key]) {
                root[key] = dfComponents[d - 1].createObject(root)
                root.insertMenu(index, root[key])
            } else if (!show && root[key]) {
                root.removeMenu(root[key]); root[key].destroy(); root[key] = null
            }
            if (root[key]) index++
        }

        // Hd0..Hd3 -- shown while connected
        const hdComponents = [hd0Component, hd1Component, hd2Component, hd3Component]
        for (let h = 0; h <= 3; h++) {

            const show = config.hdConnected(h)
            const key = "hd" + h + "MenuItem"

            if (show && !root[key]) {
                root[key] = hdComponents[h].createObject(root)
                root.insertMenu(index, root[key])
            } else if (!show && root[key]) {
                root.removeMenu(root[key]); root[key].destroy(); root[key] = null
            }
            if (root[key]) index++
        }
    }

    Component.onCompleted: updatePeripheralMenus()

    Connections {
        target: config
        function onConfigChanged() { updatePeripheralMenus() }
    }

    //
    // Keyboard Menu
    //
    // Trimmed to what vAmiga's own MainMenu.xib offers -- there's no
    // C64-style "type this BASIC command" section, since AmigaOS isn't a
    // line-oriented BASIC the emulator can type into the way the C64's
    // KERNAL is.
    //

    SiMenu {
        title: qsTr("&Keyboard")

        Action {
            text: qsTr("Show...")
            shortcut: "Ctrl+K"
            onTriggered: openKeyboard()
        }

        SiMenuSeparator { }

        Action {
            text: qsTr("Control Warp Mode with Caps Lock Key")
            checkable: true
            checked: Preferences.capsLockAction === 1
            onTriggered: Preferences.capsLockAction = checked ? 1 : 0
        }

        SiMenuSeparator { }

        Action {
            text: qsTr("Reset Keyboard Handler")
            onTriggered: amiga.resetKeyboardMatrix()
        }
    }
}
