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
import Silicium.Controllers
import Silicium.Theme

/* Asks before a dropped hard disk image is taken into the machine.
 *
 * Dropping a hard drive is not the quick, reversible thing dropping a floppy
 * is: it copies the image into the SVM, plugs in a controller if the slot
 * has none, resets the machine and rewrites the config script. So it asks
 * first, and then gets out of the way: the copy runs as a background job
 * whose progress the window's banner reports (see Controller::runTask).
 *
 * Bind 'controller' and call openFor(driveNr, url).
 */
SiUserDialog {

    id: root

    required property SiAmController controller

    // Which slot the image was dropped on, and what was dropped there.
    property int driveNr: 0
    property string fileUrl: ""

    // What the slot holds today, "" when it is empty -- not what the drop
    // will be called, which is hdImageName().
    readonly property string existing: root.controller.media.hdExistingImage(driveNr)
    readonly property bool overwrites: existing !== ""

    function openFor(driveNr, url) {

        root.driveNr = driveNr
        root.fileUrl = url
        root.open()
    }

    titleText: qsTr("Copy Hard Drive to Virtual Machine")
    badgeSource: Assets.iconUrl(overwrites ? Assets.Biohazard : Assets.Help)

    bodyText: {

        let text = qsTr("The emulator will be reset, and the hard drive " +
                        "will be copied to the virtual machine folder.")

        if (overwrites) {
            text += "\n\n" + qsTr("This replaces the existing %1 in that folder. " +
                                   "Its contents will be lost.").arg(existing)
        }

        return text + "\n\n" + qsTr("Do you want to continue?")
    }

    buttons: Dialog.Cancel | Dialog.Ok
    okLabel: qsTr("Continue")
    sound: true

    onAccepted: root.controller.media.copyAndAttachHd(driveNr, fileUrl)
}
