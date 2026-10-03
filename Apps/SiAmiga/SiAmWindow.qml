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
import Silicium.Controllers
import Silicium.Preferences
import Silicium.Theme

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

    // The chrome the base class hides in fullscreen mode
    chromeRef: chrome

    // The machine the base class pauses while the window is in the background
    controllerRef: amiga

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
    // Auxiliary components
    //

    SiAmDevPanel {

        x: 20
        // The chrome floats above everything else. Anchoring under it, rather
        // than using a fixed y, keeps this panel from starting out hidden
        // under the command bar.
        y: chrome.chromeHeight + Style.mediumSpacing
        visible: root.amiga.debugPanel && Preferences.developerMode
    }

    NotificationCenter {

        id: notifications
        maxWidth: root.width - 2 * Style.largeSpacing
        maxHeight: root.height - 2 * Style.largeSpacing
        watchdog: 0
        z: 999
    }

    SiHintBanner {

        id: hintBanner
    }

    //
    // Connections
    //

    Connections {

        target: root.amiga

        // What the controller reports when an action of ours fails, e.g.
        // loading a snapshot from a machine that has none.
        function onShowError(title, text) {

            root.showError(title, text)
        }

        // Worth saying, not worth interrupting for -- e.g. that a hard drive
        // just created is too large to travel in a snapshot. VMWindow does
        // the same for SiC64.
        function onShowNotification(title, message) {

            notifications.show(title, message)
        }
    }

    //
    // Auxiliary windows
    //

    FileDialog {

        id: insertDiskDialog
        title: qsTr("Insert Disk")
        nameFilters: [qsTr("Disk images (*.adf *.dms *.exe *.img *.st *.zip *.gz)"), qsTr("All files (*)")]

        property int driveNr: 0

        onAccepted: root.amiga.media.insertDisk(driveNr, selectedFile)
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

    SiAmAbout {

        id: aboutWindow
        visible: false
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
        userDialogRef: errorDialog
        diskCreatorRef: diskCreatorDialog
        insertDiskDialogRef: insertDiskDialog
        canvasOverlayRef: canvasOverlay
        chromeRef: chrome
    }

    //
    // Errors
    //

    function showError(title, text) {

        errorDialog.titleText = title
        errorDialog.bodyText = text
        errorDialog.buttons = Dialog.Ok
        errorDialog.okLabel = qsTr("OK")
        errorDialog.acceptedCallback = null
        errorDialog.open()
    }

    SiUserDialog {

        id: errorDialog
        sound: true
    }

    //
    // Closing
    //

    ShutDownManager {

        id: shutDownManager
        controller: root.amiga
    }

    onClosing: function(closeEvent) { shutDownManager.windowClosing(closeEvent) }
}
