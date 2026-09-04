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
import Silicium.Controllers
import Silicium.Theme

//
// Generic chrome for an inspector window, port of SiC64InspectorWindow.qml.
// SiC64 gives every panel (Events, CIA, Bus, CPU, Memory, VIC, SID) its own
// top-level window, so several can be open side by side -- picked from a
// dropdown on the main toolbar's Inspector button (SiAmToolbar.qml's
// inspectMenu, mirroring SiC64Toolbar.qml's own). SiAmiga now follows the
// same shape: each file under Inspector/Panels/ (SiAmCPUPanel.qml, ...) uses
// this as its root type and supplies a title, the sub-controller its content
// samples (currentController, activated/deactivated as the window shows/
// hides -- exactly like SiC64's per-panel windows), and the content itself,
// declared as a plain child item.
//

ApplicationWindow {

    id: root

    required property SiAmController controller
    required property SiAmActions actions

    // Set by the specialized window to the sub-controller its content panel
    // samples, so this base window can activate/deactivate it as it's
    // shown/hidden without every panel needing to repeat that wiring.
    required property var currentController

    onVisibleChanged: currentController.active = visible
    Component.onCompleted: currentController.active = visible

    visible: false
    width: 880
    height: 440
    minimumWidth: 640
    minimumHeight: 320
    color: Palette.background

    header: SiAmInspectorToolbar {

        amiga: root.controller
        actions: root.actions
        inspectorController: root.currentController
    }
}
