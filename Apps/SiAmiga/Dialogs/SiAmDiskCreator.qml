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

/* Formats a blank floppy disk and inserts it.
 *
 * The SiAmiga counterpart to SiC64DiskCreator, and the port of vAmiga's own
 * FloppyCreator (GUI/Dialogs/FloppyCreator.swift). What differs from the C64
 * is what an Amiga disk carries: two file systems worth offering rather than
 * one, and a boot block, which is where the two viruses vAmiga has always
 * been able to write live.
 *
 * The capacity is shown but not offered. It follows from the drive's model
 * (see FloppyDrive::insertNew, which derives the geometry from diameter and
 * density), so there is nothing to pick -- change the drive in the config
 * window and this follows.
 *
 * Bind 'amiga' and set driveNr before opening.
 */
SiDialog {

    id: root

    required property SiAmController amiga
    property int driveNr: 0
    readonly property int labelWidth: 90

    // The combo box tags are raw core values (see SiAmMediaController::
    // newDisk), so these name the two the layout turns on rather than
    // comparing against bare numbers.
    readonly property int nodos: 8          // amiga::FSFormat::NODOS
    readonly property int firstVirus: 3     // amiga::BootBlockId::SCA

    readonly property bool formatted: fsCombo.currentIndex !== root.nodos
    readonly property bool hasVirus: root.formatted && bbCombo.currentIndex >= root.firstVirus

    width: 460

    onOpened: {

        fsCombo.currentIndex = 0            // OFS, as vAmiga preselects
        bbCombo.currentIndex = 1            // AMIGADOS_13
        nameField.text = qsTr("Empty")
        nameField.selectAll()
        nameField.forceActiveFocus()
    }

    function insert() {

        root.amiga.media.newDisk(driveNr,
                                 fsCombo.currentIndex,
                                 root.formatted ? bbCombo.currentIndex : 0,
                                 root.formatted ? nameField.text : "")
        root.close()
    }

    RowLayout {

        id: contentRow
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
                width: parent.width * 0.8
                height: parent.height * 0.8
                fillMode: Image.PreserveAspectFit
                source: Assets.iconUrl(root.amiga.media.driveHighDensity(root.driveNr) ?
                                           Assets.Media35HDAmiga : Assets.Media35DDAmiga)
            }

            // The boot block the two virus entries write is the whole point of
            // offering them, so the disk says what it is carrying -- vAmiga
            // shows the same badge beside its own icon.
            Image {

                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: Style.smallSpacing
                width: 28
                height: 28
                visible: root.hasVirus
                fillMode: Image.PreserveAspectFit
                source: Assets.iconUrl(Assets.Biohazard)
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

                text: qsTr("Amiga Floppy Disk")
                font.bold: false
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

                l: qsTr("Capacity:")
                lwidth: root.labelWidth
                model: [root.amiga.media.driveCapacity(root.driveNr)]
                currentIndex: 0
                enabled: false
            }

            SiComboBoxControl {

                id: fsCombo
                l: qsTr("File system:")
                lwidth: root.labelWidth
                model: [qsTr("No File System"), qsTr("OFS"), qsTr("FFS")]
                tags: [root.nodos, 0, 1]    // NODOS, OFS, FFS
            }

            SiComboBoxControl {

                id: bbCombo
                l: qsTr("Boot block:")
                lwidth: root.labelWidth
                visible: root.formatted
                model: [qsTr("None"),
                    qsTr("AmigaDOS 1.3"),
                    qsTr("AmigaDOS 2.0"),
                    qsTr("SCA Virus"),
                    qsTr("Byte Bandit Virus")]
                tags: [0, 1, 2, 3, 4]       // BootBlockId, in enum order
            }

            SiControl {

                id: nameControl
                l: qsTr("Name:")
                lwidth: root.labelWidth
                visible: root.formatted

                control: [
                    SiTextField {
                        id: nameField
                        Layout.fillWidth: true
                        Layout.preferredHeight: 24
                        onAccepted: root.insert()
                    }
                ]
            }

            // Keeps the dialog from resizing as the two controls above come
            // and go with the file system.
            VSpacer {

                visible: !root.formatted
                size: bbCombo.implicitHeight + nameControl.implicitHeight +
                      2 * Style.mediumSpacing
            }
        }
    }

    footer: Item {

        implicitHeight: footerRow.implicitHeight + Style.largeSpacing

        RowLayout {

            id: footerRow
            anchors.fill: parent
            anchors.leftMargin: Style.largeSpacing
            anchors.rightMargin: Style.largeSpacing
            spacing: Style.mediumSpacing

            SiButton {
                text: qsTr("Cancel")
                onClicked: root.close()
            }

            HSpacer { }

            SiButton {
                accented: true
                text: qsTr("Insert")
                onClicked: root.insert()
            }
        }
    }
}
