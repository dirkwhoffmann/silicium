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
import Sulfur

PrefPage {

    id: root
    readonly property int labelWidth: 100
    readonly property int comboWidth: 220

    component HelpWrapper : ColumnLayout {

        spacing: 0
        width: parent.width
    }

    //
    // Toolbar
    //

    toolbar: PrefToolbar {

        backdrop: root.backgroundItem

        heading: "Advanced Settings"
        menuContent: [
            SuMenuItem {
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

        header: "EMULATOR BACKENDS"

        SuLabeledTextBox {

            id: c64Executable
            l: "C64:"
            lwidth: root.labelWidth
            controlWidth: 220
            placeholderText: "SiC64"

            text: Preferences.c64Executable
            onEditingFinished: Preferences.c64Executable = text

            HelpWrapper {

                SuLabeledTextBox {

                    placeholderText: "--native true"
                    controlWidth: 220
                    text: Preferences.c64Parameters
                    onEditingFinished: Preferences.c64Parameters = text

                    SuHelpButton {

                        id: backendHelp
                        checkable: true
                        alignment: Qt.AlignLeft
                    }

                    HelpBox {

                        visibleTarget: backendHelp.checked
                        text: "The app that is launched to run a virtual machine of the given platform, and the parameters it receives in addition to the virtual machine itself. A plain name such as \"SiC64\" refers to the app that is installed next to Silicium. A full path launches that file. The parameters are separated by spaces. Use \"--native false\" to make an app draw its own menu bar instead of using the native one on macOS. Changes take effect the next time a machine is started."
                    }
                }
            }
        }

        SuLabeledTextBox {

            l: "Amiga:"
            lwidth: root.labelWidth
            controlWidth: 220
            placeholderText: "SiAmiga"
            text: Preferences.amigaExecutable
            onEditingFinished: Preferences.amigaExecutable = text

            SuLabeledTextBox {

                placeholderText: "--native true"
                controlWidth: 220
                text: Preferences.amigaParameters
                onEditingFinished: Preferences.amigaParameters = text
            }
        }
    }

    PrefSection {

        header: "DEBUGGING"

        SuLabeledCheckBox {

            indent: root.labelWidth
            r: "Developer Mode"
            checked: Preferences.developerMode
            onCheckedChanged: Preferences.developerMode = checked
        }

        SuLabeledCheckBox {

            indent: root.labelWidth
            r: "Qt Layout Hints"
            checked: Preferences.qtDebug
            onCheckedChanged: Preferences.qtDebug = checked
        }
    }

    PrefSection {

        header: "LOGGING"

        SuLabeledCheckBox {

            indent: root.labelWidth
            r: "Include debug messages"
            checked: Preferences.logVerbosity === 2
            onCheckedChanged: Preferences.logVerbosity = checked ? 2 : 1
        }
    }
}
