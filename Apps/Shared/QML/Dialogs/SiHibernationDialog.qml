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
import Silicium.Preferences
import Sulfur

/* Asks what to keep when a machine is about to go away.
 *
 * The dialog only asks; hibernating is the window's job, because what has to
 * happen afterwards differs from app to app. It reports the answer through
 * confirmed(), which is emitted with the two boxes as the user left them.
 * Cancel means the machine stays, so nothing is emitted.
 *
 * Both apps hibernate the same way and ask the same question, so they ask it
 * with this one component (see VMWindow and SiAmWindow).
 */
SuUserDialog {

    id: root

    // Emitted when the user confirms, with what they chose to save
    signal confirmed(bool snapshot, bool workspace)

    // Whether the snapshot storage is full (the owner sets it before opening the dialog)
    property bool snapshotStorageFull: false

    titleText: qsTr("Hibernate")
    badgeSource: Assets.iconUrl(Assets.Help)
    bodyText: qsTr("The virtual machine is about to hibernate. " +
                   "Would you like to save your current changes?")

    ColumnLayout {

        Layout.fillWidth: true
        spacing: 0

        SuLabeledCheckBox {

            id: snapshotBox
            r: qsTr("Save machine state as a snapshot")
            checked: Preferences.hibernateSnapshot
        }

        SuLabel {

            visible: root.snapshotStorageFull
            Layout.fillWidth: true
            Layout.leftMargin: snapshotBox.rightTextX
            size: Size.tiny // small
            wrapMode: Text.WordWrap
            text: qsTr("The snapshot storage is full. Saving a new snapshot will delete the oldest one.")
        }
    }

    SuLabeledCheckBox {

        id: workspaceBox
        r: qsTr("Save current workspace")
        checked: Preferences.hibernateWorkspace
    }

    buttons: Dialog.Cancel | Dialog.Ok

    // Nothing to save is not a save: say what the button will do
    okLabel: snapshotBox.checked || workspaceBox.checked ? qsTr("Save") : qsTr("Quit")

    // Return confirms, no matter which control has the focus
    Shortcut {
        sequences: ["Return", "Enter"]
        enabled: root.opened
        onActivated: root.accept()
    }

    onAccepted: root.confirmed(snapshotBox.checked, workspaceBox.checked)
}
