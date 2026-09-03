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

// Stub page for SiAmInspectorWindow's sidebar. Empty for now -- content
// lands once SiAmDenisePanel grows a data controller of its own (see
// SiAmInspectorController's class comment for how that's expected to plug
// in, mirroring SiC64's per-panel controllers).
Item {

    id: root

    required property SiAmController controller

    SiText {

        anchors.centerIn: parent
        text: qsTr("Denise Inspector")
        color: Palette.tertiary
    }
}
