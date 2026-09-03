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
// (RomSettingsViewController.preset(tag:)) aren't ported here -- they embed
// actual ROM binaries as app resources, which is a separate asset-bundling
// task, not a UI one. SiAmConfigController doesn't have installOpenRoms()/
// loadMostRecentRoms() counterparts yet either, so drag-and-drop and the
// file-picker/delete buttons are the only ways in for now, matching what
// the controller currently exposes.
Item {

    id: root

    required property SiAmController controller
    readonly property var cc: controller.configController

    readonly property bool locked: controller.isPoweredOn

    readonly property string kickTitle: !cc.hasKickRom ? qsTr("No Rom loaded") : cc.kickRomTitle
    readonly property string kickSubtitle: !cc.hasKickRom ? "" : cc.kickRomRevision
    readonly property string kickDetails: !cc.hasKickRom ? "" : cc.kickRomReleased
    readonly property url kickIcon: romIcon(cc.hasKickRom, cc.kickRomVendor)

    readonly property string extTitle: !cc.hasExtRom ? qsTr("No Rom loaded") : cc.extRomTitle
    readonly property string extSubtitle: !cc.hasExtRom ? "" : cc.extRomRevision
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

    // One ROM slot: the fixed left-hand label (name + Required/Optional),
    // the chip icon (drag-and-drop + click-to-browse) with its delete
    // button below, and the loaded ROM's own title/subtitle/details.
    component RomSlot: RowLayout {

        id: slot

        property string label: ""
        property string requirement: ""
        property url icon: ""
        property string title: ""
        property string subtitle: ""
        property string details: ""

        // Extra content (the Extension Rom's Location combo) appended below
        // the title/subtitle/details column -- aliased to that column's
        // 'data' below rather than declared 'default property' (RomSlot's
        // instantiation already uses its default 'data' for nothing since
        // it's a RowLayout with fixed children, so this needs its own name).
        property alias extra: extraColumn.data

        signal urlsDropped(var urls)
        signal deleteRom()
        signal clicked()

        Layout.fillWidth: true
        spacing: Style.largeSpacing

        ColumnLayout {

            Layout.preferredWidth: 200
            Layout.alignment: Qt.AlignTop
            spacing: 2

            SiText { text: slot.label; font.pixelSize: Style.large; horizontalAlignment: Text.AlignRight; Layout.fillWidth: true }
            SiText { text: slot.requirement; color: Palette.tertiary; horizontalAlignment: Text.AlignRight; Layout.fillWidth: true }
        }

        ColumnLayout {

            Layout.alignment: Qt.AlignTop
            spacing: Style.smallSpacing

            SiImageDropView {

                Layout.preferredWidth: 120
                Layout.preferredHeight: 120
                source: slot.icon

                acceptUrls: function (urls) { return cc.isRom(urls[0]) }
                onUrlsDropped: (urls) => slot.urlsDropped(urls)
                onClicked: slot.clicked()
            }

            SiSymbolButton {

                Layout.alignment: Qt.AlignHCenter
                symbol: "delete"
                size: Size.regular
                onClicked: slot.deleteRom()
            }
        }

        ColumnLayout {

            Layout.alignment: Qt.AlignTop
            Layout.fillWidth: true
            spacing: Style.smallTextSpacing

            SiText { text: slot.title; font.bold: true; color: Palette.primary; Layout.fillWidth: true; elide: Text.ElideRight }
            SiText { text: slot.subtitle; color: Palette.secondary; Layout.fillWidth: true; elide: Text.ElideRight; visible: text !== "" }
            SiText { text: slot.details; color: Palette.tertiary; Layout.fillWidth: true; elide: Text.ElideRight; visible: text !== "" }

            ColumnLayout { id: extraColumn }
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

            anchors.fill: parent

            ConfigToolbar {

                heading: qsTr("ROM Settings")
                HSpacer { }
                ConfigLock {
                    lockText: root.locked
                    onClicked: controller.powerOnOrOff()
                }
            }

            VSpacer { }

            //
            // Kickstart / Boot Rom
            //

            RomSlot {

                enabled: !root.locked
                label: qsTr("Kickstart Rom or Boot Rom")
                requirement: qsTr("(Required)")
                icon: root.kickIcon
                title: root.kickTitle
                subtitle: root.kickSubtitle
                details: root.kickDetails

                onUrlsDropped: (urls) => cc.loadKickRom(urls[0])
                onDeleteRom: cc.deleteKickRom()
                onClicked: { romFileDialog.romType = "kick"; romFileDialog.open() }
            }

            VSpacer { size: Style.largeSpacing }

            //
            // Extension Rom
            //

            RomSlot {

                id: extSlot
                enabled: !root.locked
                label: qsTr("Kickstart Rom Extension")
                requirement: qsTr("(Optional)")
                icon: root.extIcon
                title: root.extTitle
                subtitle: root.extSubtitle
                details: root.extDetails

                onUrlsDropped: (urls) => cc.loadExtRom(urls[0])
                onDeleteRom: cc.deleteExtRom()
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
