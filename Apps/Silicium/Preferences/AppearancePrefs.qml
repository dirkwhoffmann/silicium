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
            SiMenuItem {
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

        SiComboBoxControl {

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

        SiComboBoxControl {

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

        SiComboBoxControl {

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

        SiComboBoxControl {

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

            SiComboBoxControl {

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

                SiHelpButton {

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

            SiComboBoxControl {

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

                SiHelpButton {

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

        header: "MENU AND TOOLBAR"

        HelpWrapper {

            SiComboBoxControl {

                id: menuStyle
                l: "Menu Style:"
                lwidth: root.labelWidth
                controlWidth: root.comboWidth
                model: [
                    "Standard",
                    "Compact"
                ]

                currentIndex: Preferences.menuStyle
                onCurrentIndexChanged: Preferences.menuStyle = currentIndex

                SiHelpButton {

                    id: menuStyleHelp
                    checkable: true
                    alignment: Qt.AlignLeft
                }

                HSpacer { }
            }

            HelpBox {

                visibleTarget: menuStyleHelp.checked
                text: "\"Standard\" shows the menu bar and the icon toolbar together at all times. \"Compact\" shows only one row at a time and lets you switch between them with a button embedded in the row, saving vertical space."
            }
        }

        HelpWrapper {

            SiCheckBoxControl {

                id: autoHideToolbar
                r: "Auto-hide toolbar"
                lwidth: root.labelWidth

                SiHelpButton {

                    id: autoHideToolbarHelp
                    checkable: true
                    alignment: Qt.AlignLeft
                }

                HSpacer { }

                checked: Preferences.autoHideToolbar
                onCheckedChanged: Preferences.autoHideToolbar = checked
            }

            HelpBox {

                visibleTarget: autoHideToolbarHelp.checked
                text: "Fades the toolbar out while the mouse is away from it, letting the emulated screen extend behind it, and fades it back in as soon as the mouse moves over it."
            }
        }

        HelpWrapper {

            SiCheckBoxControl {

                id: transparentMenus
                r: "Transparent menus"
                lwidth: root.labelWidth

                SiHelpButton {

                    id: transparentMenusHelp
                    checkable: true
                    alignment: Qt.AlignLeft
                }

                HSpacer { }

                checked: Preferences.transparentMenus
                onCheckedChanged: Preferences.transparentMenus = checked
            }

            HelpBox {

                visibleTarget: transparentMenusHelp.checked
                text: "Dims the menu and toolbar background so the emulated screen shows through it. The screen then extends behind the toolbar instead of starting below it."
            }
        }

        HelpWrapper {

            SiCheckBoxControl {

                id: titleBar
                r: "Show title bar"
                lwidth: root.labelWidth

                SiHelpButton {

                    id: titleBarHelp
                    checkable: true
                    alignment: Qt.AlignLeft
                }

                HSpacer { }

                checked: Preferences.titleBar
                onCheckedChanged: Preferences.titleBar = checked
            }

            HelpBox {

                visibleTarget: titleBarHelp.checked
                text: "Keeps the window's own title bar. Turning it off hands that row to the emulator window, which moves the menu and toolbar up into it, clear of the window buttons. Drag the window by any empty part of that row."
            }
        }
    }
}