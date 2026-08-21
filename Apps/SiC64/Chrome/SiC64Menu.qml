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

SiMenuBar {

    id: root

    required property C64Controller c64
    required property SiC64Window window
    readonly property SiC64ConfigController config: c64.configController
    readonly property var kb: c64.keyboardController

    // Emitted when a menu item wants to open the Configurator on a specific
    // page (see SiC64ConfigWindow.Page). The window handles the actual display.
    signal openConfigurator(int page)

    // Emitted by the C64 menu's "About" item. The window handles the actual
    // display (see About.qml).
    signal openAbout()

    // Reflects the current visibility of the toolbar (which now includes the
    // menu row) and the status bar, so the View menu's checkable items can
    // show the right state. The window owns the actual visibility and
    // toggles it in response to the signals below.
    property bool toolbarVisible: true
    property bool statusBarVisible: true

    signal toggleToolbar()
    signal toggleStatusBar()

    //
    // C64 menu
    //

    SiMenu {
        title: qsTr("C64")

        Action {
            text: qsTr("About")
            onTriggered: openAbout()
        }

        SiMenuSeparator { }

        SiMenuItem {
            action: window.actions.config
            text: qsTr("Settings...")
        }

        SiMenu {
            title: qsTr("Inspector")

            SiMenuItem {
                action: window.actions.openCPUInspector
            }
            SiMenuItem {
                action: window.actions.openMemoryInspector
            }
            SiMenuItem {
                action: window.actions.openBusInspector
            }
            SiMenuItem {
                action: window.actions.openCIAInspector
            }
            SiMenuItem {
                action: window.actions.openVICInspector
            }
            SiMenuItem {
                action: window.actions.openSIDInspector
            }
            SiMenuItem {
                action: window.actions.openEventsInspector
            }
        }

        SiMenuSeparator { }

        SiMenuItem {
            action: window.actions.retroShell
        }

        SiMenuItem {
            action: window.actions.logger
        }

        SiMenuSeparator { }

        Action {
            text: qsTr("&Quit");
            shortcut: StandardKey.Quit
            onTriggered: Qt.quit()
        }
    }

    //
    // Edit Menu (partial: Grab Mouse … Toggle Warp Mode)
    //

    SiMenu {
        title: qsTr("&Edit")

        SiMenuItem {
            action: window.actions.captureOrReleaseMouse
        }

        SiMenuSeparator { }

        SiMenuItem {
            action: window.actions.pause
        }
        SiMenuItem {
            action: window.actions.hardReset
        }
        SiMenuItem {
            action: window.actions.softReset
        }
        SiMenuItem {
            action: window.actions.power
        }
        SiMenuItem {
            action: window.actions.brk
        }

        SiMenuSeparator { }

        SiMenuItem {
            action: window.actions.stepOver
        }
        SiMenuItem {
            action: window.actions.stepInto
        }
        SiMenuItem {
            action: window.actions.finishLine
        }
        SiMenuItem {
            action: window.actions.finishFrame
        }

        SiMenuSeparator { }

        SiMenuItem {
            action: window.actions.toggleWarp
        }
    }

    //
    // View Menu
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
    // Drive Menu (reusable inline component, instantiated for drive 8 and 9)
    //

    component DriveMenu: SiMenu {

        id: driveMenu

        required property int driveNr   // 8 or 9

        readonly property bool connected: driveNr === 8 ? config.DRIVE8_CONNECTED : config.DRIVE9_CONNECTED
        readonly property bool hasDisk: driveNr === 8 ? c64.drive8HasDisk : c64.drive9HasDisk
        readonly property bool writeProtected: driveNr === 8 ? c64.drive8WriteProtected : c64.drive9WriteProtected
        readonly property bool modified: driveNr === 8 ? c64.drive8Modified : c64.drive9Modified
        readonly property bool poweredOn: driveNr === 8 ? c64.drive8PoweredOn : c64.drive9PoweredOn

        // While disconnected, there's nothing to insert/eject/export for
        // hardware that isn't part of the current setup, so every other item
        // is hidden and only the toggle remains -- keeping the menu focused
        // instead of showing a wall of items that would just error out.
        SiMenuItem {
            text: connected ? qsTr("Disconnect") : qsTr("Connect")
            onTriggered: {

                // The core refuses to connect a drive without a ROM (and
                // silently drops the request), so guard against it here and
                // point the user at the ROM settings instead.
                if (!connected && !config.hasVC1541Rom) {
                    window.showError(
                        qsTr("No Drive ROM Installed"),
                        qsTr("Drive %1 cannot be connected because no floppy drive ROM is installed. Add one in the ROM settings to continue.").arg(driveNr))
                    return
                }

                if (driveNr === 8) config.DRIVE8_CONNECTED = !connected
                else config.DRIVE9_CONNECTED = !connected
            }
        }

        SiMenuSeparator { visible: connected }

        // "Insert Recent" is a nested Menu, and a nested Menu's own 'visible'
        // property does not hide its row in the parent (verified empirically
        // -- unlike a leaf MenuItem, whose 'visible' does collapse its row).
        // So it's added to / removed from this menu explicitly via
        // insertMenu()/removeMenu(), the same technique used to show/hide
        // this whole menu in the menu bar.
        Component {

            id: insertRecentComponent

            SiMenu {

                id: insertRecentMenu
                title: qsTr("Insert Recent")

                // With an empty list there's nothing to insert and nothing to
                // clear, so gray out the row rather than let it open onto a
                // stray separator and a lone "Clear Menu". Unlike 'visible',
                // a nested Menu's 'enabled' does propagate to its row in the
                // parent (and stays bound), which is what dims it here.
                enabled: c64.recentDisks.length > 0

                // Dynamically generate one MenuItem per recently inserted disk.
                // The model (c64.recentDisks) is shared by both drives -- only
                // the insert target (driveNr) differs between the Drive 8 and
                // Drive 9 submenus. The Instantiator keeps the menu in sync with
                // it, inserting/removing items as the list changes.
                Instantiator {
                    model: c64.recentDisks
                    delegate: SiMenuItem {
                        text: modelData.substring(modelData.lastIndexOf("/") + 1)
                        onTriggered: window.insertRecentDiskAction(driveNr, index)
                    }
                    onObjectAdded: (index, object) => insertRecentMenu.insertItem(index, object)
                    onObjectRemoved: (index, object) => insertRecentMenu.removeItem(object)
                }

                SiMenuSeparator { }
                Action {
                    text: qsTr("Clear Menu")
                    onTriggered: c64.clearRecentlyInsertedDisks()
                }
            }
        }

        property Menu insertRecentItem: null

        // Inserted right after the toggle + separator (index 2), ahead of the
        // static items below -- their own indices don't shift, since a hidden
        // (visible: false) item still occupies its slot in the menu's content
        // model.
        function updateInsertRecent() {

            if (connected && !insertRecentItem) {
                insertRecentItem = insertRecentComponent.createObject(driveMenu)
                driveMenu.insertMenu(2, insertRecentItem)
            } else if (!connected && insertRecentItem) {
                driveMenu.removeMenu(insertRecentItem)
                insertRecentItem.destroy()
                insertRecentItem = null
            }
        }

        Component.onCompleted: updateInsertRecent()
        onConnectedChanged: updateInsertRecent()

        SiMenuItem {
            text: qsTr("New")
            visible: connected
            onTriggered: window.newDiskAction(driveNr)
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
            onTriggered: window.ejectDiskAction(driveNr)
        }
        SiMenuItem {
            text: qsTr("Export...")
            visible: connected
            onTriggered: window.exportDiskAction(driveNr)
        }
        SiMenuSeparator { visible: connected }
        // Action {
        //     text: qsTr("Inspect Disk...")
        //     onTriggered: c64.inspectDisk(driveNr)
        // }
        SiMenuItem {
            text: qsTr("Write Protected")
            checkable: true
            visible: connected
            enabled: hasDisk
            checked: writeProtected
            onTriggered: c64.toggleWriteProtection(driveNr)
        }

        SiMenuItem {
            text: qsTr("Modified")
            checkable: true
            visible: connected && Preferences.developerMode
            enabled: hasDisk
            checked: modified
            onTriggered: c64.toggleUnsavedState(driveNr)
        }
        SiMenuSeparator { visible: connected }

        SiMenuItem {
            text: poweredOn ? qsTr("Switch Off") : qsTr("Switch On")
            visible: connected
            onTriggered: c64.toggleDrivePower(driveNr)
        }
    }

    // The Drive 8 / 9 and Datasette menus are added to / removed from the bar
    // explicitly via insertMenu()/removeMenu(): MenuBar doesn't react to a
    // child Menu's own `visible` property (verified empirically -- even a
    // hardcoded `visible: false` left the item showing). In "Show always" mode
    // they are always present; in "When connected" mode they appear only while
    // the peripheral is connected.

    Component { id: drive8Component; DriveMenu { title: qsTr("Drive &8"); driveNr: 8 } }
    Component { id: drive9Component; DriveMenu { title: qsTr("Drive &9"); driveNr: 9 } }
    Component { id: datasetteComponent; DatasetteMenu { } }

    property Menu drive8MenuItem: null
    property Menu drive9MenuItem: null
    property Menu datasetteMenuItem: null

    // C64, Edit and View always precede these menus, so the peripheral menus
    // occupy consecutive slots starting here in the order Drive 8, Drive 9,
    // Datasette. insertMenu() shifts whatever's at/after an index up by one, so
    // inserting a missing menu at the running index keeps them ordered without
    // manual reindexing.
    readonly property int peripheralMenuBaseIndex: 3

    // Debug-only switch (not user-facing): false = drive/datasette menus are
    // always shown (each hiding its own items behind a Connect item when
    // disconnected -- see DriveMenu/DatasetteMenu); true = the whole menu
    // shows only while its peripheral is connected. Flip this locally while
    // testing; there's intentionally no Preferences/UI hook for it.
    property bool dynamicMenus: false

    readonly property bool showDrive8: !dynamicMenus || config.DRIVE8_CONNECTED
    readonly property bool showDrive9: !dynamicMenus || config.DRIVE9_CONNECTED
    readonly property bool showDatasette: !dynamicMenus || config.DAT_CONNECT

    function updatePeripheralMenus() {

        let index = peripheralMenuBaseIndex

        // Drive 8
        if (showDrive8 && !drive8MenuItem) {
            drive8MenuItem = drive8Component.createObject(root)
            root.insertMenu(index, drive8MenuItem)
        } else if (!showDrive8 && drive8MenuItem) {
            root.removeMenu(drive8MenuItem); drive8MenuItem.destroy(); drive8MenuItem = null
        }
        if (drive8MenuItem) index++

        // Drive 9
        if (showDrive9 && !drive9MenuItem) {
            drive9MenuItem = drive9Component.createObject(root)
            root.insertMenu(index, drive9MenuItem)
        } else if (!showDrive9 && drive9MenuItem) {
            root.removeMenu(drive9MenuItem); drive9MenuItem.destroy(); drive9MenuItem = null
        }
        if (drive9MenuItem) index++

        // Datasette
        if (showDatasette && !datasetteMenuItem) {
            datasetteMenuItem = datasetteComponent.createObject(root)
            root.insertMenu(index, datasetteMenuItem)
        } else if (!showDatasette && datasetteMenuItem) {
            root.removeMenu(datasetteMenuItem); datasetteMenuItem.destroy(); datasetteMenuItem = null
        }
        if (datasetteMenuItem) index++
    }

    Component.onCompleted: updatePeripheralMenus()
    onDynamicMenusChanged: updatePeripheralMenus()

    Connections {
        target: config
        function onConfigChanged() { updatePeripheralMenus() }
    }

    //
    // Datasette Menu (instantiated dynamically, see updatePeripheralMenus)
    //

    component DatasetteMenu: SiMenu {

        title: qsTr("&Datasette")

        id: datasetteMenu

        readonly property bool connected: config.DAT_CONNECT

        // While disconnected, there's nothing to insert/eject/export for
        // hardware that isn't part of the current setup, so every other item
        // is hidden and only the toggle remains.
        SiMenuItem {
            text: connected ? qsTr("Disconnect") : qsTr("Connect")
            onTriggered: config.DAT_CONNECT = !connected
        }

        SiMenuSeparator { visible: connected }

        SiMenuItem {
            text: qsTr("Insert Tape...")
            visible: connected
            onTriggered: window.insertTapeAction()
        }

        // "Insert Recent" is a nested Menu, and a nested Menu's own 'visible'
        // property does not hide its row in the parent (verified empirically
        // -- unlike a leaf MenuItem, whose 'visible' does collapse its row).
        // So it's added to / removed from this menu explicitly via
        // insertMenu()/removeMenu(), the same technique used to show/hide
        // this whole menu in the menu bar.
        Component {
            id: insertRecentTapeComponent

            SiMenu {
                id: insertRecentTapeMenu
                title: qsTr("Insert Recent")

                // Grayed out while the list is empty -- see insertRecentMenu.
                enabled: c64.recentTapes.length > 0

                // Dynamically generate one MenuItem per recently inserted tape.
                Instantiator {
                    model: c64.recentTapes
                    delegate: SiMenuItem {
                        text: modelData.substring(modelData.lastIndexOf("/") + 1)
                        onTriggered: c64.insertRecentTape(index)
                    }
                    onObjectAdded: (index, object) => insertRecentTapeMenu.insertItem(index, object)
                    onObjectRemoved: (index, object) => insertRecentTapeMenu.removeItem(object)
                }

                SiMenuSeparator { }
                Action {
                    text: qsTr("Clear Menu")
                    onTriggered: c64.clearRecentlyInsertedTapes()
                }
            }
        }

        property Menu insertRecentTapeItem: null

        // Inserted right after "Insert Tape..." (index 3), ahead of the
        // static items below -- their own indices don't shift, since a hidden
        // (visible: false) item still occupies its slot in the menu's content
        // model.
        function updateInsertRecentTape() {

            if (connected && !insertRecentTapeItem) {
                insertRecentTapeItem = insertRecentTapeComponent.createObject(datasetteMenu)
                datasetteMenu.insertMenu(3, insertRecentTapeItem)
            } else if (!connected && insertRecentTapeItem) {
                datasetteMenu.removeMenu(insertRecentTapeItem)
                insertRecentTapeItem.destroy()
                insertRecentTapeItem = null
            }
        }

        Component.onCompleted: updateInsertRecentTape()
        onConnectedChanged: updateInsertRecentTape()

        SiMenuSeparator { visible: connected }

        SiMenuItem {
            text: qsTr("Eject Tape")
            visible: connected
            enabled: c64.tapeInserted
            onTriggered: c64.ejectTape()
        }
        SiMenuItem {
            text: qsTr("Rewind Tape")
            visible: connected
            enabled: c64.tapeInserted
            onTriggered: c64.rewindTape()
        }

        SiMenuSeparator { visible: connected }

        SiMenuItem {
            text: qsTr("Export Tape...")
            visible: connected
            enabled: c64.tapeInserted
            onTriggered: window.exportTapeAction()
        }

        SiMenuSeparator { visible: connected }

        SiMenuItem {
            text: c64.tapePlaying ? qsTr("Press Stop Key") : qsTr("Press Play On Tape")
            visible: connected
            enabled: c64.tapeInserted
            onTriggered: c64.playOrStopTape()
        }
    }

    //
    // Expansion (Cartridge) Menu
    //

    SiMenu {
        title: qsTr("E&xpansion")

        Action {
            text: qsTr("Attach Cartridge...")
            onTriggered: window.attachCartridgeAction()
        }

        SiMenu {
            id: attachRecentMenu
            title: qsTr("Attach Recent")

            // Grayed out while the list is empty -- see insertRecentMenu.
            enabled: c64.recentCartridges.length > 0

            // Dynamically generate one MenuItem per recently attached cartridge.
            Instantiator {
                model: c64.recentCartridges
                delegate: SiMenuItem {
                    text: modelData.substring(modelData.lastIndexOf("/") + 1)
                    onTriggered: c64.attachRecentCartridge(index)
                }
                onObjectAdded: (index, object) => attachRecentMenu.insertItem(index, object)
                onObjectRemoved: (index, object) => attachRecentMenu.removeItem(object)
            }

            SiMenuSeparator { }
            Action {
                text: qsTr("Clear Menu")
                onTriggered: c64.clearRecentlyAttachedCartridges()
            }
        }

        SiMenuSeparator { }

        Action {
            text: qsTr("Detach Cartridge")
            enabled: c64.cartridgeAttached
            onTriggered: c64.detachCartridge()
        }

        SiMenuSeparator { }

        SiMenu {
            title: qsTr("Attach REU")
            Action { text: qsTr("REU 1700 (128 KB)");     checkable: true; checked: c64.cartridgeIsReu && c64.cartridgeMemory === 128;  onTriggered: c64.attachReu(128)  }
            Action { text: qsTr("REU 1764 (256 KB)");     checkable: true; checked: c64.cartridgeIsReu && c64.cartridgeMemory === 256;  onTriggered: c64.attachReu(256)  }
            Action { text: qsTr("REU 1750 (512 KB)");     checkable: true; checked: c64.cartridgeIsReu && c64.cartridgeMemory === 512;  onTriggered: c64.attachReu(512)  }
            Action { text: qsTr("REU 1750 XL (2048 KB)"); checkable: true; checked: c64.cartridgeIsReu && c64.cartridgeMemory === 2048; onTriggered: c64.attachReu(2048) }
        }

        SiMenu {
            title: qsTr("Attach GEO/NEO Ram")
            Action { text: qsTr("GEO RAM (512 KB)");  checkable: true; checked: c64.cartridgeIsGeoRam && c64.cartridgeMemory === 512;  onTriggered: c64.attachGeoRam(512)  }
            Action { text: qsTr("NEO RAM (1024 KB)"); checkable: true; checked: c64.cartridgeIsGeoRam && c64.cartridgeMemory === 1024; onTriggered: c64.attachGeoRam(1024) }
            Action { text: qsTr("NEO RAM (2048 KB)"); checkable: true; checked: c64.cartridgeIsGeoRam && c64.cartridgeMemory === 2048; onTriggered: c64.attachGeoRam(2048) }
            Action { text: qsTr("NEO RAM (4096 KB)"); checkable: true; checked: c64.cartridgeIsGeoRam && c64.cartridgeMemory === 4096; onTriggered: c64.attachGeoRam(4096) }
        }

        Action {
            text: qsTr("Attach Isepic Cartridge")
            checkable: true
            checked: c64.cartridgeIsIsepic
            onTriggered: c64.attachIsepic()
        }

        SiMenuSeparator { }

        Action {
            text: qsTr("Export Cartridge...")
            enabled: c64.cartridgeAttached
            onTriggered: window.exportCartridgeAction()
        }
        Action {
            text: qsTr("Inspect Cartridge...")
            onTriggered: c64.inspectCartridge()
        }

        SiMenuSeparator { }

        SiMenu {
            title: qsTr("Buttons")
            enabled: c64.cartridgeButtons > 0
            Action { text: qsTr("Press Button 1"); onTriggered: c64.pressCartridgeButton(1) }
            Action { text: qsTr("Press Button 2"); onTriggered: c64.pressCartridgeButton(2) }
        }

        SiMenu {
            title: qsTr("Switch")
            enabled: c64.cartridgeSwitches > 0
            Action { text: qsTr("Pull Left");    checkable: true; checked: c64.cartridgeSwitchPos < 0;  onTriggered: c64.setCartridgeSwitch(-1) }
            Action { text: qsTr("Set Neutral");  checkable: true; checked: c64.cartridgeSwitchPos === 0; onTriggered: c64.setCartridgeSwitch(0)  }
            Action { text: qsTr("Pull Right");   checkable: true; checked: c64.cartridgeSwitchPos > 0;   onTriggered: c64.setCartridgeSwitch(1)  }
        }
    }

    //
    // Keyboard Menu
    //

    SiMenu {
        title: qsTr("&Keyboard")

        Action {
            text: qsTr("Show ...")
            shortcut: "Ctrl+K"
            onTriggered: window.actions.keyboardWindowAction.trigger()
        }

        SiMenuSeparator { }

        SiMenu {
            title: qsTr("Press")

            Action { text: qsTr("COMMODORE");      onTriggered: kb.type(49) }
            Action { text: qsTr("RUNSTOP");        onTriggered: kb.type(33) }
            Action { text: qsTr("RESTORE");        onTriggered: kb.type(31) }
            Action { text: qsTr("RUNSTOP RESTORE");onTriggered: kb.typeRunStopRestore() }

            SiMenuSeparator { }

            Action { text: qsTr("HOME");           onTriggered: kb.type(14) }
            Action { text: qsTr("CLR");            onTriggered: kb.type(14, true)  }
            Action { text: qsTr("INST");           onTriggered: kb.type(15) }
            Action { text: qsTr("DEL");            onTriggered: kb.type(15, true)  }

            SiMenuSeparator { }

            Action { text: qsTr("LEFT ARROW");     onTriggered: kb.type(0) }
            Action { text: qsTr("UP ARROW");       onTriggered: kb.type(30) }
            Action { text: qsTr("POUND");          onTriggered: kb.type(13) }

            SiMenuSeparator { }

            Action { text: qsTr("F1");  onTriggered: kb.type(16) }
            Action { text: qsTr("F2");  onTriggered: kb.type(16, true)  }
            Action { text: qsTr("F3");  onTriggered: kb.type(32) }
            Action { text: qsTr("F4");  onTriggered: kb.type(32, true)  }
            Action { text: qsTr("F5");  onTriggered: kb.type(48) }
            Action { text: qsTr("F6");  onTriggered: kb.type(48, true)  }
            Action { text: qsTr("F7");  onTriggered: kb.type(64) }
            Action { text: qsTr("F8");  onTriggered: kb.type(64, true)  }
        }

        Action {
            text: qsTr("Shift Lock")
            checkable: kb.isPressed(34)
            onTriggered: kb.toggle(34)
        }

        SiMenuSeparator { }

        Action {
            text: qsTr("Load Directory")
            shortcut: "Ctrl+D"
            onTriggered: kb.type("load \"$\",8:\n")
        }
        Action {
            text: qsTr("List")
            onTriggered: kb.type("list:\n")
        }
        Action {
            text: qsTr("Load First File")
            shortcut: "Ctrl+L"
            onTriggered: kb.type("load \"*\",8,1:\n")
        }
        Action {
            text: qsTr("Run")
            onTriggered: kb.type("run:")
        }
        Action {
            text: qsTr("Format Disk")
            onTriggered: kb.type("open 1,8,15,\"n:test, id\": close 1\n:")
        }

        SiMenuSeparator { }

        Action {
            text: qsTr("Reset Keyboard Matrix")
            onTriggered: kb.resetKeyboardMatrix()
        }
    }
}