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

        heading: "General Settings"
        menuContent: [
            SiMenuItem {
                text: "Restore factory defaults..."
                onTriggered: Preferences.resetGeneralSettings()
            }
        ]

        HSpacer { }
    }

    //
    // Main
    //

    PrefSection {

        header: "MACHINE LIBRARY"

        HelpWrapper {

            SiComboBoxControl {

                id: vmSortMode
                Layout.fillWidth: true
                l: "Sort by:"
                lwidth: root.labelWidth
                controlWidth: root.comboWidth
                currentIndex: Preferences.vmSortMode
                onCurrentIndexChanged: Preferences.vmSortMode = currentIndex;
                model: [
                    "Name",
                    "Created",
                    "Modified",
                    "Platform, Name",
                    "Platform, Created",
                    "Platform, Modified"
                ]

                SiHelpButton {

                    id: vmSortModeHelp
                    checkable: true
                    alignment: Qt.AlignLeft
                }

                HSpacer { }
            }

            HelpBox {

                visibleTarget: vmSortModeHelp.checked
                text: "Controls the order in which virtual machines are listed in the sidebar."
            }
        }

        HelpWrapper {

            SiCheckBoxControl {

                id: hideShowcases
                r: "Hide preinstalled machines"
                lwidth: root.labelWidth

                SiHelpButton {

                    id: hideShowcasesHelp
                    checkable: true
                    alignment: Qt.AlignLeft
                }

                HSpacer { }

                checked: Preferences.hideShowcases
                onCheckedChanged: Preferences.hideShowcases = checked
            }

            HelpBox {

                visibleTarget: hideShowcasesHelp.checked
                text: "The emulator comes with a number of preinstalled machines. Check this option to hide them from your sidebar."
            }
        }

        HelpWrapper {

            SiCheckBoxControl {

                id: resolveUUIDConflicts
                l: "Identity:"
                lwidth: root.labelWidth
                r: "Automatically resolve UUID conflicts"

                SiHelpButton {

                    id: resolveUUIDConflictsHelp
                    checkable: true
                    alignment: Qt.AlignLeft
                }

                HSpacer { }

                checked: Preferences.resolveUUIDConflicts
                onCheckedChanged: Preferences.resolveUUIDConflicts = checked
            }

            HelpBox {

                visibleTarget: resolveUUIDConflictsHelp.checked
                text: "Every virtual machine carries a unique identifier. If a machine you add has the same identifier as one already in your library, e.g., a copy of an existing machine, adding it normally fails. Check this option to assign the newcomer a new identifier automatically instead, so both copies can coexist."
            }
        }
    }

    PrefSection {

        header: "SNAPSHOT LIBRARY"

        HelpWrapper {

            SiNumberInputControl {

                id: maxSnapshots
                l: "Capacity:"
                r: "snapshots"
                lwidth: root.labelWidth
                controlWidth: 64

                SiHelpButton {

                    id: maxSnapshotsHelp
                    checkable: true
                    alignment: Qt.AlignLeft
                }

                HSpacer { }

                intValue: Preferences.maxSnapshots
                onValueEdited: (value) => Preferences.maxSnapshots = value
            }

            HelpBox {

                visibleTarget: maxSnapshotsHelp.checked
                text: "This value specifies the maximum number of snapshots to retain. When the limit is exceeded, the oldest snapshot is either deleted automatically or removed after user confirmation, depending on the auto-deletion setting. Snapshots taken on hibernation always evict the oldest entry without asking."
            }
        }

        HelpWrapper {

            SiCheckBoxControl {

                id: autoDeleteSnapshots
                r: "Auto-delete oldest snapshot"
                lwidth: root.labelWidth

                SiHelpButton {

                    id: autoDeleteSnapshotsHelp
                    checkable: true
                    alignment: Qt.AlignLeft
                }

                HSpacer { }

                checked: Preferences.autoDeleteSnapshots
                onCheckedChanged: Preferences.autoDeleteSnapshots = checked
            }

            HelpBox {

                visibleTarget: autoDeleteSnapshotsHelp.checked
                text: "When the snapshot capacity above is exceeded, the oldest snapshot is deleted automatically. If unchecked, you are asked for confirmation before it is removed."
            }
        }
    }

    PrefSection {

        header: "HIBERNATION"

        HelpWrapper {

            SiCheckBoxControl {

                id: hibernateSnapshot
                lwidth: root.labelWidth
                r: "Save snapshot"

                SiHelpButton {

                    id: hibernateSnapshotHelp
                    checkable: true
                    alignment: Qt.AlignLeft
                }

                HSpacer { }

                checked: Preferences.hibernateSnapshot
                onCheckedChanged: Preferences.hibernateSnapshot = checked
            }

            HelpBox {

                visibleTarget: hibernateSnapshotHelp.checked
                text: "Takes a snapshot of the running machine when its window closes, so the emulation can resume exactly where it left off next time you open it."
            }
        }

        HelpWrapper {

            SiCheckBoxControl {

                id: hibernateWorkspace
                lwidth: root.labelWidth
                r: "Save workspace"

                SiHelpButton {

                    id: hibernateWorkspaceHelp
                    checkable: true
                    alignment: Qt.AlignLeft
                }

                HSpacer { }

                checked: Preferences.hibernateWorkspace
                onCheckedChanged: Preferences.hibernateWorkspace = checked
            }

            HelpBox {

                visibleTarget: hibernateWorkspaceHelp.checked
                text: "Saves the current workspace (such as mounted media and peripheral configuration) when the machine's window closes, so it is restored automatically the next time the machine is opened."
            }
        }

        HelpWrapper {

            SiCheckBoxControl {

                id: showHibernationDialog
                lwidth: root.labelWidth
                r: "Ask the user for confirmation"

                SiHelpButton {

                    id: showHibernationDialogHelp
                    checkable: true
                    alignment: Qt.AlignLeft
                }

                HSpacer { }

                checked: Preferences.showHibernationDialog
                onCheckedChanged: Preferences.showHibernationDialog = checked
            }

            HelpBox {

                visibleTarget: showHibernationDialogHelp.checked
                text: "Shows a confirmation dialog when closing a machine's window, letting you choose whether to save a snapshot and/or the workspace for that occasion. If unchecked, the two options above are applied automatically without asking."
            }
        }
    }

    PrefSection {

        header: "WORKFLOW"

        HelpWrapper {

            SiCheckBoxControl {

                id: ejectWithoutAsking
                l: "Media:"
                lwidth: root.labelWidth
                r: "Eject unsaved media without asking"

                SiHelpButton {

                    id: ejectWithoutAskingHelp
                    checkable: true
                    alignment: Qt.AlignLeft
                }

                HSpacer { }

                checked: Preferences.ejectWithoutAsking
                onCheckedChanged: Preferences.ejectWithoutAsking = checked
            }

            HelpBox {

                visibleTarget: ejectWithoutAskingHelp.checked
                text: "Ejects disks and other removable media with unsaved changes immediately. If unchecked, you are asked for confirmation before any unsaved media is ejected."
            }
        }

        HelpWrapper {

            SiCheckBoxControl {

                id: pauseWhileInBackground
                l: "Activity:"
                lwidth: root.labelWidth
                r: "Pause emulation in background"

                SiHelpButton {

                    id: pauseWhileInBackgroundHelp
                    checkable: true
                    alignment: Qt.AlignLeft
                }

                HSpacer { }

                checked: Preferences.pauseWhileInBackground
                onCheckedChanged: Preferences.pauseWhileInBackground = checked
            }

            HelpBox {

                visibleTarget: pauseWhileInBackgroundHelp.checked
                text: "Pauses emulation automatically whenever the machine's window loses focus or is minimized, and resumes it when the window becomes active again."
            }
        }

        HelpWrapper {

            SiCheckBoxControl {

                id: preventSleep
                l: "Sleep:"
                lwidth: root.labelWidth
                r: "Prevent the Mac from sleeping while running"

                SiHelpButton {

                    id: preventSleepHelp
                    checkable: true
                    alignment: Qt.AlignLeft
                }

                HSpacer { }

                checked: Preferences.preventSleepWhileRunning
                onCheckedChanged: Preferences.preventSleepWhileRunning = checked
            }

            HelpBox {

                visibleTarget: preventSleepHelp.checked
                text: "Keeps the machine awake while the emulator is running. The machine is free to sleep whenever the emulator is paused, powered off, or closed."
            }
        }
    }
}
