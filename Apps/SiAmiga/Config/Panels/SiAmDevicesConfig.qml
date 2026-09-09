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
import Silicium.Theme

// Port of vAmiga's own GUI/Settings/ViewControllers/PeripheralsSettings.swift.
// ConfigGrid/ConfigSection cards, one per device group, matching
// SiAmHardwareConfig's layout -- Floppy Drives, Hard Drives, Game Ports,
// Joystick, Serial Port, in that order so the row-major 2-column grid
// keeps Floppy/Game Ports/Serial Port on the left and Hard Drives/Joystick
// on the right, the same grouping the old two-column form had.
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

    readonly property int labelWidth: 90
    readonly property int sectionWidth: 320

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

    component InfoBox: RowLayout {

        property string title: ""
        property string subtitle: ""

        Layout.leftMargin: root.labelWidth + Style.smallSpacing
        spacing: Style.smallSpacing
        visible: title !== ""

        Image {
            source: Assets.iconUrl(Assets.RomPlain)
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36
            fillMode: Image.PreserveAspectFit
        }

        ColumnLayout {
            spacing: 0
            SiLabel { text: title; color: Palette.primary; size: Size.regular; font.bold: false }
            SiLabel { text: subtitle; color: Palette.secondary; size: Size.small; visible: subtitle !== "" }
        }
    }

    // A label+combo(s) row (the row's own contents go in via the default
    // property) paired with the InfoBox describing the current selection.
    component ConfigBox: ColumnLayout {

        id: box

        property string title: ""
        property string subtitle: ""
        property bool showInfo: title !== ""

        default property alias content: row.data

        spacing: Style.mediumSpacing
        opacity: enabled ? 1.0 : 0.4

        RowLayout {
            id: row
            spacing: Style.smallSpacing
        }

        InfoBox {
            title: box.title
            subtitle: box.subtitle
            visible: box.showInfo
        }
    }

    ConfigGrid {

        id: grid

        //
        // Floppy Drives
        //

        ConfigSection {

            header: "Floppy Drives"
            size: root.sectionWidth
            rowSpacing: Style.smallSpacing

            SiCheckBoxControl {

                lwidth: root.labelWidth
                Layout.fillWidth: true
                l: "Df0:"

                SiComboBoxControl {

                    model: root.driveTypeNames
                    currentIndex: config.driveType(0)
                    onCurrentIndexChanged: config.setDriveType(0, currentIndex)

                    SiHelpButton {
                        onClicked: root.help("")
                    }
                }
                checked: config.SID_ENABLE1
                onClicked: config.SID_ENABLE1 = checked;
            }

            SiCheckBoxControl {

                lwidth: root.labelWidth
                Layout.fillWidth: true
                l: "Df1:"

                SiComboBoxControl {

                    model: root.driveTypeNames
                    currentIndex: config.driveType(1)
                    onCurrentIndexChanged: config.setDriveType(1, currentIndex)

                    SiHelpButton {
                        onClicked: root.help("")
                    }
                }

                enabled: !root.locked
                checked: config.driveConnected(1)
                onClicked: {
                    config.setDriveConnected(1, checked)
                    if (!checked) { config.setDriveConnected(2, false); config.setDriveConnected(3, false) }
                }
            }

            SiCheckBoxControl {

                lwidth: root.labelWidth
                Layout.fillWidth: true
                l: "Df2:"

                SiComboBoxControl {

                    model: root.driveTypeNames
                    currentIndex: config.driveType(2)
                    onCurrentIndexChanged: config.setDriveType(2, currentIndex)
                }

                enabled: !root.locked
                checked: config.driveConnected(2)
                onClicked: {
                    config.setDriveConnected(2, checked)
                    if (!checked) { config.setDriveConnected(3, false) }
                }
            }

            SiCheckBoxControl {

                lwidth: root.labelWidth
                Layout.fillWidth: true
                l: "Df3:"

                SiComboBoxControl {

                    model: root.driveTypeNames
                    currentIndex: config.driveType(3)
                    onCurrentIndexChanged: config.setDriveType(3, currentIndex)
                }

                enabled: !root.locked
                checked: config.driveConnected(3)
                onClicked: {
                    config.setDriveConnected(3, checked)
                }
            }

            /*
            SiComboBoxControl {

                l: "DF0:"
                lwidth: root.labelWidth
                Layout.fillWidth: true
                enabled: !root.locked
                model: root.driveTypeNames
                currentIndex: config.driveType(0)
                onCurrentIndexChanged: config.setDriveType(0, currentIndex)
            }

            ConfigBox {

                // Placeholder matching the connect checkbox's width below,
                // so "DF0:" lines up with "DF1:"/"DF2:"/"DF3:" -- DF0 is
                // always connected and has no checkbox of its own.
                Item { Layout.preferredWidth: 24 }

                SiComboBoxControl {

                    l: "DF0:"
                    lwidth: root.labelWidth
                    Layout.fillWidth: true
                    enabled: !root.locked
                    model: root.driveTypeNames
                    currentIndex: config.driveType(0)
                    onCurrentIndexChanged: config.setDriveType(0, currentIndex)
                }
            }

            ConfigBox {

                SiCheckBoxControl {
                    Layout.preferredWidth: 24
                    enabled: !root.locked
                    checked: config.driveConnected(1)
                    onClicked: {
                        config.setDriveConnected(1, checked)
                        if (!checked) { config.setDriveConnected(2, false); config.setDriveConnected(3, false) }
                    }
                }

                SiComboBoxControl {

                    l: "DF1:"
                    lwidth: root.labelWidth
                    Layout.fillWidth: true
                    enabled: !root.locked && config.driveConnected(1)
                    model: root.driveTypeNames
                    currentIndex: config.driveType(1)
                    onCurrentIndexChanged: config.setDriveType(1, currentIndex)
                }
            }



            ConfigBox {

                SiCheckBoxControl {
                    Layout.preferredWidth: 24
                    enabled: !root.locked && config.driveConnected(1)
                    checked: config.driveConnected(2)
                    onClicked: {
                        config.setDriveConnected(2, checked)
                        if (!checked) config.setDriveConnected(3, false)
                    }
                }

                SiComboBoxControl {

                    l: "DF2:"
                    lwidth: root.labelWidth
                    Layout.fillWidth: true
                    enabled: !root.locked && config.driveConnected(2)
                    model: root.driveTypeNames
                    currentIndex: config.driveType(2)
                    onCurrentIndexChanged: config.setDriveType(2, currentIndex)
                }
            }

            ConfigBox {

                SiCheckBoxControl {
                    Layout.preferredWidth: 24
                    enabled: !root.locked && config.driveConnected(2)
                    checked: config.driveConnected(3)
                    onClicked: config.setDriveConnected(3, checked)
                }

                SiComboBoxControl {

                    l: "DF3:"
                    lwidth: root.labelWidth
                    Layout.fillWidth: true
                    enabled: !root.locked && config.driveConnected(3)
                    model: root.driveTypeNames
                    currentIndex: config.driveType(3)
                    onCurrentIndexChanged: config.setDriveType(3, currentIndex)
                }
            }

             */
        }

        //
        // Hard Drives
        //

        ConfigSection {

            header: "Hard Drives"
            size: root.sectionWidth
            rowSpacing: Style.smallSpacing

            ConfigBox {

                SiCheckBoxControl {
                    Layout.preferredWidth: 24
                    enabled: !root.locked
                    checked: config.hdConnected(0)
                    onClicked: config.setHdConnected(0, checked)
                }

                SiComboBoxControl {

                    l: "HD0:"
                    lwidth: root.labelWidth
                    Layout.fillWidth: true
                    enabled: !root.locked && config.hdConnected(0)
                    model: root.hdTypeNames
                    currentIndex: config.hdType(0)
                    onCurrentIndexChanged: config.setHdType(0, currentIndex)
                }
            }

            ConfigBox {

                SiCheckBoxControl {
                    Layout.preferredWidth: 24
                    enabled: !root.locked
                    checked: config.hdConnected(1)
                    onClicked: config.setHdConnected(1, checked)
                }

                SiComboBoxControl {

                    l: "HD1:"
                    lwidth: root.labelWidth
                    Layout.fillWidth: true
                    enabled: !root.locked && config.hdConnected(1)
                    model: root.hdTypeNames
                    currentIndex: config.hdType(1)
                    onCurrentIndexChanged: config.setHdType(1, currentIndex)
                }
            }

            ConfigBox {

                SiCheckBoxControl {
                    Layout.preferredWidth: 24
                    enabled: !root.locked
                    checked: config.hdConnected(2)
                    onClicked: config.setHdConnected(2, checked)
                }

                SiComboBoxControl {

                    l: "HD2:"
                    lwidth: root.labelWidth
                    Layout.fillWidth: true
                    enabled: !root.locked && config.hdConnected(2)
                    model: root.hdTypeNames
                    currentIndex: config.hdType(2)
                    onCurrentIndexChanged: config.setHdType(2, currentIndex)
                }
            }

            ConfigBox {

                SiCheckBoxControl {
                    Layout.preferredWidth: 24
                    enabled: !root.locked
                    checked: config.hdConnected(3)
                    onClicked: config.setHdConnected(3, checked)
                }

                SiComboBoxControl {

                    l: "HD3:"
                    lwidth: root.labelWidth
                    Layout.fillWidth: true
                    enabled: !root.locked && config.hdConnected(3)
                    model: root.hdTypeNames
                    currentIndex: config.hdType(3)
                    onCurrentIndexChanged: config.setHdType(3, currentIndex)
                }
            }
        }

        //
        // Game Ports
        //

        ConfigSection {

            header: "Game Ports"
            size: root.sectionWidth

            SiComboBoxControl {
                l: "Game 1:"
                lwidth: root.labelWidth
                Layout.fillWidth: true
                model: ["No device"]
                currentIndex: 0
            }

            SiComboBoxControl {
                l: "Game 2:"
                lwidth: root.labelWidth
                Layout.fillWidth: true
                model: ["No device"]
                currentIndex: 0
            }
        }

        //
        // Joystick
        //

        ConfigSection {

            header: "Joystick"
            size: root.sectionWidth

            ConfigBox {

                SiCheckBoxControl {
                    l: "Auto-fire:"
                    lwidth: root.labelWidth
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
            }

            ConfigBox {

                SiCheckBoxControl {
                    l: "Burst Mode:"
                    lwidth: root.labelWidth
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
        }

        //
        // Serial Port
        //

        ConfigSection {

            header: "Serial Port"
            size: root.sectionWidth

            SiComboBoxControl {
                l: "Serial:"
                lwidth: root.labelWidth
                Layout.fillWidth: true
                model: root.serialDeviceNames
                currentIndex: config.SER_DEVICE
                onCurrentIndexChanged: config.SER_DEVICE = currentIndex
            }

            SiComboBoxControl {
                l: "MIDI Out:"
                lwidth: root.labelWidth
                Layout.fillWidth: true
                visible: config.SER_DEVICE === 5
                model: ["None"]
                currentIndex: 0
            }

            SiComboBoxControl {
                l: "MIDI In:"
                lwidth: root.labelWidth
                Layout.fillWidth: true
                visible: config.SER_DEVICE === 5
                model: ["None"]
                currentIndex: 0
            }
        }
    }
}
