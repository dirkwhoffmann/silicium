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

        heading: "Appearance Settings"
        menuContent: [
            SuMenuItem {
                text: "Restore factory defaults..."
                onTriggered: Preferences.resetAppearanceSettings()
            }
        ]

        HSpacer { }
    }

    //
    // Main
    //

    PrefSection {

        header: "THEMES"

        SuLabeledComboBox {

            l: "Color Theme:"
            lwidth: root.labelWidth
            controlWidth: root.comboWidth
            model: [
                "Default",
                "Solaris"
            ]

            currentIndex: Preferences.colorTheme
            onCurrentIndexChanged: {
                Preferences.colorTheme = currentIndex
            }
        }

        SuLabeledComboBox {

            Layout.preferredWidth: root.comboWidth + root.labelWidth
            Layout.fillWidth: false
            l: "Appearance:"
            indent: root.labelWidth
            model: [
                "System",
                "Light",
                "Dark"
            ]

            currentIndex: Preferences.appearance
            onCurrentIndexChanged: {
                Preferences.appearance = currentIndex
            }
        }

        SuLabeledComboBox {

            l: "Fonts:"
            lwidth: root.labelWidth
            controlWidth: root.comboWidth
            model: [
                "System Default",
                "Classic",
                "Futuristic",
                "Solaris"
            ]

            currentIndex: Preferences.fontTheme
            onCurrentIndexChanged: {
                Preferences.fontTheme = currentIndex
            }
        }

        SuLabeledComboBox {

            l: "Monospaced:"
            lwidth: root.labelWidth
            controlWidth: root.comboWidth
            model: [
                "Sans-serif",
                "Serif"
            ]

            currentIndex: Preferences.monoFontTheme
            onCurrentIndexChanged: {
                Preferences.monoFontTheme = currentIndex
            }
        }
    }

    PrefSection {

        header: "EMULATOR WINDOW"

        HelpWrapper {

            SuLabeledComboBox {

                id: resizeMode
                l: "Resizing:"
                lwidth: root.labelWidth
                controlWidth: root.comboWidth
                model: [
                    "Stretch",
                    "Letterbox",
                    "Crop"
                ]

                currentIndex: Preferences.resizeMode
                onCurrentIndexChanged: Preferences.resizeMode = currentIndex

                SuHelpButton {

                    id: resizeModeHelp
                    checkable: true
                    alignment: Qt.AlignLeft
                }

                HSpacer { }
            }

            HelpBox {

                visibleTarget: resizeModeHelp.checked
                text: "Controls how the emulated screen fills the window when its aspect ratio doesn't match the window's. \"Stretch\" fills the window completely, distorting the picture if needed. \"Letterbox\" preserves the aspect ratio and adds bars around the picture. \"Crop\" fills the window completely and clips whatever doesn't fit."
            }
        }

        HelpWrapper {

            SuLabeledComboBox {

                id: statusbar
                l: "Statusbar:"
                lwidth: root.labelWidth
                controlWidth: root.comboWidth
                model: [
                    "None",
                    "Windows",
                    "Windows + Fullscreen",
                ]
                Layout.fillWidth: true

                currentIndex: Preferences.statusbar
                onCurrentIndexChanged: Preferences.statusbar = currentIndex

                SuHelpButton {

                    id: statusbarHelp
                    checkable: true
                    alignment: Qt.AlignLeft
                }

                HSpacer { }
            }

            HelpBox {

                visibleTarget: statusbarHelp.checked
                text: "Controls when the status bar at the bottom of the emulator window is shown: never, only while in a regular window, or in both windowed and fullscreen mode."
            }
        }
    }

    PrefSection {

        header: "CHROME"

        HelpWrapper {

            SuLabeledComboBox {

                id: chromePlacement
                l: "Placement:"
                lwidth: root.labelWidth
                controlWidth: root.comboWidth
                model: [
                    "Attached",
                    "Overlayed"
                ]

                currentIndex: Preferences.chromePlacement
                onCurrentIndexChanged: Preferences.chromePlacement = currentIndex

                SuHelpButton {

                    id: chromePlacementHelp
                    checkable: true
                    alignment: Qt.AlignLeft
                }

                HSpacer { }
            }

            HelpBox {

                visibleTarget: chromePlacementHelp.checked
                text: "\"Attach\" gives the window its usual title bar, with the menu and toolbar below it and the emulated screen below that, so all of the screen stays visible. \"Overlay\" drops the title bar, leaving only the window buttons, and lets the screen fill the whole window with the menu and toolbar laid over it in the same place as before. The button at the right-hand end of that row then hides and shows them."
            }
        }

        HelpWrapper {

            SuLabeledComboBox {

                id: chromeTitleBar
                l: "Title Bar:"
                lwidth: root.labelWidth
                controlWidth: root.comboWidth
                model: [
                    "Standard",
                    "Unified"
                ]

                currentIndex: Preferences.chromeTitleBar
                onCurrentIndexChanged: Preferences.chromeTitleBar = currentIndex

                SuHelpButton {

                    id: chromeTitleBarHelp
                    checkable: true
                    alignment: Qt.AlignLeft
                }

                HSpacer { }
            }

            HelpBox {

                visibleTarget: chromeTitleBarHelp.checked
                text: "How the title bar row is filled. \"Standard\" gives it the usual title bar background, so the menu and toolbar read as something separate below it. \"Unified\" gives it the same colour as the menu and toolbar, so the whole thing reads as one block of chrome."
            }
        }

        HelpWrapper {

            SuLabeledComboBox {

                id: chromeLayout
                l: "Controls:"
                lwidth: root.labelWidth
                controlWidth: root.comboWidth
                model: [
                    "Standard",
                    "Compact"
                ]

                currentIndex: Preferences.chromeLayout
                onCurrentIndexChanged: Preferences.chromeLayout = currentIndex

                SuHelpButton {

                    id: chromeLayoutHelp
                    checkable: true
                    alignment: Qt.AlignLeft
                }

                HSpacer { }
            }

            HelpBox {

                visibleTarget: chromeLayoutHelp.checked
                text: "\"Standard\" shows the menu bar and the icon toolbar together at all times. \"Compact\" shows only one row at a time and lets you switch between them with a button embedded in the row, saving vertical space."
            }
        }

    }
}