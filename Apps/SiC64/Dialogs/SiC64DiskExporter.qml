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
import QtQuick.Dialogs
import Silicium.Assets
import Silicium.Controllers
import Silicium.Theme

// Ports the old Swift-based emulator's DiskExporter sheet: lets the user pick
// an export format, then hands off to a native file/folder picker. T64 and
// PRG aren't offered here (unlike the original) since the core's codec only
// implements D64 encoding right now -- see FloppyDisk::writeToFile.
SiDialog {

    id: root

    required property C64Controller c64
    property int driveNr: 8

    readonly property int labelWidth: 90
    readonly property bool folderSelected: formatCombo.currentIndex === 1

    width: 460

    onOpened: formatCombo.currentIndex = 0

    function doExport() {
        if (folderSelected) {
            folderDialog.open()
        } else {
            fileDialog.open()
        }
    }

    RowLayout {

        Layout.fillWidth: true
        spacing: Style.largeSpacing

        //
        // Disk icon
        //

        Rectangle {

            Layout.preferredWidth: 110
            Layout.preferredHeight: 110
            Layout.alignment: Qt.AlignTop
            radius: Style.borderRadius
            color: Palette.surfaceElevated

            Image {
                anchors.centerIn: parent
                width: parent.width * 0.7
                height: parent.height * 0.7
                fillMode: Image.PreserveAspectFit
                source: Assets.iconUrl(Assets.Media525DDCbm)
            }
        }

        //
        // Form
        //

        ColumnLayout {

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            spacing: Style.mediumSpacing

            SiText {
                text: qsTr("Commodore Floppy Disk")
                font.bold: true
                font.pixelSize: Style.large
                Layout.fillWidth: true
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: Style.smallSpacing
                Layout.bottomMargin: Style.smallSpacing
                height: 1
                color: Palette.border
            }

            SiComboBoxControl {
                id: formatCombo
                l: qsTr("Export As:")
                lwidth: root.labelWidth
                model: [qsTr("D64"), qsTr("Folder")]
            }

            Item { Layout.fillHeight: true }
        }
    }

    footer: Item {

        implicitHeight: footerRow.implicitHeight + Style.largeSpacing

        RowLayout {

            id: footerRow
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Style.largeSpacing
            anchors.topMargin: 0
            spacing: Style.mediumSpacing

            SiButton {
                text: qsTr("Cancel")
                onClicked: root.close()
            }

            Item { Layout.fillWidth: true }

            Button {

                id: exportButton
                text: qsTr("Export")
                implicitHeight: 24
                implicitWidth: Math.max(80, contentItem.implicitWidth + 24)
                leftPadding: 12
                rightPadding: 12

                background: Rectangle {
                    radius: 3
                    color: exportButton.down ? Palette.accentElevated : Palette.accent
                }

                contentItem: SiText {
                    text: exportButton.text
                    color: Palette.accentText
                    font.family: Fonts.main
                    font.pixelSize: Style.regular
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: root.doExport()
            }
        }
    }

    FileDialog {

        id: fileDialog
        title: qsTr("Export Disk")
        fileMode: FileDialog.SaveFile
        nameFilters: [qsTr("D64 disk image (*.d64)")]
        defaultSuffix: "d64"

        onAccepted: {
            root.c64.exportDisk(root.driveNr, selectedFile)
            root.close()
        }
    }

    FolderDialog {

        id: folderDialog
        title: qsTr("Export Disk")

        onAccepted: {
            root.c64.exportDiskFolder(root.driveNr, selectedFolder)
            root.close()
        }
    }
}
