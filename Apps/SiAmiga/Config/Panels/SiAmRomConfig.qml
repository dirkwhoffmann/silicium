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
import QtQuick.Dialogs
import QtQuick.Layouts
import Silicium.Assets
import Silicium.Controllers
import Silicium.Theme

// Port of vAmiga's own GUI/Settings/ViewControllers/RomSettings.swift. Only
// two ROM slots -- the Amiga has no BASIC/Kernal/Char/VC1541 split the way
// the C64 does (see SiC64RomConfig.qml) -- Kickstart (required) and an
// optional Extension ROM, plus the Extension ROM's memory-location picker
// (MEM_EXT_START, valid only as $E0 or $F0 -- see Memory::checkOption).
//
// The AROS/EmuTOS/DiagROM one-click installer presets
// (RomSettingsViewController.preset(tag:)) live in the toolbar's burger menu
// below, one item per bundled version -- see ConfigToolbar's menuContent --
// in place of vAmiga's own preset popup. SiAmConfigController has no
// installOpenRoms()/loadMostRecentRoms() equivalent, so drag-and-drop and
// the file-picker/delete buttons remain the only other way in.
Item {

    id: root

    required property SiAmController controller
    readonly property var cc: controller.configController

    readonly property bool locked: controller.isPoweredOn

    // Cap the title/subtitle/details/combo column at half the panel's width,
    // so a tile's total width -- image + spacing + that column -- matches
    // SiRomDropView's own internal RowLayout spacing exactly.
    readonly property real romTileWidth: 120 + Style.mediumSpacing + mainColumn.width / 2

    readonly property string kickTitle: !cc.hasKickRom ? qsTr("Kickstart Rom or Boot Rom") : cc.kickRomTitle
    readonly property string kickSubtitle: !cc.hasKickRom ? qsTr("Required") : cc.kickRomRevision
    readonly property string kickDetails: !cc.hasKickRom ? "" : cc.kickRomReleased
    readonly property url kickIcon: romIcon(cc.hasKickRom, cc.kickRomVendor)

    readonly property string extTitle: !cc.hasExtRom ? qsTr("Kickstart Rom Extension") : cc.extRomTitle
    readonly property string extSubtitle: !cc.hasExtRom ? qsTr("Optional") : cc.extRomRevision
    readonly property string extDetails: !cc.hasExtRom ? "" : cc.extRomReleased
    readonly property url extIcon: romIcon(cc.hasExtRom, cc.extRomVendor)

    function romIcon(has, vendor) {

        if (!has) return Assets.iconUrl(Assets.RomPlain)

        switch (vendor) {
            case "COMMODORE": return Assets.iconUrl(Assets.RomCommodore)
            case "HYPERION":  return Assets.iconUrl(Assets.RomHyperion)
            case "AROS":      return Assets.iconUrl(Assets.RomAros)
            case "DIAG":      return Assets.iconUrl(Assets.RomDiag)
            case "DEMO":      return Assets.iconUrl(Assets.RomDemo)
            case "EMUTOS":    return Assets.iconUrl(Assets.RomEmutos)
            default:          return Assets.iconUrl(Assets.RomUnknown)
        }
    }

    FileDialog {

        id: romFileDialog
        title: qsTr("Select a Rom Image")
        nameFilters: [qsTr("Rom images (*.rom *.bin)"), qsTr("All files (*)")]

        property string romType: ""

        onAccepted: {
            switch (romType) {
                case "kick": cc.loadKickRom(selectedFile); break
                case "ext":  cc.loadExtRom(selectedFile); break
            }
        }
    }

    Pane {

        anchors.fill: parent
        padding: Style.mediumSpacing

        background: Rectangle {
            color: "transparent"
            radius: Style.borderRadius
        }

        ColumnLayout {

            id: mainColumn
            anchors.fill: parent

            ConfigToolbar {

                heading: qsTr("ROM Settings")

                // One-click Rom presets: AROS and DiagROM each get a submenu
                // listing every bundled version (newest first), EmuTOS a
                // single item since only one version is bundled -- see
                // SiAmMediaController::installAros()/installDiagRom()/
                // installEmuTOS(). The CRC32 passed to installAros()/
                // installDiagRom() picks the version; it has to match one of
                // the cases those functions switch on, which in turn has to
                // match a Rom file actually bundled under Shared/Assets/Roms
                // -- see their own comments for why not every version
                // VACore's RomFileTypes.h knows about is offered here.
                menuContent: [
                    SiMenu {
                        title: qsTr("Install AROS")
                        enabled: !root.locked

                        SiMenuItem {
                            text: qsTr("Version 20260820 (newest)")
                            onTriggered: controller.media.installAros(0x7ae94477)
                        }
                        SiMenuItem {
                            text: qsTr("Version 20250219")
                            onTriggered: controller.media.installAros(0xA3232963)
                        }
                        SiMenuItem {
                            text: qsTr("SVN 55696 (SAE version)")
                            onTriggered: controller.media.installAros(0x3F4FCC0A)
                        }
                        SiMenuItem {
                            text: qsTr("SVN 54705 (UAE version)")
                            onTriggered: controller.media.installAros(0x9CE0F009)
                        }
                    },
                    SiMenu {
                        title: qsTr("Install DiagROM")
                        enabled: !root.locked

                        SiMenuItem {
                            text: qsTr("Version 1.3 (newest)")
                            onTriggered: controller.media.installDiagRom(0x55E2E127)
                        }
                        SiMenuItem {
                            text: qsTr("Version 1.2.1")
                            onTriggered: controller.media.installDiagRom(0x850209CD)
                        }
                    },
                    SiMenuItem {
                        text: qsTr("Install EmuTOS 1.3")
                        enabled: !root.locked
                        onTriggered: controller.media.installEmuTOS()
                    }
                ]

                HSpacer { }
                ConfigLock {
                    lockText: root.locked
                    onClicked: controller.powerOnOrOff()
                }
            }

            VSpacer { }

            //
            // Kickstart Rom
            //

            SiRomDropView {

                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: root.romTileWidth
                enabled: !root.locked
                orientation: Qt.LeftToRight
                title: root.kickTitle
                subtitle: root.kickSubtitle
                details: root.kickDetails
                imageSource: root.kickIcon
                libraryRoms: cc.availableKickRoms

                acceptUrls: function (urls) { return cc.isRom(urls[0]) }
                onUrlsDropped: (urls) => cc.loadKickRom(urls[0])
                onDeleteRom: cc.deleteKickRom()
                onInstallRom: (index) => cc.installKickRom(index)
                onClicked: { romFileDialog.romType = "kick"; romFileDialog.open() }
            }

            VSpacer { size: Style.largeSpacing }

            //
            // Extension Rom
            //

            SiRomDropView {

                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: root.romTileWidth
                enabled: !root.locked
                orientation: Qt.LeftToRight
                title: root.extTitle
                subtitle: root.extSubtitle
                details: root.extDetails
                imageSource: root.extIcon
                libraryRoms: cc.availableExtRoms

                acceptUrls: function (urls) { return cc.isRom(urls[0]) }
                onUrlsDropped: (urls) => cc.loadExtRom(urls[0])
                onDeleteRom: cc.deleteExtRom()
                onInstallRom: (index) => cc.installExtRom(index)
                onClicked: { romFileDialog.romType = "ext"; romFileDialog.open() }

                extra: RowLayout {

                    Layout.topMargin: Style.tinySpacing
                    visible: cc.hasExtRom
                    spacing: Style.smallSpacing

                    SiLabel { text: qsTr("Location:") }

                    SiComboBoxControl {

                        model: ["$E00000", "$F00000"]
                        currentIndex: cc.MEM_EXT_START === 0xF0 ? 1 : 0
                        onCurrentIndexChanged: cc.MEM_EXT_START = currentIndex === 1 ? 0xF0 : 0xE0
                    }
                }
            }

            VSpacer { size: Style.largeSpacing }

            RowLayout {

                Layout.alignment: Qt.AlignHCenter
                spacing: Style.mediumSpacing

                SiSymbol { symbol: "info"; size: Size.large; color: Palette.accent }

                ColumnLayout {

                    spacing: 0

                    SiText {
                        text: qsTr("To add a Rom, drag a Rom image file onto one of the chip icons, or click an icon to select a file.")
                        font.bold: true
                        color: Palette.primary
                    }
                    SiText {
                        text: qsTr("Original Roms are protected by copyright. Please obey legal regulations.")
                        color: Palette.secondary
                    }
                }
            }

            VSpacer { }
        }
    }
}
