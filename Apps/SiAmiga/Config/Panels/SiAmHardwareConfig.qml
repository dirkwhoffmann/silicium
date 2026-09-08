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

// Port of vAmiga's own GUI/Settings/ViewControllers/HardwareSettings.swift.
// ConfigGrid/ConfigSection cards, one per hardware component, matching
// SiC64HardwareConfig's layout.
//
// The chip-model preset combos (Amiga 500/1000/2000/500+/1200 --
// HardwareSettingsViewController.preset(tag:)) aren't ported: they'd need a
// second combo box this panel doesn't have room for without a screenshot to
// match, and every option they set is already reachable individually here.
SettingsPage {

    id: root

    required property SiAmController controller
    readonly property var config: controller.configController

    readonly property int labelWidth: 100
    readonly property int sectionWidth: 320

    // Agnus revision, Chip/Slow/Fast Ram and the RTC model can only be
    // changed while the machine is off (see Agnus/Memory/RTC::checkOption's
    // isPoweredOff() guards in VACore) -- the core silently refuses the
    // change otherwise, which used to go unnoticed because nothing ever
    // re-read the rejected value back into the combo box. Gate those rows
    // on this so the panel can't misrepresent a change that never took.
    readonly property bool locked: controller.isPoweredOn

    // Chip Ram address ceiling per Agnus revision (in KB) -- matches
    // HardwareSettingsViewController's 'badAgnus' warning, which compares
    // the selected Chip Ram against AgnusTraits.chipRamLimit for the
    // selected revision.
    readonly property var chipRamLimits: [512, 512, 1024, 2048, 2048]
    readonly property bool badAgnus: chipRamLimits[config.AGNUS_REVISION] < config.MEM_CHIP_RAM

    function cpuInfo(rev) {
        switch (rev) {
            case 0: return ["Motorola MC68000", "Original Amigas"]
            case 1: return ["Motorola MC68010", ""]
            case 2: return ["Motorola 68EC020", "A1200, A2500"]
            default: return ["Invalid", ""]
        }
    }

    function agnusInfo(rev, pal) {
        switch (rev) {
            case 0: return [pal ? "MOS 8367" : "MOS 8361", "A1000, A2000A"]
            case 1: return [pal ? "MOS 8371" : "MOS 8370", "Early A500, A2000"]
            case 2: return ["MOS 8372A", "Later A500, A2000"]
            case 3: return ["MOS 8375", "A500+, A600"]
            case 4: return ["MOS 8374 (Alice)", "A1200, A4000"]
            default: return ["Invalid", ""]
        }
    }

    function deniseInfo(rev) {
        switch (rev) {
            case 0: return ["MOS 8362R8", "A500, A1000, A2000"]
            case 1: return ["MOS 8373R4", "A500+, A600"]
            case 2: return ["MOS 5721 (Lisa)", "A1200, A4000"]
            default: return ["Invalid", ""]
        }
    }

    function ciaInfo(rev) {
        switch (rev) {
            case 0: return ["MOS 8520", "A500, A1000, A2000, A500+"]
            case 1: return ["MOS 8520PL", "A600"]
            default: return ["Invalid", ""]
        }
    }

    function rtcInfo(rev) {
        switch (rev) {
            case 0: return ["", ""]
            case 1: return ["MSM6242B", "A2000, A500+"]
            case 2: return ["RF5C01A", "A3000, A4000"]
            default: return ["Invalid", ""]
        }
    }

    toolbar: ConfigToolbar {

        heading: "Hardware Settings"

        menuContent: [
            MenuItem {
                text: "Restore factory defaults..."
                onTriggered: config.restoreHardwareDefaults()
            }
        ]

        HSpacer { }

        ConfigLock {
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
            SiText { text: title; color: Palette.primary }
            SiText { text: subtitle; color: Palette.secondary; visible: subtitle !== "" }
        }
    }

    // A label+combo(s) row (the row's own contents go in via the default
    // property) paired with the InfoBox describing the current selection.
    component ConfigBox: ColumnLayout {

        id: box

        property string title: ""
        property string subtitle: ""

        // Lets a caller hide the InfoBox on its own (e.g. Slow/Fast Ram,
        // whose row stays visible at 0 KB but whose info line shouldn't).
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
            // opacity, not visible -- keeps the row's height reserved so
            // hiding the info (e.g. Slow/Fast Ram at 0 KB) doesn't make the
            // rows below jump up.
            opacity: box.showInfo ? 1 : 0
        }
    }

    ConfigGrid {

        id: grid

        //
        // Chipset
        //

        ConfigSection {

            header: "Chipset"
            size: root.sectionWidth

            ConfigBox {
                title: root.cpuInfo(config.CPU_REVISION)[0]
                subtitle: root.cpuInfo(config.CPU_REVISION)[1]

                SiLabel { text: "CPU:"; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: root.labelWidth }
                SiComboBoxControl {
                    model: ["68000", "68010", "68EC020"]
                    currentIndex: config.CPU_REVISION
                    onCurrentIndexChanged: config.CPU_REVISION = currentIndex
                }
                SiComboBoxControl {
                    model: ["7 MHz", "14 MHz", "28 MHz", "56 MHz"]
                    currentIndex: config.CPU_OVERCLOCKING
                    onCurrentIndexChanged: config.CPU_OVERCLOCKING = currentIndex
                }
            }

            ConfigBox {
                // Only the revision combo is power-locked; the video format
                // isn't (see Amiga::checkOption), so it stays enabled -- the
                // box as a whole can't be disabled without taking that down
                // with it, so the combo gets its own 'enabled' below instead.
                title: root.agnusInfo(config.AGNUS_REVISION, config.AMIGA_VIDEO_FORMAT === 0)[0]
                subtitle: root.agnusInfo(config.AGNUS_REVISION, config.AMIGA_VIDEO_FORMAT === 0)[1]

                SiLabel { text: "Agnus:"; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: root.labelWidth }
                SiComboBoxControl {
                    enabled: !root.locked
                    model: ["Early OCS", "OCS", "ECS (1MB)", "ECS (2MB)", "AGA"]
                    currentIndex: config.AGNUS_REVISION
                    onCurrentIndexChanged: config.AGNUS_REVISION = currentIndex
                }
                SiComboBoxControl {
                    model: ["PAL", "NTSC"]
                    currentIndex: config.AMIGA_VIDEO_FORMAT
                    onCurrentIndexChanged: config.AMIGA_VIDEO_FORMAT = currentIndex
                }
            }

            ConfigBox {
                title: root.deniseInfo(config.DENISE_REVISION)[0]
                subtitle: root.deniseInfo(config.DENISE_REVISION)[1]

                SiLabel { text: "Denise:"; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: root.labelWidth }
                SiComboBoxControl {
                    model: ["OCS", "ECS", "AGA"]
                    currentIndex: config.DENISE_REVISION
                    onCurrentIndexChanged: config.DENISE_REVISION = currentIndex
                }
            }

            ConfigBox {
                title: root.ciaInfo(config.CIA_A_REVISION)[0]
                subtitle: root.ciaInfo(config.CIA_A_REVISION)[1]

                SiLabel { text: "CIAs:"; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: root.labelWidth }
                SiComboBoxControl {
                    model: ["DIP", "PLCC"]
                    currentIndex: config.CIA_A_REVISION
                    onCurrentIndexChanged: { config.CIA_A_REVISION = currentIndex; config.CIA_B_REVISION = currentIndex }
                }
            }

            ConfigBox {
                enabled: !root.locked
                title: root.rtcInfo(config.RTC_MODEL)[0]
                subtitle: root.rtcInfo(config.RTC_MODEL)[1]

                SiLabel { text: "RTC:"; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: root.labelWidth }
                SiComboBoxControl {
                    model: ["None", "OKI", "Ricoh"]
                    currentIndex: config.RTC_MODEL
                    onCurrentIndexChanged: config.RTC_MODEL = currentIndex
                }
            }
        }

        //
        // Memory
        //

        ConfigSection {

            header: "Memory"
            size: root.sectionWidth

            ConfigBox {
                enabled: !root.locked
                title: "DRAM"
                subtitle: "%1 - %2".arg(formatAddr(0)).arg(formatAddr(config.MEM_CHIP_RAM * 1024 - 1))

                SiSymbol {
                    visible: root.badAgnus
                    symbol: "warning"
                    color: Palette.warning
                    ToolTip.visible: badAgnusHover.hovered
                    ToolTip.text: "Chip Ram is not fully usable. The selected Agnus revision is limited to address %1 KB.".arg(root.chipRamLimits[config.AGNUS_REVISION])
                    HoverHandler { id: badAgnusHover }
                }
                SiLabel { text: "Chip Ram:"; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: root.labelWidth }
                SiComboBoxControl {
                    model: ["256 KB", "512 KB", "1024 KB", "2048 KB"]
                    currentIndex: [256, 512, 1024, 2048].indexOf(config.MEM_CHIP_RAM)
                    onCurrentIndexChanged: config.MEM_CHIP_RAM = [256, 512, 1024, 2048][currentIndex]
                }
            }

            ConfigBox {
                enabled: !root.locked
                title: "DRAM"
                subtitle: "%1 - %2".arg(formatAddr(0xC00000)).arg(formatAddr(0xC00000 + config.MEM_SLOW_RAM * 1024 - 1))
                showInfo: config.MEM_SLOW_RAM > 0

                SiLabel { text: "Slow Ram:"; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: root.labelWidth }
                SiComboBoxControl {
                    model: ["None", "256 KB", "512 KB", "768 KB", "1024 KB", "1280 KB", "1536 KB"]
                    currentIndex: config.MEM_SLOW_RAM / 256
                    onCurrentIndexChanged: config.MEM_SLOW_RAM = currentIndex * 256
                }
            }

            ConfigBox {
                enabled: !root.locked
                title: "DRAM"
                subtitle: "%1 - %2".arg(formatAddr(0x200000)).arg(formatAddr(0x200000 + config.MEM_FAST_RAM * 1024 - 1))
                showInfo: config.MEM_FAST_RAM > 0

                SiLabel { text: "Fast Ram:"; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: root.labelWidth }
                SiComboBoxControl {
                    model: ["None", "64 KB", "128 KB", "256 KB", "512 KB", "1024 KB", "2048 KB", "4096 KB", "8192 KB"]
                    currentIndex: [0, 64, 128, 256, 512, 1024, 2048, 4096, 8192].indexOf(config.MEM_FAST_RAM)
                    onCurrentIndexChanged: config.MEM_FAST_RAM = [0, 64, 128, 256, 512, 1024, 2048, 4096, 8192][currentIndex]
                }
            }

            GridLayout {

                Layout.topMargin: Style.smallSpacing
                columns: 2
                columnSpacing: Style.smallSpacing
                rowSpacing: Style.mediumSpacing

                SiLabel { text: "Bus width:"; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: root.labelWidth }
                SiComboBoxControl {
                    model: ["16 Bit", "32 Bit"]
                    currentIndex: config.MEM_BUS_WIDTH === 32 ? 1 : 0
                    onCurrentIndexChanged: config.MEM_BUS_WIDTH = currentIndex === 1 ? 32 : 16
                }

                SiLabel { text: "Bank Map:"; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: root.labelWidth }
                SiComboBoxControl {
                    model: ["Amiga 500", "Amiga 1000", "Amiga 2000 (Rev A)", "Amiga 2000 (Rev B)", "Amiga 1200"]
                    currentIndex: config.MEM_BANKMAP
                    onCurrentIndexChanged: config.MEM_BANKMAP = currentIndex
                }

                SiLabel { text: "Init Pattern:"; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: root.labelWidth }
                SiComboBoxControl {
                    model: ["All zeroes", "All ones", "Randomized"]
                    currentIndex: config.MEM_RAM_INIT_PATTERN
                    onCurrentIndexChanged: config.MEM_RAM_INIT_PATTERN = currentIndex
                }

                SiLabel { text: "Unmapped area:"; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: root.labelWidth }
                SiComboBoxControl {
                    model: ["Floating", "All zeroes", "All ones"]
                    currentIndex: config.MEM_UNMAPPING_TYPE
                    onCurrentIndexChanged: config.MEM_UNMAPPING_TYPE = currentIndex
                }
            }
        }
    }

    function formatAddr(addr) {
        return "0x" + addr.toString(16).toUpperCase().padStart(6, "0")
    }
}
