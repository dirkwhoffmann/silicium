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

        controller.insertDisk(driveNr, url)
    }

    function attachDroppedHd(driveNr, url) {

        controller.attachHd(driveNr, url)
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

    // Hd0 is always offered, connected or not -- matching DropZone.swift's
    // own 'enabled = [true, hasHd(1), hasHd(2), hasHd(3)]': it's the
    // built-in hard drive slot, and mounting an image there is expected to
    // work even before it's been explicitly connected.
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
        enabled: root.isHardDiskImage && root.config.hdConnected(1)
        onTriggered: root.attachDroppedHd(1, root.path)
    }

    Action {
        id: hd2Action
        text: "Hd2"
        icon.source: Assets.iconUrl(Assets.DropHd)
        enabled: root.isHardDiskImage && root.config.hdConnected(2)
        onTriggered: root.attachDroppedHd(2, root.path)
    }

    Action {
        id: hd3Action
        text: "Hd3"
        icon.source: Assets.iconUrl(Assets.DropHd)
        enabled: root.isHardDiskImage && root.config.hdConnected(3)
        onTriggered: root.attachDroppedHd(3, root.path)
    }

    actions: root.isHardDiskImage
        ? [hd0Action, hd1Action, hd2Action, hd3Action]
        : [df0Action, df1Action, df2Action, df3Action]
}
