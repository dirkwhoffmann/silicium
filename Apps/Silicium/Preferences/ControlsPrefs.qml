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
import Silicium.Preferences
import Silicium.Theme

PrefPage {

    id: root

    // required property PrefController controller
    readonly property int labelWidth: 100
    readonly property int comboWidth: 200

    // Shared model for all "Ctrl + <Modifier>" combo boxes
    readonly property var ctrlActionModel: [
        "No Action",
        "Press Commodore Key",
        "Hold Commodore Key"
    ]

    //
    // Toolbar
    //

    toolbar: PrefToolbar {

        backdrop: root.backgroundItem

        heading: "Controls Settings"
        menuContent: [
            SiMenuItem {
                text: "Restore factory defaults..."
                onTriggered: Preferences.resetControlsSettings()
            }
        ]

        HSpacer { }
    }

    //
    // Mouse
    //

    PrefSection {

        header: "MOUSE"

        SiComboBoxControl {

            l: "Hotkey:"
            lwidth: labelWidth
            controlWidth: 100
            model: [
                Shortcuts.nativeText("Ctrl+G"),
                Shortcuts.nativeText("Ctrl+M")
            ]
            currentIndex: Preferences.mouseHotkey === "Ctrl+G" ? 0 : 1
            onCurrentIndexChanged: Preferences.mouseHotkey = currentIndex == 0 ? "Ctrl+G" : "Ctrl+M"
        }

        VSpacer {
            size: Style.mediumSpacing
        }

        SiCheckBoxControl {

            id: mouseRetainEnable
            l: "Retain"
            lwidth: labelWidth
            r: "by pressing " + Shortcuts.nativeText(Preferences.mouseHotkey)
            checked: Preferences.retainMouseByPressing
            onCheckedChanged: Preferences.retainMouseByPressing = checked
        }

        SiCheckBoxControl {

            lwidth: labelWidth
            r: "by clicking inside the emulator"
            checked: Preferences.retainMouseByClicking
            onCheckedChanged: Preferences.retainMouseByClicking = checked
        }

        SiCheckBoxControl {

            lwidth: labelWidth
            r: "by double-clicking inside the emulator"
            checked: Preferences.retainMouseByDoubleClicking
            onCheckedChanged: Preferences.retainMouseByDoubleClicking = checked
        }

        VSpacer {
            size: Style.mediumSpacing
        }

        SiCheckBoxControl {

            id: mouseReleaseEnable
            l: "Release"
            lwidth: labelWidth
            r: "by pressing " + Shortcuts.nativeText(Preferences.mouseHotkey)
            checked: Preferences.releaseMouseByPressing
            onCheckedChanged: Preferences.releaseMouseByPressing = checked
        }

        SiCheckBoxControl {

            r: "by shaking"
            lwidth: labelWidth
            checked: Preferences.releaseMouseByShaking
            onCheckedChanged: Preferences.releaseMouseByShaking = checked
        }
    }

    //
    // Hotkeys
    //

    PrefSection {

        header: "HOTKEYS"

        SiComboBoxControl {

            l: "Caps Lock:"
            lwidth: labelWidth
            controlWidth: comboWidth
            model: [
                "None",
                "Toggle warp mode"
            ]
            currentIndex: Preferences.capsLockAction
            onCurrentIndexChanged: Preferences.capsLockAction = currentIndex
        }
    }

    //
    // C64 Keyboard
    //

    C64KeyRecorderWindow {

        id: keyRecorderWindow
        controller: root.controller
    }

    PrefSection {

        header: "C64 KEYBOARD"

        SiComboBoxControl {

            id: keyMapScheme
            l: "Key mapping:"
            lwidth: labelWidth
            controlWidth: comboWidth
            model: [
                "Positional",
                "Symbolic"
            ]
            currentIndex: Preferences.c64KeyMapScheme
            onCurrentIndexChanged: Preferences.c64KeyMapScheme = currentIndex

            SiControlButton {

                symbol: "edit"
                visible: Preferences.c64KeyMapScheme === 0
                onClicked: {
                    keyRecorderWindow.show()
                    keyRecorderWindow.raise()
                    keyRecorderWindow.requestActivate()
                }

                SiToolTip {

                    visible: parent.hovered
                    text: "Record key mappings"
                }
            }

            HSpacer {}
        }

        SiCheckBoxControl {

            r: "Auto-release keys"
            enabled: Preferences.c64KeyMapScheme === 1
            lwidth: labelWidth
            checked: Preferences.c64AutoReleaseKeys
            onCheckedChanged: Preferences.c64AutoReleaseKeys = checked
        }

        SiComboBoxControl {

            id: ctrlAltCombo
            l: controller.ctrlSymbol + "L" + controller.altSymbol + ":"
            lwidth: labelWidth
            controlWidth: comboWidth
            model: ctrlActionModel
            currentIndex: Preferences.c64CtrlLeftAlt
            onCurrentIndexChanged: Preferences.c64CtrlLeftAlt = currentIndex
        }

        SiComboBoxControl {

            id: ctrlRightAltCombo
            l: controller.ctrlSymbol + "R" + controller.altSymbol + ":"
            lwidth: labelWidth
            controlWidth: comboWidth
            model: ctrlActionModel
            currentIndex: Preferences.c64CtrlRightAlt
            onCurrentIndexChanged: Preferences.c64CtrlRightAlt = currentIndex
        }

        SiComboBoxControl {

            id: ctrlLeftMetaCombo
            l: controller.ctrlSymbol + "L" + controller.metaSymbol + ":"
            lwidth: labelWidth
            controlWidth: comboWidth
            model: ctrlActionModel
            currentIndex: Preferences.c64CtrlLeftMeta
            onCurrentIndexChanged: Preferences.c64CtrlLeftMeta = currentIndex
        }

        SiComboBoxControl {

            id: ctrlRightMetaCombo
            l: controller.ctrlSymbol + "R" + controller.metaSymbol + ":"
            lwidth: labelWidth
            controlWidth: comboWidth
            model: ctrlActionModel
            currentIndex: Preferences.c64CtrlRightMeta
            onCurrentIndexChanged: Preferences.c64CtrlRightMeta = currentIndex
        }
    }
}