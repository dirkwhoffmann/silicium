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
import Silicium.Assets
import Silicium.Preferences
import Silicium.Theme

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
SiUserDialog {

    id: root

    // Emitted when the user confirms, with what they chose to save
    signal confirmed(bool snapshot, bool workspace)

    titleText: qsTr("Hibernate")
    badgeSource: Assets.iconUrl(Assets.Help)
    bodyText: qsTr("The virtual machine is about to hibernate. " +
                   "Would you like to save your current changes?")

    SiCheckBoxControl {
        id: snapshotBox
        r: qsTr("Save machine state as a snapshot")
        checked: Preferences.hibernateSnapshot
    }

    SiCheckBoxControl {
        id: workspaceBox
        r: qsTr("Save current workspace")
        checked: Preferences.hibernateWorkspace
    }

    buttons: Dialog.Cancel | Dialog.Ok

    // Nothing to save is not a save: say what the button will do
    okLabel: snapshotBox.checked || workspaceBox.checked ? qsTr("Save") : qsTr("Quit")

    onAccepted: root.confirmed(snapshotBox.checked, workspaceBox.checked)
}
