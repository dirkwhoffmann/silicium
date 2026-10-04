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

    property SiAmController amiga: SiAmController
    property real aspectRatio: 4.0 / 3.0
    property alias actions: siActions

    visible: true
    width: 800
    height: 600
    minimumWidth: 400
    minimumHeight: 300
    topPadding: 0

    flags: Qt.Window | Qt.ExpandedClientAreaHint | Qt.NoTitleBarBackgroundHint
    Palette.appearance: Preferences.appearance
    Palette.theme: Preferences.colorTheme

    // References from VMWindow
    chromeRef: chrome
    controllerRef: amiga
    actionsRef: siActions

    title: ""

    //
    // Main area
    //

    SiAmChrome {

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
        poweredBySource: Assets.iconUrl(Assets.PoweredByVA)

        onClicked: {

            if (Preferences.retainMouseByClicking && !canvasOverlay.visible) {
                root.amiga.captureMouse()
            }
        }

        onDoubleClicked: {

            if (Preferences.retainMouseByDoubleClicking && !canvasOverlay.visible) {
                root.amiga.captureMouse()
            }
        }

        SiAmCanvas {

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

        anchors.fill: overlayArea
        controller: root.amiga
    }

    //
    // Drop area
    //

    SiAmDropOverlay {

        anchors.fill: overlayArea
        window: root
    }

    //
    // Consoles
    //

    SiAmCanvasOverlay {

        id: canvasOverlay
        anchors.fill: overlayArea
    }

    //
    // Debug panel
    //

    SiAmDevPanel {

        x: 20
        y: chrome.chromeHeight + Style.mediumSpacing
        visible: root.amiga.debugPanel && Preferences.developerMode
    }

    //
    // Actions
    //

    SiAmActions {

        id: siActions
        aboutWindowRef: aboutWindow
        configWindowRef: configWindow
        keyboardWindowRef: keyboardWindow
        cpuInspectorRef: cpuInspectorWindow
        logicAnalyzerRef: logicAnalyzerWindow
        xrayScannerRef: xrayScannerWindow
        ciaInspectorRef: ciaInspectorWindow
        memoryInspectorRef: memoryInspectorWindow
        agnusInspectorRef: agnusInspectorWindow
        copperInspectorRef: copperInspectorWindow
        blitterInspectorRef: blitterInspectorWindow
        paulaInspectorRef: paulaInspectorWindow
        deniseInspectorRef: deniseInspectorWindow
        portInspectorRef: portInspectorWindow
        eventsInspectorRef: eventsInspectorWindow
        hardDiskCreatorRef: hardDiskCreatorDialog
        userDialogRef: userDialog
        diskCreatorRef: diskCreatorDialog
        insertDiskDialogRef: insertDiskDialog
        exportDiskDialogRef: exportDiskDialog
        attachHdDialogRef: attachHdDialog
        exportHdDialogRef: exportHdDialog
        canvasOverlayRef: canvasOverlay
        chromeRef: chrome
    }

    //
    // File dialogs
    //

    FileDialog {

        id: insertDiskDialog
        title: qsTr("Insert Disk")
        nameFilters: [qsTr("Disk images (*.adf *.dms *.exe *.img *.st *.zip *.gz)"), qsTr("All files (*)")]

        property int driveNr: 0

        onAccepted: root.amiga.media.insertDisk(driveNr, selectedFile)
    }

    FileDialog {

        id: exportDiskDialog
        title: qsTr("Export Disk")
        fileMode: FileDialog.SaveFile
        nameFilters: [qsTr("Disk image (*.adf)")]
        defaultSuffix: "adf"

        property int driveNr: 0

        onAccepted: root.amiga.media.exportDisk(driveNr, selectedFile)
    }

    FileDialog {

        id: attachHdDialog
        title: qsTr("Attach Hard Drive")
        nameFilters: [qsTr("Hard drive images (*.hdf *.hdz)"), qsTr("All files (*)")]

        property int driveNr: 0

        onAccepted: root.amiga.media.attachHdAsync(driveNr, selectedFile)
    }

    FileDialog {

        id: exportHdDialog
        title: qsTr("Export Hard Drive")
        fileMode: FileDialog.SaveFile
        nameFilters: [qsTr("Hard drive image (*.hdf)")]
        defaultSuffix: "hdf"

        property int driveNr: 0

        onAccepted: root.amiga.media.exportHd(driveNr, selectedFile)
    }

    //
    // Auxiliary windows
    //

    SiAmAbout {

        id: aboutWindow
        visible: false
    }

    SiAmDiskCreator {

        id: diskCreatorDialog
    }

    SiAmHardDiskCreator {

        id: hardDiskCreatorDialog
    }

    SiAmConfigWindow {

        id: configWindow
    }

    SiAmKeyboardWindow {

        id: keyboardWindow
    }

    SiAmCPUPanel {

        id: cpuInspectorWindow
        actions: root.actions
    }

    SiAmLogicAnalyzerPanel {

        id: logicAnalyzerWindow
        actions: root.actions
    }

    SiAmXRayPanel {

        id: xrayScannerWindow
        actions: root.actions
    }

    SiAmCIAPanel {

        id: ciaInspectorWindow
        actions: root.actions
    }

    SiAmMemoryPanel {

        id: memoryInspectorWindow
        actions: root.actions
    }

    SiAmAgnusPanel {

        id: agnusInspectorWindow
        actions: root.actions
    }

    SiAmCopperPanel {

        id: copperInspectorWindow
        actions: root.actions
    }

    SiAmBlitterPanel {

        id: blitterInspectorWindow
        actions: root.actions
    }

    SiAmPaulaPanel {

        id: paulaInspectorWindow
        actions: root.actions
    }

    SiAmDenisePanel {

        id: deniseInspectorWindow
        actions: root.actions
    }

    SiAmPortPanel {

        id: portInspectorWindow
        actions: root.actions
    }

    SiAmEventsPanel {

        id: eventsInspectorWindow
        actions: root.actions
    }
}
