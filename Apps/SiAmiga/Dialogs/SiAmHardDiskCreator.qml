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
 * what the whole dialog turns on: pick a capacity and the CHS fields follow
 * it, pick "User defined" and they become yours to set, within what a
 * geometry may hold (see SiAmMediaController::hdGeometryLimits).
 *
 * The drive is built in memory. Nothing reaches the disk until the workspace
 * is saved -- unlike a dropped image, which is copied into the SVM there and
 * then (see SiAmDropHdfDialog).
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
    readonly property bool formatted: fsCombo.currentIndex !== root.nodos

    // "User defined" carries no capacity of its own, which is what makes it
    // the one entry that leaves the geometry alone.
    readonly property bool custom: capacityCombo.currentIndex === 0

    // The geometry being described. vAmiga keeps these outside its controls
    // too: the fields display them, the capacity computes them, and neither
    // is their home.
    property int cylinders: 0
    property int heads: 0
    property int sectors: 0
    property int bsize: 512

    readonly property var limits: root.amiga.media.hdGeometryLimits()
    readonly property real megabytes:
        cylinders * heads * sectors * bsize / (1024 * 1024)

    // Where the drive's initial contents come from, "" for an empty drive.
    property url importUrl: ""

    width: 620

    onOpened: {

        capacityCombo.currentIndex = 8      // 8 MB, as vAmiga preselects
        fsCombo.currentIndex = 0            // OFS
        nameField.text = qsTr("Hdrv")
        root.importUrl = ""
        root.setCapacity(8)
    }

    /* Derives a geometry from a capacity.
     *
     * vAmiga's own arithmetic (HardDiskCreator.setCapacity): 32 sectors of
     * 512 bytes, and as many cylinders as that takes -- doubling the head
     * count whenever the cylinders would run past what an Amiga hard drive
     * plausibly has.
     */
    function setCapacity(mb) {

        if (mb <= 0) return

        root.bsize = 512
        root.sectors = 32
        root.heads = 1
        root.cylinders = (mb * 1024 * 1024) / (root.heads * root.sectors * root.bsize)

        while (root.cylinders > 1024) {

            root.cylinders /= 2
            root.heads *= 2
        }
    }

    function clamp(value, lo, hi) {
        return Math.max(lo, Math.min(hi, value))
    }

    function attach() {

        root.amiga.media.newHardDisk(root.driveNr,
                                     root.cylinders, root.heads, root.sectors, root.bsize,
                                     fsCombo.currentIndex,
                                     root.formatted ? nameField.text : "",
                                     root.formatted ? root.importUrl : "")
        root.close()
    }

    /* A number field with the two arrows beside it.
     *
     * The stepper lives in SiControl's 'accessories', which is where a
     * control's trailing decoration goes -- there is no stepper component in
     * the shared set, and one pair of arrows used by one dialog is not yet a
     * reason to add one.
     */
    component GeometryField : SiNumberInputControl {

        id: field

        property int minimum: 0
        property int maximum: 999999
        signal bumped(int delta)

        lwidth: 70
        controlWidth: 72
        minValue: minimum
        maxValue: maximum

        ColumnLayout {

            spacing: 0
            enabled: field.enabled

            SiControlButton {
                symbol: "keyboard_arrow_up"
                implicitWidth: 22
                implicitHeight: 13
                onClicked: field.bumped(1)
            }

            SiControlButton {
                symbol: "keyboard_arrow_down"
                implicitWidth: 22
                implicitHeight: 13
                onClicked: field.bumped(-1)
            }
        }
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

            SiComboBoxControl {

                id: capacityCombo
                l: qsTr("Capacity:")
                lwidth: root.labelWidth
                model: [qsTr("User defined"),
                    "4 MB", "8 MB", "16 MB", "32 MB", "64 MB", "128 MB", "256 MB"]
                tags: [0, 4, 8, 16, 32, 64, 128, 256]
                onActivated: (tag) => root.setCapacity(tag)
            }

            SiComboBoxControl {

                id: fsCombo
                l: qsTr("File system:")
                lwidth: root.labelWidth
                model: [qsTr("None"), qsTr("OFS"), qsTr("FFS")]
                tags: [root.nodos, 0, 1]    // NODOS, OFS, FFS

                // An unformatted drive has nowhere to put files, so the
                // folder goes with the file system (as it does in vAmiga).
                onActivated: { if (!root.formatted) root.importUrl = "" }
            }

            SiControl {

                l: qsTr("Name:")
                lwidth: root.labelWidth
                visible: root.formatted

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
                visible: root.formatted

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
                visible: root.formatted
                elide: Text.ElideMiddle
                color: root.importUrl != "" ? Palette.secondary : Palette.tertiary
                text: root.importUrl != "" ? root.importUrl.toString().replace("file://", "")
                                           : qsTr("Path to import folder")
            }
        }

        //
        // Geometry
        //

        ColumnLayout {

            Layout.alignment: Qt.AlignTop
            Layout.topMargin: Style.large + 2 * Style.smallSpacing + Style.mediumSpacing
            spacing: Style.mediumSpacing

            GeometryField {

                l: qsTr("Cylinders:")
                enabled: root.custom
                intValue: root.cylinders
                minimum: root.limits.cMin
                maximum: root.limits.cMax
                onValueEdited: (v) => root.cylinders = root.clamp(v, minimum, maximum)
                onBumped: (d) => root.cylinders = root.clamp(root.cylinders + d, minimum, maximum)
            }

            GeometryField {

                l: qsTr("Heads:")
                enabled: root.custom
                intValue: root.heads
                minimum: root.limits.hMin
                maximum: root.limits.hMax
                onValueEdited: (v) => root.heads = root.clamp(v, minimum, maximum)
                onBumped: (d) => root.heads = root.clamp(root.heads + d, minimum, maximum)
            }

            GeometryField {

                l: qsTr("Sectors:")
                enabled: root.custom
                intValue: root.sectors
                minimum: root.limits.sMin
                maximum: root.limits.sMax
                onValueEdited: (v) => root.sectors = root.clamp(v, minimum, maximum)
                onBumped: (d) => root.sectors = root.clamp(root.sectors + d, minimum, maximum)
            }

            // What the three above add up to. vAmiga leaves this to the
            // capacity popup, which says nothing once the geometry is edited
            // by hand -- and that is exactly when the number is worth having.
            SiText {

                Layout.alignment: Qt.AlignRight
                Layout.rightMargin: 22 + Style.smallSpacing
                color: Palette.secondary
                font.pixelSize: Style.small
                text: root.megabytes < 1 ? qsTr("%1 KB").arg(Math.round(root.megabytes * 1024))
                                         : qsTr("%1 MB").arg(root.megabytes.toFixed(1))
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
                onClicked: root.attach()
            }
        }
    }
}
