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

/* Builds a hard drive from scratch and plugs it in.
 *
 * The port of vAmiga's HardDiskCreator (GUI/Dialogs/HardDiskCreator.swift),
 * and the hard-drive counterpart to SiAmDiskCreator. A floppy has one
 * geometry and nothing to decide; a hard drive has a size, and the size is
 * the whole of what this dialog asks for: a capacity is either picked from
 * the list or typed in, and the geometry that describes it is the core's
 * business (see SiAmMediaController::attachHdAsync). vAmiga's own dialog
 * offers the CHS fields instead, which is the same question asked three
 * times over.
 *
 * The drive is built as a file in the machine's own folder and attached on
 * top of it (see SiAmMediaController::attachHdAsync), so the SVM carries it
 * and a snapshot need not.
 *
 * Bind 'amiga' and set driveNr before opening.
 */
SiDialog {

    id: root

    required property SiAmController amiga
    property int driveNr: 0
    readonly property int labelWidth: 90

    // amiga::FSFormat::NODOS, as SiAmDiskCreator names it
    readonly property int nodos: 8

    // The capacity being asked for, in MB. Whatever the field says, parsed.
    readonly property int megabytes: root.parseCapacity(capacityCombo.editText)

    // What this slot accepts, 0 when it is unlimited (see hdCapacityLimit).
    readonly property int limit: root.amiga.media.hdCapacityLimit(root.driveNr)
    readonly property bool tooLarge: root.limit > 0 && root.megabytes > root.limit

    /* Past what any Amiga file system can describe.
     *
     * Not a reason to refuse the drive -- a drive this large is perfectly
     * usable, it just cannot be formatted here, so everything belonging to a
     * file system goes grey and the drive is created raw. Formatting it is
     * then the guest's business, with whatever it uses for drives of this
     * size.
     */
    readonly property bool unformattable:
        root.megabytes > root.amiga.media.hdFileSystemLimit()

    // Whether a file system is actually going to be created.
    readonly property bool formatted:
        fsCombo.currentIndex !== root.nodos && !root.unformattable

    // Where the drive's initial contents come from, "" for an empty drive.
    property url importUrl: ""

    width: 520

    onOpened: {

        capacityCombo.currentIndex = 1      // 8 MB, as vAmiga preselects
        fsCombo.currentIndex = 0            // OFS
        nameField.text = qsTr("Hdrv")
        root.importUrl = ""
    }

    /* The number in front of whatever the user typed.
     *
     * The field is free text, so it takes "384" and "384 MB" alike, and 0
     * for anything that carries no number at all -- which is what disables
     * the Attach button.
     */
    function parseCapacity(text) {

        const mb = parseInt(text)
        return isNaN(mb) || mb < 0 ? 0 : mb
    }

    // Puts the field back into the shape the list entries have, so a typed
    // "384" reads like a capacity once it has been accepted.
    function normalize() {

        if (root.megabytes > 0) capacityCombo.editText = root.megabytes + " MB"
    }

    function attach() {

        // Guards the Enter key in the name field, which reaches this without
        // passing the Attach button's own 'enabled'.
        if (root.megabytes <= 0 || root.tooLarge) return

        root.amiga.media.attachHdAsync(root.driveNr,
                                       root.megabytes,
                                       root.formatted ? fsCombo.currentIndex : root.nodos,
                                       root.formatted ? nameField.text : "",
                                       root.formatted ? root.importUrl : "")

        /* Closed as soon as the job is under way: the drive is built in the
         * background (see SiAmMediaController::attachHdAsync), so what
         * follows is the status bar's business, and an error -- including
         * one saying the job could not be started at all -- arrives on its
         * own.
         */
        root.close()
    }

    RowLayout {

        id: contentRow
        Layout.fillWidth: true
        spacing: Style.largeSpacing

        //
        // Drive icon
        //

        Rectangle {

            Layout.preferredWidth: 110
            Layout.preferredHeight: 110
            Layout.alignment: Qt.AlignTop
            radius: Style.borderRadius
            color: Palette.surfaceElevated

            // Follows the import folder, as vAmiga's does: what is about to
            // be created is the folder's contents, not an empty drive.
            Image {

                anchors.centerIn: parent
                width: parent.width * 0.8
                height: parent.height * 0.8
                fillMode: Image.PreserveAspectFit
                source: Assets.iconUrl(root.importUrl != "" ? Assets.MediaFsAmiga
                                                            : Assets.MediaHdrAmiga)
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

                text: qsTr("Amiga Hard Drive")
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

            /* Editable, unlike the list vAmiga offers: the entries are the
             * sizes worth one click, and anything else -- "384" -- is typed
             * straight in. That is also what retires the CHS fields, whose
             * only job was to express a size the list did not carry.
             */
            SiComboInputControl {

                id: capacityCombo
                l: qsTr("Capacity:")
                lwidth: root.labelWidth
                model: ["4 MB", "8 MB", "16 MB", "32 MB", "64 MB", "128 MB", "256 MB"]

                /* A number, optionally followed by the unit the list entries
                 * carry -- so "384", "384 MB" and a picked "64 MB" are all
                 * spellings of the same thing, and a letter typed where a
                 * digit belongs never lands. Six digits is past every limit
                 * below; what is well-formed but too large is caught there,
                 * not here.
                 */
                validator: RegularExpressionValidator {
                    regularExpression: /[0-9]{0,6} ?([Mm][Bb]?)?/
                }

                onAccepted: root.normalize()
                onEditingFinished: root.normalize()
            }

            SiText {

                Layout.fillWidth: true
                Layout.leftMargin: root.labelWidth + Style.mediumSpacing
                font.pixelSize: Style.small
                color: root.tooLarge ? Palette.warning : Palette.tertiary
                text: root.tooLarge ? qsTr("This slot holds at most %1 MB.").arg(root.limit)
                    : root.unformattable ? qsTr("Too large for a file system. " +
                                                "The drive is created unformatted.")
                    : root.limit > 0 ? qsTr("Up to %1 MB.").arg(root.limit)
                    : qsTr("Type a size in MB, or pick one.")
            }

            SiComboBoxControl {

                id: fsCombo
                l: qsTr("File system:")
                lwidth: root.labelWidth
                model: [qsTr("None"), qsTr("OFS"), qsTr("FFS")]
                tags: [root.nodos, 0, 1]    // NODOS, OFS, FFS
                enabled: !root.unformattable

                // An unformatted drive has nowhere to put files, so the
                // folder goes with the file system (as it does in vAmiga).
                onActivated: { if (!root.formatted) root.importUrl = "" }
            }

            SiControl {

                l: qsTr("Name:")
                lwidth: root.labelWidth
                visible: root.formatted || root.unformattable
                enabled: !root.unformattable

                control: [
                    SiTextField {
                        id: nameField
                        Layout.fillWidth: true
                        Layout.preferredHeight: 24
                        onAccepted: root.attach()
                    }
                ]
            }

            SiControl {

                id: importControl
                l: qsTr("Files:")
                lwidth: root.labelWidth
                visible: root.formatted || root.unformattable
                enabled: !root.unformattable

                control: [
                    SiButton {
                        text: qsTr("Add folder...")
                        onClicked: importDialog.open()
                    }
                ]
            }

            SiText {

                Layout.fillWidth: true
                Layout.leftMargin: root.labelWidth + Style.mediumSpacing
                visible: root.formatted || root.unformattable
                enabled: !root.unformattable
                elide: Text.ElideMiddle
                color: root.importUrl != "" ? Palette.secondary : Palette.tertiary
                text: root.importUrl != "" ? root.importUrl.toString().replace("file://", "")
                                           : qsTr("Path to import folder")
            }
        }

    }

    FolderDialog {

        id: importDialog
        title: qsTr("Import Folder")
        onAccepted: root.importUrl = selectedFolder
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
                text: qsTr("Attach")
                enabled: root.megabytes > 0 && !root.tooLarge
                onClicked: root.attach()
            }
        }
    }
}
