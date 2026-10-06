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
import QtQuick.Dialogs
import Silicium.Assets
import Silicium.Controllers
import Silicium.Preferences
import Sulfur

VMWindow {

    id: root

    property C64Controller c64: C64Controller
    property real aspectRatio: 800.0 / 614.0
    property alias actions: siActions

    visible: true
    width: 782
    height: 652
    minimumWidth: 400
    minimumHeight: 200
    topPadding: 0

    flags: Qt.Window | Qt.ExpandedClientAreaHint | Qt.NoTitleBarBackgroundHint
    Palette.appearance: Preferences.appearance
    Palette.theme: Preferences.colorTheme

    // References from VMWindow
    chromeRef: chrome
    controllerRef: c64
    actionsRef: siActions

    title: ""

    //
    // Main area
    //

    SiC64Chrome {

        id: chrome
        window: root
        anchors.fill: parent
        z: 10
    }

    CanvasWrapper {

        id: wrapper
        anchors.fill: parent
        anchors.topMargin: chrome.canvasStart
        anchors.bottomMargin: parent.height - chrome.canvasEnd
        aspectRatio: root.aspectRatio
        resizeMode: Preferences.resizeMode
        fadeIn: true
        poweredBySource: Assets.iconUrl(Assets.PoweredByVC)

        onClicked: {

            if (Preferences.retainMouseByClicking && !canvasOverlay.visible) {
                root.c64.captureMouse()
            }
        }

        onDoubleClicked: {
            if (Preferences.retainMouseByDoubleClicking && !canvasOverlay.visible) {
                root.c64.captureMouse()
            }
        }

        SiC64Canvas {

            id: canvas
        }
    }

    Item {

        id: overlayArea

        anchors.fill: parent
        anchors.topMargin: chrome.overlayStart
        anchors.bottomMargin: parent.height - chrome.overlayEnd
    }

    //
    // Pause overlay
    //

    PauseOverlay {

        id: pauseOverlay

        anchors.top: overlayArea.top
        anchors.right: overlayArea.right
        anchors.topMargin: Style.largeSpacing
        anchors.rightMargin: Style.largeSpacing
        controller: root.c64
    }

    //
    // Drop area
    //

    SiC64DropOverlay {

        anchors.fill: overlayArea
        window: root
    }

    //
    // Consoles
    //

    SiC64CanvasOverlay {

        id: canvasOverlay
        anchors.fill: overlayArea
    }

    //
    // Debug panel
    //

    SiC64DevPanel {

        x: 20
        y: chrome.chromeHeight + Style.mediumSpacing
        visible: root.c64.debugPanel && Preferences.developerMode
    }

    //
    // Actions
    //

    SiC64Actions {

        id: siActions
        configWindowRef: configWindow
        progressDialogRef: progressDialog
        keyboardSheetRef: keyboardSheet
        keyboardWindowRef: keyboardWindow
        eventsInspectorRef: eventsInspectorWindow
        ciaInspectorRef: ciaInspectorWindow
        busInspectorRef: busInspectorWindow
        cpuInspectorRef: cpuInspectorWindow
        memoryInspectorRef: memoryInspectorWindow
        vicInspectorRef: vicInspectorWindow
        sidInspectorRef: sidInspectorWindow
        chromeRef: chrome
        canvasOverlayRef: canvasOverlay
        aboutWindowRef: aboutWindow
        userDialogRef: userDialog
        insertDiskDialogRef: insertDiskDialog
        diskCreatorRef: diskCreatorDialog
        diskExporterRef: diskExporterDialog
        insertTapeDialogRef: insertTapeDialog
        exportTapeDialogRef: exportTapeDialog
        attachCartridgeDialogRef: attachCartridgeDialog
        exportCartridgeDialogRef: exportCartridgeDialog
    }

    //
    // Progress dialog (test of runTask)
    //

    SuProgressDialog {

        id: progressDialog
        text: ""

        Connections {

            target: root.c64
            enabled: progressDialog.visible
            function onShowProgress(what, percentage) { if (what !== "") progressDialog.text = what }
            function onBusyChanged() { if (!root.c64.busy) progressDialog.close() }
        }
    }

    //
    // File dialogs
    //

    FileDialog {

        id: insertDiskDialog
        title: qsTr("Insert Disk")
        nameFilters: [qsTr("Disk images (*.d64 *.g64 *.t64 *.prg *.p00 *.zip *.gz)"), qsTr("All files (*)")]

        property int driveNr: 8

        onAccepted: root.c64.media.insertDisk(driveNr, selectedFile)
    }

    FileDialog {

        id: insertTapeDialog
        title: qsTr("Insert Tape")
        nameFilters: [qsTr("Tape images (*.tap *.zip *.gz)"), qsTr("All files (*)")]

        onAccepted: root.c64.media.insertTape(selectedFile)
    }

    FileDialog {

        id: exportTapeDialog
        title: qsTr("Export Tape")
        fileMode: FileDialog.SaveFile
        nameFilters: [qsTr("Tape image (*.tap)")]
        defaultSuffix: "tap"

        onAccepted: root.c64.media.exportTape(selectedFile)
    }

    FileDialog {

        id: attachCartridgeDialog
        title: qsTr("Attach Cartridge")
        nameFilters: [qsTr("Cartridge images (*.crt *.zip *.gz)"), qsTr("All files (*)")]

        onAccepted: root.c64.media.attachCartridge(selectedFile)
    }

    FileDialog {

        id: exportCartridgeDialog
        title: qsTr("Export Cartridge")
        fileMode: FileDialog.SaveFile
        nameFilters: [qsTr("Cartridge image (*.crt)")]
        defaultSuffix: "crt"

        onAccepted: root.c64.media.exportCartridge(selectedFile)
    }

    //
    // Auxiliary windows
    //

    SiC64About {

        id: aboutWindow
        visible: false
    }

    SiC64DiskCreator {

        id: diskCreatorDialog
    }

    SiC64DiskExporter {

        id: diskExporterDialog
    }

    SiC64ConfigWindow {

        id: configWindow
    }

    SiC64KeyboardSheet {

        id: keyboardSheet
        anchors.horizontalCenter: parent.horizontalCenter
        slideTop: overlayArea.y
        z: 2
    }

    SiC64KeyboardWindow {

        id: keyboardWindow
    }

    SiC64EventsPanel {

        id: eventsInspectorWindow
        actions: root.actions
    }

    SiC64CIAPanel {

        id: ciaInspectorWindow
        actions: root.actions
    }

    SiC64VICPanel {

        id: vicInspectorWindow
        actions: root.actions
    }

    SiC64SIDPanel {

        id: sidInspectorWindow
        actions: root.actions
    }

    SiC64BusPanel {

        id: busInspectorWindow
        actions: root.actions
    }

    SiC64CPUPanel {

        id: cpuInspectorWindow
        actions: root.actions
    }

    SiC64MemoryPanel {

        id: memoryInspectorWindow
        actions: root.actions
    }
}
