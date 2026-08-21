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
import Silicium.Preferences
import Silicium.Theme

PrefPage {

    id: root
    readonly property int labelWidth: 100
    readonly property int comboWidth: 220

    //
    // Toolbar
    //

    toolbar: PrefToolbar {

        backdrop: root.backgroundItem

        heading: "Developer Settings"
        menuContent: [
            SiMenuItem {
                text: "Restore factory defaults..."
                onTriggered: Preferences.resetDeveloperSettings()
            }
        ]

        HSpacer { }
    }

    //
    // Main
    //

    PrefSection {

        header: "DEBUGGING"

        SiCheckBoxControl {

            indent: root.labelWidth
            r: "Developer Mode"
            checked: Preferences.developerMode
            onCheckedChanged: Preferences.developerMode = checked
        }

        SiCheckBoxControl {

            indent: root.labelWidth
            r: "Qt Layout Hints"
            checked: Preferences.qtDebug
            onCheckedChanged: Preferences.qtDebug = checked
        }
    }

    PrefSection {

        header: "LOGGING"

        SiCheckBoxControl {

            indent: root.labelWidth
            r: "Include debug messages"
            checked: Preferences.logVerbosity === 2
            onCheckedChanged: Preferences.logVerbosity = checked ? 2 : 1
        }
    }
}