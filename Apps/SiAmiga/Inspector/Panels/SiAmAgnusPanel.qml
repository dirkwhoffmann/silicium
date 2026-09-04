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

// Stub window (see SiAmInspectorWindow.qml). Empty for now -- content lands
// once SiAmAgnusPanel grows a data controller of its own (see
// SiAmInspectorController's class comment for how that's expected to plug
// in, mirroring SiC64's per-panel controllers). Until then this borrows
// SiAmController's shared inspectorController instance as a placeholder
// currentController -- harmless since it carries no panel-specific data,
// just the active flag this window needs to toggle on show/hide.
SiAmInspectorWindow {

    id: root

    title: qsTr("Agnus Inspector")
    currentController: controller.inspectorController

    SiText {

        anchors.centerIn: parent
        text: qsTr("Agnus Inspector")
        color: Palette.tertiary
    }
}
