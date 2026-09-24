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

// Port of SiC64DropOverlay.qml, but with different semantics -- ported from
// vAmiga's own GUI/Layers/DropZone.swift rather than being a like-for-like
// translation. SiC64's five drop zones are fixed: drive 8, drive 9, memory,
// expansion port, datasette, each its own Action, always all five on
// screen. An Amiga only has one *kind* of target that makes sense for a
// dropped file -- either the four floppy drives or the four hard drives,
// never both at once, because a single file is only ever a floppy image or
// a hard disk image -- so DropZone.swift shows the same four boxes for
// either case and just swaps what they represent (icon, label, and which
// mount call a drop triggers) based on the dragged file's format. That is
// exactly what happens here too, except the four "zones" are just entries
// in the shared DropOverlay's now-dynamic 'actions' list (see that file --
// generalized from SiC64's fixed action1..action5 specifically so this
// swappable four-Action list could reuse it) instead of a set of four
// fixed properties.
//
// One deliberate simplification versus DropZone.swift: vAmiga distinguishes
// 3.5"/5.25" floppy media (df35/df525) because some of its drives can be
// configured as 5.25" externals. SiAmConfigController's floppy drives don't
// expose that distinction yet (see its driveType()/driveConnected() pair),
// so every floppy zone here just checks driveConnected(nr).
DropOverlay {

    id: root

    required property SiAmController controller
    required property SiAmWindow window

    readonly property SiAmConfigController config: controller.configController

    // Formats FloppyDiskImage/HardDiskImage recognize -- see vAmiga's own
    // Core/rvlib/Images/ImageTypes.h (ImageFormat), which is the source of
    // truth DropZone.swift's isFloppy35Image/isHardDiskImage checks were
    // themselves derived from.
    readonly property var floppyExtensions: ["adf", "adz", "eadf", "img", "st", "dms", "exe"]
    readonly property var hdExtensions: ["hdf", "hdz"]

    readonly property bool isFloppyImage: floppyExtensions.includes(extension)
    readonly property bool isHardDiskImage: hdExtensions.includes(extension)

    function insertDroppedDisk(driveNr, url) {

        controller.media.insertDisk(driveNr, url)
    }

    /* Dropping a hard drive is not the quick, reversible thing dropping a
     * floppy is: it stops the machine and writes into the SVM, so it asks
     * first. The copy and the attach are the dialog's job (see below), not
     * this one's -- all that happens here is remembering what was dropped
     * where.
     */
    function attachDroppedHd(driveNr, url) {

        hdDialog.driveNr = driveNr
        hdDialog.fileUrl = url
        console.log("Calling hdDialog.open()")
        hdDialog.open()
        console.log("Returning from hdDialog.open()")
    }



    SiUserDialog {

        id: hdDialog

        // Parented to the window rather than to this overlay: the overlay is
        // anchored to the canvas and disappears the moment the drag ends,
        // which would take the dialog with it.
        parent: root.window.contentItem

        property int driveNr: 0
        property string fileUrl: ""

        // What the slot holds today, "" when it is empty -- not what the drop
        // will be called, which is hdImageName().
        readonly property string existing: root.controller.media.hdExistingImage(driveNr)
        readonly property bool overwrites: existing !== ""

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

        readonly property var task: root.controller.media.task
        readonly property bool busy: task.running

        // Nothing to accept twice, and nothing to close by pressing Escape
        // while a machine is being rearranged.
        onBusyChanged: {
            setButtonEnabled(Dialog.Apply, !busy)
            closePolicy = busy ? Popup.NoAutoClose : Popup.CloseOnEscape
        }

        onApplied: {
            indicator.restart()
            root.controller.media.copyAndAttachHd(driveNr, fileUrl)
        }

        // Cancel means "do not install it" while the copy runs, and plain
        // dismissal before it starts.
        onRejected: if (busy) task.cancel()

        Connections {

            target: hdDialog.task
            function onFinished() { indicator.stop(); hdDialog.close() }
        }

        /* The ring is held back for half a second. A mount that finishes
         * sooner than that shows its step names and nothing else, which
         * reads as the dialog simply getting on with it rather than as a
         * spinner flashing up and vanishing.
         */
        Timer {

            id: indicator
            interval: 500
            /* Qualified: an unqualified name inside this Timer would be
             * looked up on the Timer and then on the root of this file, not
             * on the dialog around it, and the assignment would quietly go
             * nowhere.
             */
            onTriggered: if (hdDialog.busy) hdDialog.visibleIndicator = true
        }

        property bool visibleIndicator: false
        onVisibleChanged: if (!visible) visibleIndicator = false

        RowLayout {

            Layout.fillWidth: true
            Layout.topMargin: Style.smallSpacing
            spacing: Style.mediumSpacing
            visible: hdDialog.busy

            BusyIndicator {

                Layout.alignment: Qt.AlignVCenter
                implicitWidth: 24
                implicitHeight: 24
                running: true
                visible: hdDialog.visibleIndicator
            }

            SiText {

                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                horizontalAlignment: Text.AlignLeft
                wrapMode: Text.WordWrap
                font.pixelSize: Style.regular
                opacity: 0.7
                text: hdDialog.task.description
            }
        }
    }

    // One Action per drive, built once and rebound into 'actions' below
    // depending on what's being dragged -- df0..df3 for a floppy image,
    // hd0..hd3 for a hard disk image. Both action sets exist the whole
    // time (rather than being created/destroyed per drag) so their
    // enabled/icon/text bindings stay live even while hidden.

    Action {
        id: df0Action
        text: "Df0"
        icon.source: Assets.iconUrl(Assets.Drop35)
        enabled: root.isFloppyImage && root.config.driveConnected(0)
        onTriggered: root.insertDroppedDisk(0, root.path)
    }

    Action {
        id: df1Action
        text: "Df1"
        icon.source: Assets.iconUrl(Assets.Drop35)
        enabled: root.isFloppyImage && root.config.driveConnected(1)
        onTriggered: root.insertDroppedDisk(1, root.path)
    }

    Action {
        id: df2Action
        text: "Df2"
        icon.source: Assets.iconUrl(Assets.Drop35)
        enabled: root.isFloppyImage && root.config.driveConnected(2)
        onTriggered: root.insertDroppedDisk(2, root.path)
    }

    Action {
        id: df3Action
        text: "Df3"
        icon.source: Assets.iconUrl(Assets.Drop35)
        enabled: root.isFloppyImage && root.config.driveConnected(3)
        onTriggered: root.insertDroppedDisk(3, root.path)
    }

    /* Every hard drive zone is offered, connected or not: dropping an image
     * on a slot that has no controller yet plugs one in (see
     * SiAmMediaController::copyAndAttachHd), so requiring one beforehand would
     * only hide the very zones a machine without hard drives needs.
     */

    Action {
        id: hd0Action
        text: "Hd0"
        icon.source: Assets.iconUrl(Assets.DropHd)
        enabled: root.isHardDiskImage
        onTriggered: root.attachDroppedHd(0, root.path)
    }

    Action {
        id: hd1Action
        text: "Hd1"
        icon.source: Assets.iconUrl(Assets.DropHd)
        enabled: root.isHardDiskImage
        onTriggered: root.attachDroppedHd(1, root.path)
    }

    Action {
        id: hd2Action
        text: "Hd2"
        icon.source: Assets.iconUrl(Assets.DropHd)
        enabled: root.isHardDiskImage
        onTriggered: root.attachDroppedHd(2, root.path)
    }

    Action {
        id: hd3Action
        text: "Hd3"
        icon.source: Assets.iconUrl(Assets.DropHd)
        enabled: root.isHardDiskImage
        onTriggered: root.attachDroppedHd(3, root.path)
    }

    actions: root.isHardDiskImage
        ? [hd0Action, hd1Action, hd2Action, hd3Action]
        : [df0Action, df1Action, df2Action, df3Action]
}
