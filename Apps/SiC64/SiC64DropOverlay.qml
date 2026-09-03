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

DropOverlay {

    id: root

    required property C64Controller controller
    required property SiC64Window window

    readonly property SiC64ConfigController config: controller.configController

    function insertDroppedDisk(driveNr, url) {

        window.proceedWithUnsavedFloppyDisk(driveNr, function () {
            controller.insertDisk(driveNr, url)
        })
    }

    Action {

        id: drive8Action
        text: "Drive 8"
        icon.source: Assets.iconUrl(Assets.Drop525)
        enabled: ["d64", "g64", "t64", "prg", "p00"].includes(extension) &&
                 root.config.DRIVE8_CONNECTED
        onTriggered: {
            console.log("Drop zone 1 action triggered")
            root.insertDroppedDisk(8, path)
        }
    }

    Action {

        id: drive9Action
        text: "Drive 9"
        enabled: ["d64", "g64", "t64", "prg", "p00"].includes(extension) &&
                 root.config.DRIVE9_CONNECTED
        icon.source: Assets.iconUrl(Assets.Drop525)

        onTriggered: {
            console.log("Drop zone 2 action triggered")
            root.insertDroppedDisk(9, path)
        }
    }

    Action {

        id: memoryAction
        text: "Memory"
        enabled: ["prg", "p00", "t64"].includes(extension)
        icon.source: Assets.iconUrl(Assets.DropMem)

        onTriggered: {
            console.log("Drop zone 3 action triggered")
            controller.flash(path)
        }
    }

    Action {

        id: expansionAction
        text: "Expansion"
        enabled: ["crt"].includes(extension)
        icon.source: Assets.iconUrl(Assets.DropCrt)

        onTriggered: {
            console.log("Drop zone 4 action triggered")
            controller.attachCartridge(path)
        }
    }

    Action {

        id: datasetteAction
        text: "Datasette"
        enabled: ["tap"].includes(extension) && root.config.DAT_CONNECT
        icon.source: Assets.iconUrl(Assets.DropTape)

        onTriggered: {
            console.log("Drop zone 5 action triggered")
            controller.insertTape(path)
        }
    }

    actions: [drive8Action, drive9Action, memoryAction, expansionAction, datasetteAction]
}
