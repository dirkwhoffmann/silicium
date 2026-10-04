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
import Sulfur

SuMenuBar {

    id: root

    readonly property C64Controller c64: C64Controller
    required property SiC64Window window
    readonly property SiC64ConfigController config: c64.configController
    readonly property var kb: c64.keyboardController

    //
    // C64 menu
    //

    SuMenu {
        title: qsTr("C64")

        SuMenuItem {
            action: window.actions.showAbout
        }

        SuMenuSeparator { }

        SuMenuItem {
            action: window.actions.config
            text: qsTr("Settings...")
        }

        SuMenu {
            title: qsTr("Inspector")

            SuMenuItem {
                action: window.actions.openCPUInspector
            }
            SuMenuItem {
                action: window.actions.openMemoryInspector
            }
            SuMenuItem {
                action: window.actions.openBusInspector
            }
            SuMenuItem {
                action: window.actions.openCIAInspector
            }
            SuMenuItem {
                action: window.actions.openVICInspector
            }
            SuMenuItem {
                action: window.actions.openSIDInspector
            }
            SuMenuItem {
                action: window.actions.openEventsInspector
            }
        }

        SuMenuSeparator { }

        SuMenuItem {
            action: window.actions.retroShell
        }

        SuMenuItem {
            action: window.actions.logger
        }

        SuMenuSeparator { }

        Action {
            text: qsTr("&Quit");
            shortcut: StandardKey.Quit
            onTriggered: Qt.quit()
        }
    }

    //
    // Edit Menu (partial: Grab Mouse … Toggle Warp Mode)
    //

    SuMenu {
        title: qsTr("&Edit")

        SuMenuItem {
            action: window.actions.captureOrReleaseMouse
        }

        SuMenuSeparator { }

        SuMenuItem {
            action: window.actions.pause
        }
        SuMenuItem {
            action: window.actions.hardReset
        }
        SuMenuItem {
            action: window.actions.softReset
        }
        SuMenuItem {
            action: window.actions.power
        }
        SuMenuItem {
            action: window.actions.brk
        }

        SuMenuSeparator { }

        SuMenuItem {
            action: window.actions.stepOver
        }
        SuMenuItem {
            action: window.actions.stepInto
        }
        SuMenuItem {
            action: window.actions.finishLine
        }
        SuMenuItem {
            action: window.actions.finishFrame
        }

        SuMenuSeparator { }

        SuMenuItem {
            action: window.actions.toggleWarp
        }
    }

    //
    // View Menu
    //

    SuMenu {
        title: qsTr("&View")

        SuMenuItem {
            action: window.actions.toggleCommandBar
            onTriggered: window.showToolbarHint()
        }
        SuMenuItem {
            action: window.actions.toggleStatusBar
        }
    }

    //
    // Drive Menu (reusable inline component, instantiated for drive 8 and 9)
    //

    component DriveMenu: SuMenu {

        id: driveMenu

        required property int driveNr   // 8 or 9

        readonly property bool connected: driveNr === 8 ? config.DRIVE8_CONNECTED : config.DRIVE9_CONNECTED
        readonly property bool hasDisk: driveNr === 8 ? c64.media.drive8HasDisk : c64.media.drive9HasDisk
        readonly property bool writeProtected: driveNr === 8 ? c64.media.drive8WriteProtected : c64.media.drive9WriteProtected
        readonly property bool modified: driveNr === 8 ? c64.media.drive8Modified : c64.media.drive9Modified
        readonly property bool poweredOn: driveNr === 8 ? c64.media.drive8PoweredOn : c64.media.drive9PoweredOn

        // While disconnected, there's nothing to insert/eject/export for
        // hardware that isn't part of the current setup, so every other item
        // is hidden and only the toggle remains -- keeping the menu focused
        // instead of showing a wall of items that would just error out.
        SuMenuItem {
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

        SuMenuSeparator { visible: connected }

        // "Insert Recent" is a nested Menu, and a nested Menu's own 'visible'
        // property does not hide its row in the parent (verified empirically
        // -- unlike a leaf MenuItem, whose 'visible' does collapse its row).
        // So it's added to / removed from this menu explicitly via
        // insertMenu()/removeMenu(), the same technique used to show/hide
        // this whole menu in the menu bar.
        Component {

            id: insertRecentComponent

            SuMenu {

                id: insertRecentMenu
                title: qsTr("Insert Recent")

                // With an empty list there's nothing to insert and nothing to
                // clear, so gray out the row rather than let it open onto a
                // stray separator and a lone "Clear Menu". Unlike 'visible',
                // a nested Menu's 'enabled' does propagate to its row in the
                // parent (and stays bound), which is what dims it here.
                enabled: c64.media.recentDisks.length > 0

                // Dynamically generate one MenuItem per recently inserted disk.
                // The model (c64.media.recentDisks) is shared by both drives -- only
                // the insert target (driveNr) differs between the Drive 8 and
                // Drive 9 submenus. The Instantiator keeps the menu in sync with
                // it, inserting/removing items as the list changes.
                Instantiator {
                    model: c64.media.recentDisks
                    delegate: SuMenuItem {
                        text: modelData.substring(modelData.lastIndexOf("/") + 1)
                        onTriggered: window.actions.insertRecentDiskAction(driveNr, index)
                    }
                    onObjectAdded: (index, object) => insertRecentMenu.insertItem(index, object)
                    onObjectRemoved: (index, object) => insertRecentMenu.removeItem(object)
                }

                SuMenuSeparator { }
                Action {
                    text: qsTr("Clear Menu")
                    onTriggered: c64.media.clearRecentlyInsertedDisks()
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

        SuMenuItem {
            text: qsTr("New")
            visible: connected
            onTriggered: window.actions.newDiskAction(driveNr)
        }
        SuMenuItem {
            text: qsTr("Insert...")
            visible: connected
            onTriggered: window.actions.insertDiskAction(driveNr)
        }
        SuMenuSeparator { visible: connected }
        SuMenuItem {
            text: qsTr("Eject")
            visible: connected
            enabled: hasDisk
            onTriggered: window.actions.ejectDiskAction(driveNr)
        }
        SuMenuItem {
            text: qsTr("Export...")
            visible: connected
            onTriggered: window.actions.exportDiskAction(driveNr)
        }
        SuMenuSeparator { visible: connected }
        // Action {
        //     text: qsTr("Inspect Disk...")
        //     onTriggered: c64.inspectDisk(driveNr)
        // }
        SuMenuItem {
            text: qsTr("Write Protected")
            checkable: true
            visible: connected
            enabled: hasDisk
            checked: writeProtected
            onTriggered: c64.media.toggleWriteProtection(driveNr)
        }

        SuMenuItem {
            text: qsTr("Modified")
            checkable: true
            visible: connected && Preferences.developerMode
            enabled: hasDisk
            checked: modified
            onTriggered: c64.media.toggleUnsavedState(driveNr)
        }
        SuMenuSeparator { visible: connected }

        SuMenuItem {
            text: poweredOn ? qsTr("Switch Off") : qsTr("Switch On")
            visible: connected
            onTriggered: c64.media.toggleDrivePower(driveNr)
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

    component DatasetteMenu: SuMenu {

        title: qsTr("&Datasette")

        id: datasetteMenu

        readonly property bool connected: config.DAT_CONNECT

        // While disconnected, there's nothing to insert/eject/export for
        // hardware that isn't part of the current setup, so every other item
        // is hidden and only the toggle remains.
        SuMenuItem {
            text: connected ? qsTr("Disconnect") : qsTr("Connect")
            onTriggered: config.DAT_CONNECT = !connected
        }

        SuMenuSeparator { visible: connected }

        SuMenuItem {
            text: qsTr("Insert Tape...")
            visible: connected
            onTriggered: window.actions.insertTapeAction()
        }

        // "Insert Recent" is a nested Menu, and a nested Menu's own 'visible'
        // property does not hide its row in the parent (verified empirically
        // -- unlike a leaf MenuItem, whose 'visible' does collapse its row).
        // So it's added to / removed from this menu explicitly via
        // insertMenu()/removeMenu(), the same technique used to show/hide
        // this whole menu in the menu bar.
        Component {
            id: insertRecentTapeComponent

            SuMenu {
                id: insertRecentTapeMenu
                title: qsTr("Insert Recent")

                // Grayed out while the list is empty -- see insertRecentMenu.
                enabled: c64.media.recentTapes.length > 0

                // Dynamically generate one MenuItem per recently inserted tape.
                Instantiator {
                    model: c64.media.recentTapes
                    delegate: SuMenuItem {
                        text: modelData.substring(modelData.lastIndexOf("/") + 1)
                        onTriggered: c64.media.insertRecentTape(index)
                    }
                    onObjectAdded: (index, object) => insertRecentTapeMenu.insertItem(index, object)
                    onObjectRemoved: (index, object) => insertRecentTapeMenu.removeItem(object)
                }

                SuMenuSeparator { }
                Action {
                    text: qsTr("Clear Menu")
                    onTriggered: c64.media.clearRecentlyInsertedTapes()
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

        SuMenuSeparator { visible: connected }

        SuMenuItem {
            text: qsTr("Eject Tape")
            visible: connected
            enabled: c64.media.tapeInserted
            onTriggered: c64.media.ejectTape()
        }
        SuMenuItem {
            text: qsTr("Rewind Tape")
            visible: connected
            enabled: c64.media.tapeInserted
            onTriggered: c64.media.rewindTape()
        }

        SuMenuSeparator { visible: connected }

        SuMenuItem {
            text: qsTr("Export Tape...")
            visible: connected
            enabled: c64.media.tapeInserted
            onTriggered: window.actions.exportTapeAction()
        }

        SuMenuSeparator { visible: connected }

        SuMenuItem {
            text: c64.media.tapePlaying ? qsTr("Press Stop Key") : qsTr("Press Play On Tape")
            visible: connected
            enabled: c64.media.tapeInserted
            onTriggered: c64.media.playOrStopTape()
        }
    }

    //
    // Expansion (Cartridge) Menu
    //

    SuMenu {
        title: qsTr("E&xpansion")

        Action {
            text: qsTr("Attach Cartridge...")
            onTriggered: window.actions.attachCartridgeAction()
        }

        SuMenu {
            id: attachRecentMenu
            title: qsTr("Attach Recent")

            // Grayed out while the list is empty -- see insertRecentMenu.
            enabled: c64.media.recentCartridges.length > 0

            // Dynamically generate one MenuItem per recently attached cartridge.
            Instantiator {
                model: c64.media.recentCartridges
                delegate: SuMenuItem {
                    text: modelData.substring(modelData.lastIndexOf("/") + 1)
                    onTriggered: c64.media.attachRecentCartridge(index)
                }
                onObjectAdded: (index, object) => attachRecentMenu.insertItem(index, object)
                onObjectRemoved: (index, object) => attachRecentMenu.removeItem(object)
            }

            SuMenuSeparator { }
            Action {
                text: qsTr("Clear Menu")
                onTriggered: c64.media.clearRecentlyAttachedCartridges()
            }
        }

        SuMenuSeparator { }

        Action {
            text: qsTr("Detach Cartridge")
            enabled: c64.media.cartridgeAttached
            onTriggered: c64.media.detachCartridge()
        }

        SuMenuSeparator { }

        SuMenu {
            title: qsTr("Attach REU")
            Action { text: qsTr("REU 1700 (128 KB)");     checkable: true; checked: c64.media.cartridgeIsReu && c64.media.cartridgeMemory === 128;  onTriggered: c64.media.attachReu(128)  }
            Action { text: qsTr("REU 1764 (256 KB)");     checkable: true; checked: c64.media.cartridgeIsReu && c64.media.cartridgeMemory === 256;  onTriggered: c64.media.attachReu(256)  }
            Action { text: qsTr("REU 1750 (512 KB)");     checkable: true; checked: c64.media.cartridgeIsReu && c64.media.cartridgeMemory === 512;  onTriggered: c64.media.attachReu(512)  }
            Action { text: qsTr("REU 1750 XL (2048 KB)"); checkable: true; checked: c64.media.cartridgeIsReu && c64.media.cartridgeMemory === 2048; onTriggered: c64.media.attachReu(2048) }
        }

        SuMenu {
            title: qsTr("Attach GEO/NEO Ram")
            Action { text: qsTr("GEO RAM (512 KB)");  checkable: true; checked: c64.media.cartridgeIsGeoRam && c64.media.cartridgeMemory === 512;  onTriggered: c64.media.attachGeoRam(512)  }
            Action { text: qsTr("NEO RAM (1024 KB)"); checkable: true; checked: c64.media.cartridgeIsGeoRam && c64.media.cartridgeMemory === 1024; onTriggered: c64.media.attachGeoRam(1024) }
            Action { text: qsTr("NEO RAM (2048 KB)"); checkable: true; checked: c64.media.cartridgeIsGeoRam && c64.media.cartridgeMemory === 2048; onTriggered: c64.media.attachGeoRam(2048) }
            Action { text: qsTr("NEO RAM (4096 KB)"); checkable: true; checked: c64.media.cartridgeIsGeoRam && c64.media.cartridgeMemory === 4096; onTriggered: c64.media.attachGeoRam(4096) }
        }

        Action {
            text: qsTr("Attach Isepic Cartridge")
            checkable: true
            checked: c64.media.cartridgeIsIsepic
            onTriggered: c64.media.attachIsepic()
        }

        SuMenuSeparator { }

        Action {
            text: qsTr("Export Cartridge...")
            enabled: c64.media.cartridgeAttached
            onTriggered: window.actions.exportCartridgeAction()
        }
        Action {
            text: qsTr("Inspect Cartridge...")
            onTriggered: c64.inspectCartridge()
        }

        SuMenuSeparator { }

        SuMenu {
            title: qsTr("Buttons")
            enabled: c64.media.cartridgeButtons > 0
            Action { text: qsTr("Press Button 1"); onTriggered: c64.media.pressCartridgeButton(1) }
            Action { text: qsTr("Press Button 2"); onTriggered: c64.media.pressCartridgeButton(2) }
        }

        SuMenu {
            title: qsTr("Switch")
            enabled: c64.media.cartridgeSwitches > 0
            Action { text: qsTr("Pull Left");    checkable: true; checked: c64.media.cartridgeSwitchPos < 0;  onTriggered: c64.media.setCartridgeSwitch(-1) }
            Action { text: qsTr("Set Neutral");  checkable: true; checked: c64.media.cartridgeSwitchPos === 0; onTriggered: c64.media.setCartridgeSwitch(0)  }
            Action { text: qsTr("Pull Right");   checkable: true; checked: c64.media.cartridgeSwitchPos > 0;   onTriggered: c64.media.setCartridgeSwitch(1)  }
        }
    }

    //
    // Keyboard Menu
    //

    SuMenu {
        title: qsTr("&Keyboard")

        Action {
            text: qsTr("Show ...")
            shortcut: "Ctrl+K"
            onTriggered: window.actions.keyboardWindowAction.trigger()
        }

        SuMenuSeparator { }

        SuMenu {
            title: qsTr("Press")

            Action { text: qsTr("COMMODORE");      onTriggered: kb.type(49) }
            Action { text: qsTr("RUNSTOP");        onTriggered: kb.type(33) }
            Action { text: qsTr("RESTORE");        onTriggered: kb.type(31) }
            Action { text: qsTr("RUNSTOP RESTORE");onTriggered: kb.typeRunStopRestore() }

            SuMenuSeparator { }

            Action { text: qsTr("HOME");           onTriggered: kb.type(14) }
            Action { text: qsTr("CLR");            onTriggered: kb.type(14, true)  }
            Action { text: qsTr("INST");           onTriggered: kb.type(15) }
            Action { text: qsTr("DEL");            onTriggered: kb.type(15, true)  }

            SuMenuSeparator { }

            Action { text: qsTr("LEFT ARROW");     onTriggered: kb.type(0) }
            Action { text: qsTr("UP ARROW");       onTriggered: kb.type(30) }
            Action { text: qsTr("POUND");          onTriggered: kb.type(13) }

            SuMenuSeparator { }

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

        SuMenuSeparator { }

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

        SuMenuSeparator { }

        Action {
            text: qsTr("Reset Keyboard Matrix")
            onTriggered: kb.resetKeyboardMatrix()
        }
    }
}