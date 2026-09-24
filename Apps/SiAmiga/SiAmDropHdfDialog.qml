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

/* Asks before a dropped hard disk image is taken into the machine, and then
 * reports how that is going.
 *
 * Dropping a hard drive is not the quick, reversible thing dropping a floppy
 * is: it copies the image into the SVM, plugs in a controller if the slot
 * has none, resets the machine and rewrites the config script. So it asks
 * first -- and once the work starts, the very same dialog turns into its
 * progress display rather than handing over to a second one.
 *
 * Bind 'controller' and call openFor(driveNr, url); the dialog closes itself
 * when the job is done.
 */
SiUserDialog {

    id: root

    required property SiAmController controller

    // Which slot the image was dropped on, and what was dropped there.
    property int driveNr: 0
    property string fileUrl: ""

    readonly property var task: root.controller.media.task
    readonly property bool busy: task.running

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

        return busy ? text : text + "\n\n" + qsTr("Do you want to continue?")
    }

    /* Apply rather than Ok, because Apply carries no accept role and so
     * leaves the dialog open. The copy then reports inside the dialog
     * that started it instead of a second one taking its place.
     */
    buttons: Dialog.Cancel | Dialog.Apply
    applyLabel: qsTr("Continue")
    sound: true

    /* Via Connections rather than as plain onBusyChanged/onVisibleChanged
     * handlers: a handler declared here would be replaced outright by one
     * a use site declares for the same signal, and this dialog's own
     * bookkeeping would silently stop running.
     */
    Connections {

        target: root

        // Nothing to accept twice, and nothing to close by pressing Escape
        // while a machine is being rearranged.
        function onBusyChanged() {
            root.setButtonEnabled(Dialog.Apply, !root.busy)
            root.closePolicy = root.busy ? Popup.NoAutoClose : Popup.CloseOnEscape
        }

        /* A dialog that was dismissed starts its next run without a ring.
         * The timer has to be stopped along with it: cancelling leaves the
         * task busy for a moment longer, so a timer still ticking would
         * fire after the dialog is gone and arm the ring for the next run.
         */
        function onVisibleChanged() {
            if (!root.visible) { indicator.stop(); root.visibleIndicator = false }
        }
    }

    onApplied: {
        indicator.restart()
        root.controller.media.copyAndAttachHd(driveNr, fileUrl)
    }

    // Cancel means "do not install it" while the copy runs, and plain
    // dismissal before it starts.
    onRejected: if (busy) task.cancel()

    Connections {

        target: root.task
        function onFinished() { indicator.stop(); root.close() }
    }

    /* The indicator is held back for half a second. A mount that finishes
     * sooner than that shows its step names and nothing else, which reads
     * as the dialog simply getting on with it rather than as a spinner
     * flashing up and vanishing.
     */
    Timer {

        id: indicator
        interval: 500
        onTriggered: if (root.busy) root.visibleIndicator = true
    }

    property bool visibleIndicator: false

    RowLayout {

        Layout.fillWidth: true
        Layout.topMargin: Style.smallSpacing
        spacing: Style.mediumSpacing
        visible: root.busy

        BusyIndicator {

            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 24
            implicitHeight: 24
            running: true
            visible: root.visibleIndicator
        }

        SiText {

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            horizontalAlignment: Text.AlignLeft
            wrapMode: Text.WordWrap
            font.pixelSize: Style.regular
            opacity: 0.7
            text: root.task.description
        }
    }
}
