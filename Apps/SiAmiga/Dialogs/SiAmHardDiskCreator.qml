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
import Sulfur

SiDialog {

    id: root

    readonly property SiAmController amiga: SiAmController
    readonly property SiAmInfoController info: amiga.info

    property int driveNr: 0
    readonly property int labelWidth: 90

    readonly property int nodos: 8 // amiga::FSFormat::NODOS
    readonly property int ofs: 0   // amiga::FSFormat::OFS
    readonly property int ffs: 1   // amiga::FSFormat::FFS

    // The capacity being asked for
    property int megabytes: 8

    // Import folder
    property url importUrl: ""

    // Maximum hard-drive capacity
    readonly property int limit: {

        switch (root.driveNr) {
            case 0: return root.amiga.configController.HD0_MB_LIMIT
            case 1: return root.amiga.configController.HD1_MB_LIMIT
            case 2: return root.amiga.configController.HD2_MB_LIMIT
            case 3: return root.amiga.configController.HD3_MB_LIMIT
        }
        return 0
    }

    // Computed properties
    readonly property bool tooLarge: root.limit > 0 && root.megabytes > root.limit
    readonly property bool formattable: root.megabytes <= 4096
    readonly property bool unformattable: root.megabytes > 4096

    // Whether a file system is actually going to be created.
    /*
    readonly property bool formatted:
        fsCombo.currentIndex !== root.nodos && root.formattable
    */

    width: 520

    onOpened: {

        fsCombo.currentIndex = 0
        nameField.text = qsTr("Hdrv")
        root.refresh()
    }

    /* The number in front of whatever the user typed, or 0 for text that
     * carries no usable one. "384" and "384 MB" are the same thing, as is a
     * "64 MB" picked from the list.
     */
    function parseCapacity(text) {

        const mb = parseInt(text)
        return isNaN(mb) || mb <= 0 ? 0 : mb
    }

    /* Takes what the field says, once the user has finished saying it.
     *
     * Nothing is refused while it is being typed -- a field that rejects
     * keystrokes leaves the user guessing which one it disliked. The text
     * is judged when the edit ends instead, and whatever cannot be used is
     * undone: the capacity goes back to the last one that could be, which
     * is the value still shown everywhere else in the dialog.
     *
     * Text carrying no usable number is undone in silence; there is nothing
     * to explain that the field does not already show. A capacity that is
     * merely too large for this slot is undone with a word about why, since
     * on the face of it there is nothing wrong with the number.
     */
    function commit() {

        const mb = root.parseCapacity(capacityCombo.editText)
        const refused = mb > 0 && root.limit > 0 && mb > root.limit

        if (mb > 0 && !refused) root.megabytes = mb

        // The old value first, so the dialog appears over a settled field
        root.refresh()
        if (refused) capacityRefused.open()
    }

    // Puts the field into the shape the list entries have
    function refresh() {

        capacityCombo.editText = root.megabytes + " MB"
    }

    function attach() {

        if (root.megabytes <= 0 || root.tooLarge) return

        if (root.formattable && fsCombo.currentIndex !== root.nodos) {

            root.amiga.media.attachHdAsync(root.driveNr,
                root.megabytes,
                fsCombo.currentIndex,
                nameField.text,
                root.importUrl)

        } else {

            root.amiga.media.attachHdAsync(root.driveNr,
                root.megabytes,
                root.nodos,
                "",
                "")
        }

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
        // Options
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

            SiLabeledComboInput {

                id: capacityCombo
                l: qsTr("Capacity:")
                lwidth: root.labelWidth
                model: ["4 MB", "8 MB", "16 MB", "32 MB", "64 MB", "128 MB", "256 MB"]
                onAccepted: root.commit()
                onEditingFinished: root.commit()
                onActivated: root.commit()
            }

            SiLabeledComboBox {

                id: fsCombo
                l: qsTr("File system:")
                lwidth: root.labelWidth
                model: [qsTr("None"), qsTr("OFS"), qsTr("FFS")]
                tags: [root.nodos, root.ofs, root.ffs]
                enabled: root.formattable
                // onActivated: { if (!root.formatted) root.importUrl = "" }
            }

            SiLabeled {

                l: qsTr("Name:")
                lwidth: root.labelWidth
                opacity: root.formattable && fsCombo.currentIndex !== root.nodos ? 1.0 : 0.0

                control: [
                    SiTextField {
                        id: nameField
                        Layout.fillWidth: true
                        Layout.preferredHeight: 22
                        onAccepted: root.attach()
                    },
                    HSpacer { size: 20 }
                ]
            }

            SiLabeled {

                id: importControl
                l: qsTr("Files:")
                lwidth: root.labelWidth
                opacity: root.formattable && fsCombo.currentIndex !== root.nodos ? 1.0 : 0.0

                control: [

                    SiSymbolButton {

                        size: Size.large
                        phosphor: "folder"
                        onClicked: importDialog.open()
                    },

                    SiLabel {

                        Layout.fillWidth: true
                        enabled: !root.unformattable
                        elide: Text.ElideMiddle
                        color: root.importUrl != "" ? Palette.secondary : Palette.tertiary
                        text: root.importUrl != "" ? root.importUrl.toString().replace("file://", "")
                            : qsTr("Path to import folder...")
                    }
                ]
            }
        }

    }

    SiUserDialog {

        id: capacityRefused
        titleText: qsTr("Maximum hard drive capacity exceeded.")
        bodyText: qsTr("HD%1 can hold at most %2 MB.").arg(root.driveNr).arg(root.limit)
        buttons: Dialog.Ok
        okLabel: qsTr("OK")
        sound: true
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
