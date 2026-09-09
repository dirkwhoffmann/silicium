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
                enabled: !root.locked
                checked: true
                hide: true

                SiComboBoxControl {

                    model: root.driveTypeNames
                    currentIndex: config.DF0_TYPE
                    onCurrentIndexChanged: config.DF0_TYPE = currentIndex

                    SiHelpButton {
                        onClicked: root.help("")
                    }
                }
            }

            SiCheckBoxControl {

                lwidth: root.labelWidth
                Layout.fillWidth: true
                l: "Df1:"
                enabled: !root.locked
                checked: config.DF1_CONNECTED
                onClicked: {
                    config.DF1_CONNECTED = checked
                    if (!checked) { config.DF2_CONNECTED = false; config.DF3_CONNECTED = false }
                }

                SiComboBoxControl {

                    model: root.driveTypeNames
                    currentIndex: config.DF1_TYPE
                    onCurrentIndexChanged: config.DF1_TYPE = currentIndex

                    SiHelpButton { opacity: 0 }
                }
            }

            SiCheckBoxControl {

                lwidth: root.labelWidth
                Layout.fillWidth: true
                l: "Df2:"
                enabled: !root.locked
                checked: config.DF2_CONNECTED
                onClicked: {
                    config.DF2_CONNECTED = checked
                    if (!checked) { config.DF3_CONNECTED = false }
                }

                SiComboBoxControl {

                    enabled: !root.locked && config.DF2_CONNECTED
                    model: root.driveTypeNames
                    currentIndex: config.DF2_TYPE
                    onCurrentIndexChanged: config.DF2_TYPE = currentIndex

                    SiHelpButton { opacity: 0 }
                }
            }

            SiCheckBoxControl {

                lwidth: root.labelWidth
                Layout.fillWidth: true
                l: "Df3:"
                enabled: !root.locked
                checked: config.DF3_CONNECTED
                onClicked: {
                    config.DF3_CONNECTED = checked
                }

                SiComboBoxControl {

                    enabled: !root.locked && config.DF3_CONNECTED
                    model: root.driveTypeNames
                    currentIndex: config.DF3_TYPE
                    onCurrentIndexChanged: config.DF3_TYPE = currentIndex

                    SiHelpButton { opacity: 0 }
                }
            }
        }

        //
        // Hard Drives
        //

        ConfigSection {

            header: "Hard Drives"
            size: root.sectionWidth
            rowSpacing: Style.smallSpacing

            SiCheckBoxControl {

                lwidth: root.labelWidth
                Layout.fillWidth: true
                l: "Hd0:"
                enabled: !root.locked
                checked: config.HD0_CONNECTED
                onClicked: config.HD0_CONNECTED = checked

                SiComboBoxControl {

                    enabled: !root.locked && config.HD0_CONNECTED
                    model: root.hdTypeNames
                    currentIndex: config.HD0_TYPE
                    onCurrentIndexChanged: config.HD0_TYPE = currentIndex

                    SiHelpButton { onClicked: root.help("") }
                }
            }

            SiCheckBoxControl {

                lwidth: root.labelWidth
                Layout.fillWidth: true
                l: "Hd1:"
                enabled: !root.locked
                checked: config.HD1_CONNECTED
                onClicked: config.HD1_CONNECTED = checked

                SiComboBoxControl {

                    enabled: !root.locked && config.HD1_CONNECTED
                    model: root.hdTypeNames
                    currentIndex: config.HD1_TYPE
                    onCurrentIndexChanged: config.HD1_TYPE = currentIndex

                    SiHelpButton { opacity: 0 }
                }
            }

            SiCheckBoxControl {

                lwidth: root.labelWidth
                Layout.fillWidth: true
                l: "Hd2:"
                enabled: !root.locked
                checked: config.HD2_CONNECTED
                onClicked: config.HD2_CONNECTED = checked

                SiComboBoxControl {

                    enabled: !root.locked && config.HD2_CONNECTED
                    model: root.hdTypeNames
                    currentIndex: config.HD2_TYPE
                    onCurrentIndexChanged: config.HD2_TYPE = currentIndex

                    SiHelpButton { opacity: 0 }
                }
            }

            SiCheckBoxControl {

                lwidth: root.labelWidth
                Layout.fillWidth: true
                l: "Hd3:"
                enabled: !root.locked
                checked: config.HD3_CONNECTED
                onClicked: config.HD3_CONNECTED = checked

                SiComboBoxControl {

                    enabled: !root.locked && config.HD3_CONNECTED
                    model: root.hdTypeNames
                    currentIndex: config.HD3_TYPE
                    onCurrentIndexChanged: config.HD3_TYPE = currentIndex

                    SiHelpButton { opacity: 0 }
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

                SiHelpButton { opacity: 0 }
            }

            SiComboBoxControl {

                l: "Game 2:"
                lwidth: root.labelWidth
                Layout.fillWidth: true
                model: ["No device"]
                currentIndex: 0

                SiHelpButton { opacity: 0 }
            }
        }

        //
        // Joystick
        //

        ConfigSection {

            header: "Joystick"
            size: root.sectionWidth

            SiCheckBoxControl {

                l: "Auto-fire:"
                lwidth: root.labelWidth
                // SiCheckBoxControl overrides hasFlexControl to false, which
                // is what makes accessoryContainer (holding the slider
                // below) flex in the first place -- see SiControl.qml's
                // 'Layout.fillWidth: !hasFlexControl' on it. But that same
                // override also makes *this* row's own default
                // Layout.fillWidth ('hasFlexControl') false, so without this
                // override the whole row -- and the slider along with it --
                // never grows past its natural size in the first place.
                // Matches the SID2/SID3 rows in SiC64HardwareConfig.qml.
                Layout.fillWidth: true
                checked: config.JOY1_AUTOFIRE
                onClicked: root.setAutofire(checked)

                SiSliderControl {

                    // l: "-"
                    // r: "+"
                    from: 1
                    to: 25
                    enabled: config.JOY1_AUTOFIRE
                    value: config.JOY1_AUTOFIRE_DELAY
                    onMoved: (value) => root.setAutofireDelay(Math.round(value))

                    SiHelpButton { enabled: true; onClicked: root.help("") }
                }
            }

            SiCheckBoxControl {

                l: "Burst Mode:"
                lwidth: root.labelWidth
                checked: config.JOY1_AUTOFIRE_BURSTS
                onClicked: root.setAutofireBursts(checked)

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

                SiHelpButton { opacity: 0 }
            }

            SiComboBoxControl {

                l: "MIDI Out:"
                lwidth: root.labelWidth
                Layout.fillWidth: true
                visible: config.SER_DEVICE === 5
                model: ["None"]
                currentIndex: 0

                SiHelpButton { opacity: 0 }
            }

            SiComboBoxControl {

                l: "MIDI In:"
                lwidth: root.labelWidth
                Layout.fillWidth: true
                visible: config.SER_DEVICE === 5
                model: ["None"]
                currentIndex: 0

                SiHelpButton { opacity: 0 }
            }
        }
    }
}
