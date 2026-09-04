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
import Silicium.Controllers
import Silicium.Theme

// Amiga counterpart to SiC64's inspector windows -- but shaped differently.
// SiC64 gives every panel (Events, CIA, Bus, CPU, Memory, VIC, SID) its own
// top-level window, picked from a dropdown on the main toolbar's Inspector
// button (SiAmToolbar.qml's inspectMenu, mirroring SiC64Toolbar.qml's own).
// The Amiga side has more panels (11 vs. SiC64's 7), so rather than open 11
// separate windows, this hosts every panel in a single window; the toolbar's
// dropdown just calls showPage(n) below instead of raising a distinct
// window per panel -- one toolbar, one set of chrome, switching pages
// instead of switching windows.

Window {

    id: root

    // Page indices. Must match the order of SiAmActions' per-panel
    // openXxxInspector actions and the StackLayout children below.
    enum Page {
        CPU,
        Bus,
        CIA,
        Memory,
        Agnus,
        Copper,
        Blitter,
        Paula,
        Denise,
        Port,
        Events
    }

    required property SiAmController controller
    required property SiAmActions actions
    readonly property var inspectorController: controller.inspectorController
    property int currentIndex: 0

    title: qsTr("Inspector")
    visible: false
    width: 880
    height: 440
    minimumWidth: 640
    minimumHeight: 320
    color: Palette.background

    onVisibleChanged: { inspectorController.active = visible; updateActiveController() }
    onCurrentIndexChanged: updateActiveController()
    Component.onCompleted: { inspectorController.active = visible; updateActiveController() }

    // Brings the window to the front, optionally switching to a specific page
    function showPage(page) {

        currentIndex = page
        show()
        raise()
        requestActivate()
    }

    // Per-panel controllers (SiAmEventController, SiAmCIAController, ...)
    // each carry their own 'active' flag inherited from
    // SiAmInspectorController -- unlike SiC64's one-window-per-panel
    // shape, where a window's own onVisibleChanged sets its single
    // panel's controller active, this window hosts every panel, so
    // 'active' here means "window visible AND this is the selected page."
    // Extend this switch as more panels grow real controllers to activate.
    function updateActiveController() {

        controller.eventController.active = visible && currentIndex === SiAmInspectorWindow.Page.Events
        controller.cpuController.active = visible && currentIndex === SiAmInspectorWindow.Page.CPU
        controller.deniseController.active = visible && currentIndex === SiAmInspectorWindow.Page.Denise
        controller.portController.active = visible && currentIndex === SiAmInspectorWindow.Page.Port
        controller.busController.active = visible && currentIndex === SiAmInspectorWindow.Page.Bus
        controller.ciaController.active = visible && currentIndex === SiAmInspectorWindow.Page.CIA
        controller.memoryController.active = visible && currentIndex === SiAmInspectorWindow.Page.Memory
        controller.copperController.active = visible && currentIndex === SiAmInspectorWindow.Page.Copper
        controller.blitterController.active = visible && currentIndex === SiAmInspectorWindow.Page.Blitter
        controller.paulaController.active = visible && currentIndex === SiAmInspectorWindow.Page.Paula
    }

    ColumnLayout {

        anchors.fill: parent
        spacing: 0

        SiAmInspectorToolbar {

            Layout.fillWidth: true
            amiga: root.controller
            actions: root.actions
            inspectorController: root.inspectorController
        }

        StackLayout {

            id: stack
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: root.currentIndex

            SiAmCPUPanel { controller: root.controller }
            SiAmBusPanel { controller: root.controller }
            SiAmCIAPanel { controller: root.controller }
            SiAmMemoryPanel { controller: root.controller }
            SiAmAgnusPanel { controller: root.controller }
            SiAmCopperPanel { controller: root.controller }
            SiAmBlitterPanel { controller: root.controller }
            SiAmPaulaPanel { controller: root.controller }
            SiAmDenisePanel { controller: root.controller }
            SiAmPortPanel { controller: root.controller }
            SiAmEventsPanel { controller: root.controller }
        }
    }
}
