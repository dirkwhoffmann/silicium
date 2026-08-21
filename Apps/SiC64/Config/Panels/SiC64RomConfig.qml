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
import Silicium.Preferences
import Silicium.Theme

Item {

    id: root
    required property C64Controller controller
    readonly property var cc: controller.configController

    readonly property string basicRomTitle: !cc ? "" : !cc.hasBasicRom ? "Basic ROM" : cc.basicRomTitle
    readonly property string basicRomSubtitle: !cc ? "" : !cc.hasBasicRom ? "Required" : cc.basicRomSubtitle
    readonly property string basicRomRevision: !cc ? "" : !cc.hasBasicRom ? "" : cc.basicRomRevision
    readonly property string basicRomIcon: !cc ? "" : cc.basicRomIcon

    readonly property string kernalRomTitle: !cc ? "" : !cc.hasKernalRom ? "Kernal ROM" : cc.kernalRomTitle
    readonly property string kernalRomSubtitle: !cc ? "" : !cc.hasKernalRom ? "Required" : cc.kernalRomSubtitle
    readonly property string kernalRomRevision: !cc ? "" : !cc.hasKernalRom ? "" : cc.kernalRomRevision
    readonly property string kernalRomIcon: !cc ? "" : cc.kernalRomIcon

    readonly property string charRomTitle: !cc ? "" : !cc.hasCharRom ? "Character ROM" : cc.charRomTitle
    readonly property string charRomSubtitle: !cc ? "" : !cc.hasCharRom ? "Required" : cc.charRomSubtitle
    readonly property string charRomRevision: !cc ? "" : !cc.hasCharRom ? "" : cc.charRomRevision
    readonly property string charRomIcon: !cc ? "" : cc.charRomIcon

    readonly property string vc1541RomTitle: !cc ? "" : !cc.hasVC1541Rom ? "VC1541 ROM" : cc.vc1541RomTitle
    readonly property string vc1541RomSubtitle: !cc ? "" : !cc.hasVC1541Rom ? "Optional" : cc.vc1541RomSubtitle
    readonly property string vc1541RomRevision: !cc ? "" : !cc.hasVC1541Rom ? "" : cc.vc1541RomRevision
    readonly property string vc1541RomIcon: !cc ? "" : cc.vc1541RomIcon

    readonly property bool hasRecentRoms: Preferences.basicPath.toString() !== ""
                                        || Preferences.charPath.toString() !== ""
                                        || Preferences.kernalPath.toString() !== ""
                                        || Preferences.vc1541Path.toString() !== ""

    /* The ROMs are what the machine booted from, so swapping one underneath a
     * live machine is not meaningful -- the lock is tied to power, not to
     * RUNNING, because a paused machine holds exactly the same ROMs (see
     * C64Controller::isPoweredOn). ConfigLock's button powers down, which is
     * what unlocks the panel.
     */
    readonly property bool locked: controller.isPoweredOn

    FileDialog {

        id: romFileDialog
        title: "Select a Rom Image"
        nameFilters: ["Rom images (*.rom *.bin)", "All files (*)"]

        // Set right before opening, so onAccepted knows which slot to load into
        property string romType: ""

        onAccepted: {
            switch (romType) {
                case "basic":  cc.loadBasicRom(selectedFile); break
                case "kernal": cc.loadKernalRom(selectedFile); break
                case "char":   cc.loadCharRom(selectedFile); break
                case "vc1541": cc.loadVC1541Rom(selectedFile); break
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

            anchors.fill: parent

            ConfigToolbar {

                heading: "ROM Settings"
                menuContent: [
                    SiMenuItem {
                        text: "Install OpenROMs"
                        enabled: !root.locked
                        onTriggered: cc.installOpenRoms()
                    },
                    SiMenuItem {
                        text: "Load most recently used custom ROMs"
                        enabled: !root.locked && root.hasRecentRoms
                        onTriggered: cc.loadMostRecentRoms()
                    }
                ]

                HSpacer { }

                ConfigLock {

                    lockText: root.locked
                    onClicked: controller.powerOnOrOff()
                }
            }

            VSpacer { }

            GridLayout {

                Layout.fillWidth: true
                columns: 2
                rowSpacing: Style.mediumSpacing
                columnSpacing: Style.mediumSpacing

                //
                // BASIC ROM
                //

                SiRomDropView {

                    Layout.fillWidth: true
                    enabled: !root.locked
                    orientation: Qt.RightToLeft
                    title: basicRomTitle
                    subtitle: basicRomSubtitle
                    details: basicRomRevision
                    imageSource: basicRomIcon

                    acceptUrls: function (urls) { return cc.isBasicRom(urls[0]) }
                    onUrlsDropped: (urls) => { cc.loadBasicRom(urls[0]) }
                    onDeleteRom: cc.deleteBasicRom()
                    onClicked: { romFileDialog.romType = "basic"; romFileDialog.open() }
                }

                //
                // KERNAL ROM
                //

                SiRomDropView {

                    Layout.fillWidth: true
                    enabled: !root.locked
                    orientation: Qt.LeftToRight
                    title: kernalRomTitle
                    subtitle: kernalRomSubtitle
                    details: kernalRomRevision
                    imageSource: kernalRomIcon

                    acceptUrls: function (urls) { return cc.isKernalRom(urls[0]) }
                    onUrlsDropped: (urls) => { cc.loadKernalRom(urls[0]) }
                    onDeleteRom: cc.deleteKernalRom()
                    onClicked: { romFileDialog.romType = "kernal"; romFileDialog.open() }
                }

                //
                // CHAR ROM
                //

                SiRomDropView {

                    Layout.fillWidth: true
                    enabled: !root.locked
                    orientation: Qt.RightToLeft
                    title: charRomTitle
                    subtitle: charRomSubtitle
                    details: charRomRevision
                    imageSource: charRomIcon

                    acceptUrls: function (urls) { return cc.isCharRom(urls[0]) }
                    onUrlsDropped: (urls) => { cc.loadCharRom(urls[0]) }
                    onDeleteRom: cc.deleteCharRom()
                    onClicked: { romFileDialog.romType = "char"; romFileDialog.open() }
                }

                //
                // VC1541 ROM
                //

                SiRomDropView {

                    Layout.fillWidth: true
                    enabled: !root.locked
                    orientation: Qt.LeftToRight
                    title: vc1541RomTitle
                    subtitle: vc1541RomSubtitle
                    details: vc1541RomRevision
                    imageSource: vc1541RomIcon

                    acceptUrls: function (urls) { return cc.isVC1541Rom(urls[0]) }
                    onUrlsDropped: (urls) => { cc.loadVC1541Rom(urls[0]) }
                    onDeleteRom: cc.deleteVC1541Rom()
                    onClicked: { romFileDialog.romType = "vc1541"; romFileDialog.open() }
                }
            }

            VSpacer {
                size: Style.largeSpacing
            }

            ColumnLayout {

                Layout.alignment: Qt.AlignHCenter
                spacing: 0

                SiText {
                    text: "To add a Rom, drag a Rom image file onto one of the four chip icons, or click an icon to select a file."
                    Layout.alignment: Qt.AlignHCenter
                    font.bold: true
                    color: Palette.primary
                }
                SiText {
                    text: "Original Roms are protected by copyright. Please obey legal regulations."
                    Layout.alignment: Qt.AlignHCenter
                    font.bold: false
                    color: Palette.secondary
                }
            }

            VSpacer {
            }
        }
    }
}