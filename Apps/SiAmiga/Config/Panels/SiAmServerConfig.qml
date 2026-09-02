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

// Empty for now -- the GUI elements land in a later step. See
// SiAmConfigController for the properties this panel will bind to.
SettingsPage {

    id: root

    required property SiAmController controller
    readonly property var config: controller.configController

    toolbar: ConfigToolbar {

        heading: "Server Settings"

        menuContent: [
            MenuItem {
                text: "Restore factory defaults..."
                onTriggered: config.restoreServerDefaults()
            }
        ]
    }
}
