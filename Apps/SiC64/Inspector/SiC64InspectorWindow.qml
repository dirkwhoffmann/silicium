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
// Generic chrome for an inspector window: size and the toolbar (see
// SiC64InspectorToolbar, a port of the old Swift-based emulator's
// InspectorToolbar).
//
// Not used directly -- SiC64EventsPanel and SiC64CIAPanel each use this as
// their root type and supply the panel-specific bits: a title, the
// sub-controller this window's content is backed by (currentController,
// activated/deactivated as the window shows/hides), and the content itself,
// declared as a plain child item. ApplicationWindow's own default content
// property (contentData) parents that child into its contentItem, so no
// custom plumbing is needed for that part.
//

ApplicationWindow {

    id: root

    required property C64Controller controller

    // The main window's shared action set (SiC64Window.actions), forwarded
    // to the toolbar so its buttons trigger the same actions as the main
    // toolbar/menu rather than duplicating their logic.
    required property SiC64Actions actions

    // Set by the specialized window to the sub-controller its content panel
    // samples, so this base window can activate/deactivate it as it's
    // shown/hidden without either subtype needing to repeat that wiring.
    required property var currentController

    onVisibleChanged: currentController.active = visible
    Component.onCompleted: currentController.active = visible

    visible: false
    width: 880
    height: 440
    minimumWidth: 640
    minimumHeight: 320
    color: Palette.background

    header: SiC64InspectorToolbar {

        controller: root.controller
        actions: root.actions
        inspectorController: root.currentController
    }
}
