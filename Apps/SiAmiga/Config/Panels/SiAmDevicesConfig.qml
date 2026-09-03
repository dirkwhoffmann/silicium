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

// Port of vAmiga's own GUI/Settings/ViewControllers/PeripheralsSettings.swift.
// A plain two-column form (Floppy Drives/Game Ports/Serial Port on the
// left, Hard Drives/Joystick on the right) rather than SiC64DevicesConfig's
// card-per-device ConfigSection layout -- the Amiga side scales to 4 floppy
// + 4 hard drives plus game/serial/MIDI port pickers, which reads better as
// compact label+control rows than as one card apiece.
//
// Game Ports and MIDI Out/In are shown but inert: Configuration.swift's
// gameDevice1/gameDevice2 and MidiManagerProxy pick from host game
// controllers/MIDI devices enumerated by the app layer, and neither
// SiC64's own Devices panel nor SiAmConfigController has that
// enumeration wired up yet -- both combos are placeholders (a single
// "No device"/"None" entry) until that infrastructure exists, matching
// the screenshot's own "No device" placeholders exactly.
//
// Autofire (JOY1_AUTOFIRE/JOY2_AUTOFIRE and its burst/bullets/delay
// siblings) is read from port 1 and written to both ports at once,
// mirroring Configuration.swift's own autofire/autofireBursts/
// autofireBullets/autofireDelay wrappers (get id:1, set with no id --
// i.e. broadcast to every port that has the option).
SettingsPage {

    id: root

    required property SiAmController controller
    readonly property var config: controller.configController

    readonly property bool locked: controller.isPoweredOn

    readonly property var driveTypeNames: ["3.5\" DD", "3.5\" HD", "5.25\" DD"]
    readonly property var hdTypeNames: ["Zorro board"]
    readonly property var serialDeviceNames: ["No device", "Null modem", "Loopback", "RetroShell", "Commander", "MIDI"]

    // Configuration.swift's autofire/autofireBursts/autofireBullets/
    // autofireDelay wrappers write both ports at once -- see the class
    // comment.
    function setAutofire(v) { config.JOY1_AUTOFIRE = v; config.JOY2_AUTOFIRE = v }
    function setAutofireBursts(v) { config.JOY1_AUTOFIRE_BURSTS = v; config.JOY2_AUTOFIRE_BURSTS = v }
    function setAutofireBullets(v) { config.JOY1_AUTOFIRE_BULLETS = v; config.JOY2_AUTOFIRE_BULLETS = v }
    function setAutofireDelay(v) { config.JOY1_AUTOFIRE_DELAY = v; config.JOY2_AUTOFIRE_DELAY = v }

    toolbar: ConfigToolbar {

        heading: "Peripherals Settings"

        menuContent: [
            MenuItem {
                text: "Restore factory defaults..."
                onTriggered: config.restoreDevicesDefaults()
            }
        ]

        HSpacer { }

        ConfigLock {
            lockText: root.locked
            onClicked: controller.powerOnOrOff()
        }
    }

    RowLayout {

        Layout.fillWidth: true
        spacing: Style.largeSpacing * 2

        //
        // Left column: Floppy Drives, Game Ports, Serial Port
        //

        ColumnLayout {

            Layout.fillWidth: true
            spacing: Style.smallSpacing

            SiText { text: "Floppy Drives"; font.bold: true; font.pixelSize: Style.large }

            GridLayout {

                columns: 3
                columnSpacing: Style.smallSpacing
                rowSpacing: Style.smallSpacing

                Item { Layout.preferredWidth: 24 }
                SiLabel { text: "DF0:"; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 60 }
                SiComboBoxControl {
                    Layout.fillWidth: true
                    enabled: !root.locked
                    model: root.driveTypeNames
                    currentIndex: config.driveType(0)
                    onCurrentIndexChanged: config.setDriveType(0, currentIndex)
                }

                SiCheckBoxControl {
                    Layout.preferredWidth: 24
                    enabled: !root.locked
                    checked: config.driveConnected(1)
                    onClicked: {
                        config.setDriveConnected(1, checked)
                        if (!checked) { config.setDriveConnected(2, false); config.setDriveConnected(3, false) }
                    }
                }
                SiLabel { text: "DF1:"; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 60 }
                SiComboBoxControl {
                    Layout.fillWidth: true
                    enabled: !root.locked && config.driveConnected(1)
                    model: root.driveTypeNames
                    currentIndex: config.driveType(1)
                    onCurrentIndexChanged: config.setDriveType(1, currentIndex)
                }

                SiCheckBoxControl {
                    Layout.preferredWidth: 24
                    enabled: !root.locked && config.driveConnected(1)
                    checked: config.driveConnected(2)
                    onClicked: {
                        config.setDriveConnected(2, checked)
                        if (!checked) config.setDriveConnected(3, false)
                    }
                }
                SiLabel { text: "DF2:"; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 60 }
                SiComboBoxControl {
                    Layout.fillWidth: true
                    enabled: !root.locked && config.driveConnected(2)
                    model: root.driveTypeNames
                    currentIndex: config.driveType(2)
                    onCurrentIndexChanged: config.setDriveType(2, currentIndex)
                }

                SiCheckBoxControl {
                    Layout.preferredWidth: 24
                    enabled: !root.locked && config.driveConnected(2)
                    checked: config.driveConnected(3)
                    onClicked: config.setDriveConnected(3, checked)
                }
                SiLabel { text: "DF3:"; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 60 }
                SiComboBoxControl {
                    Layout.fillWidth: true
                    enabled: !root.locked && config.driveConnected(3)
                    model: root.driveTypeNames
                    currentIndex: config.driveType(3)
                    onCurrentIndexChanged: config.setDriveType(3, currentIndex)
                }
            }

            VSpacer { size: Style.largeSpacing }

            SiText { text: "Game Ports"; font.bold: true; font.pixelSize: Style.large }

            GridLayout {

                columns: 2
                columnSpacing: Style.smallSpacing
                rowSpacing: Style.smallSpacing

                SiLabel { text: "Game 1:"; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 84 }
                SiComboBoxControl { Layout.fillWidth: true; model: ["No device"]; currentIndex: 0 }

                SiLabel { text: "Game 2:"; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 84 }
                SiComboBoxControl { Layout.fillWidth: true; model: ["No device"]; currentIndex: 0 }
            }

            VSpacer { size: Style.largeSpacing }

            SiText { text: "Serial Port"; font.bold: true; font.pixelSize: Style.large }

            GridLayout {

                columns: 2
                columnSpacing: Style.smallSpacing
                rowSpacing: Style.smallSpacing

                SiLabel { text: "Serial:"; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 84 }
                SiComboBoxControl {
                    Layout.fillWidth: true
                    model: root.serialDeviceNames
                    currentIndex: config.SER_DEVICE
                    onCurrentIndexChanged: config.SER_DEVICE = currentIndex
                }

                SiLabel { text: "MIDI Out:"; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 84; visible: config.SER_DEVICE === 5 }
                SiComboBoxControl { Layout.fillWidth: true; visible: config.SER_DEVICE === 5; model: ["None"]; currentIndex: 0 }

                SiLabel { text: "MIDI In:"; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 84; visible: config.SER_DEVICE === 5 }
                SiComboBoxControl { Layout.fillWidth: true; visible: config.SER_DEVICE === 5; model: ["None"]; currentIndex: 0 }
            }

            VSpacer { }
        }

        //
        // Right column: Hard Drives, Joystick
        //

        ColumnLayout {

            Layout.fillWidth: true
            spacing: Style.smallSpacing

            SiText { text: "Hard Drives"; font.bold: true; font.pixelSize: Style.large }

            GridLayout {

                columns: 3
                columnSpacing: Style.smallSpacing
                rowSpacing: Style.smallSpacing

                SiCheckBoxControl {
                    Layout.preferredWidth: 24
                    enabled: !root.locked
                    checked: config.hdConnected(0)
                    onClicked: config.setHdConnected(0, checked)
                }
                SiLabel { text: "HD0:"; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 60 }
                SiComboBoxControl {
                    Layout.fillWidth: true
                    enabled: !root.locked && config.hdConnected(0)
                    model: root.hdTypeNames
                    currentIndex: config.hdType(0)
                    onCurrentIndexChanged: config.setHdType(0, currentIndex)
                }

                SiCheckBoxControl {
                    Layout.preferredWidth: 24
                    enabled: !root.locked
                    checked: config.hdConnected(1)
                    onClicked: config.setHdConnected(1, checked)
                }
                SiLabel { text: "HD1:"; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 60 }
                SiComboBoxControl {
                    Layout.fillWidth: true
                    enabled: !root.locked && config.hdConnected(1)
                    model: root.hdTypeNames
                    currentIndex: config.hdType(1)
                    onCurrentIndexChanged: config.setHdType(1, currentIndex)
                }

                SiCheckBoxControl {
                    Layout.preferredWidth: 24
                    enabled: !root.locked
                    checked: config.hdConnected(2)
                    onClicked: config.setHdConnected(2, checked)
                }
                SiLabel { text: "HD2:"; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 60 }
                SiComboBoxControl {
                    Layout.fillWidth: true
                    enabled: !root.locked && config.hdConnected(2)
                    model: root.hdTypeNames
                    currentIndex: config.hdType(2)
                    onCurrentIndexChanged: config.setHdType(2, currentIndex)
                }

                SiCheckBoxControl {
                    Layout.preferredWidth: 24
                    enabled: !root.locked
                    checked: config.hdConnected(3)
                    onClicked: config.setHdConnected(3, checked)
                }
                SiLabel { text: "HD3:"; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 60 }
                SiComboBoxControl {
                    Layout.fillWidth: true
                    enabled: !root.locked && config.hdConnected(3)
                    model: root.hdTypeNames
                    currentIndex: config.hdType(3)
                    onCurrentIndexChanged: config.setHdType(3, currentIndex)
                }
            }

            VSpacer { size: Style.largeSpacing }

            SiText { text: "Joystick"; font.bold: true; font.pixelSize: Style.large }

            GridLayout {

                columns: 2
                columnSpacing: Style.smallSpacing
                rowSpacing: Style.mediumSpacing

                SiCheckBoxControl {
                    l: "Auto-fire:"
                    lwidth: 84
                    checked: config.JOY1_AUTOFIRE
                    onClicked: root.setAutofire(checked)
                }

                SiSliderControl {
                    Layout.fillWidth: true
                    l: "Slow"
                    r: "Fast"
                    from: 1
                    to: 25
                    enabled: config.JOY1_AUTOFIRE
                    value: config.JOY1_AUTOFIRE_DELAY
                    onMoved: (value) => root.setAutofireDelay(Math.round(value))
                }

                SiCheckBoxControl {
                    l: "Burst Mode:"
                    lwidth: 84
                    checked: config.JOY1_AUTOFIRE_BURSTS
                    onClicked: root.setAutofireBursts(checked)
                }

                SiNumberInputControl {
                    Layout.fillWidth: true
                    enabled: config.JOY1_AUTOFIRE_BURSTS
                    r: "bullets per burst"
                    controlWidth: 48
                    intValue: config.JOY1_AUTOFIRE_BULLETS
                    onValueEdited: (value) => root.setAutofireBullets(value)
                }
            }

            VSpacer { }
        }
    }
}
