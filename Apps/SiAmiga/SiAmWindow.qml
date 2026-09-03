import QtQuick
import QtQuick.Controls
import Silicium.Controllers
import Silicium.Preferences
import Silicium.Theme

ApplicationWindow {

    id: root

    property SiAmController amiga: SiAmController

    // Shared with SiAmMenu's "Toolbar" shortcut hint.
    readonly property string toolbarShortcut: "Ctrl+Alt+T"

    property bool toolbarVisible: true
    property bool statusBarVisible: true

    // Whether the Logger overlay is showing, mirroring SiC64Window's own
    // loggerOpen -- RetroShell has its own visibility on SiAmController
    // (amiga.retroShell) since, unlike the Logger, other things also care
    // whether it's open (e.g. a future physical-keyboard passthrough would
    // need to stop routing keys to the emulator while it's up). The two are
    // mutually exclusive -- see the toolbar's RetroShell/Logger buttons.
    property bool loggerOpen: false

    // No compact-menu preference hook yet (see SiC64Window's own
    // root.compactMenu, sourced from Preferences.menuStyle) -- always false
    // until SiAmiga grows a settings surface for it.
    readonly property bool compactMenu: false

    visible: true
    width: 800
    height: 600
    minimumWidth: 400
    minimumHeight: 300
    title: "SiAmiga"
    color: "black"

    Palette.appearance: Preferences.appearance
    Palette.theme: Preferences.colorTheme

    SiAmCanvas {

        anchors.fill: parent
        controller: root.amiga
    }

    SiAmDevPanel {

        controller: root.amiga
        x: 20
        // Unlike SiC64Window's canvas (which starts below the toolbar
        // unless auto-hide is on), SiAmToolbar always floats above the
        // canvas at z: 10 -- see its own header comment. Anchoring under it
        // here, rather than reusing SiC64DevPanel's fixed y: 20, keeps this
        // panel from starting out hidden under that opaque toolbar.
        y: toolbar.height + Style.mediumSpacing
        visible: root.amiga.debugPanel && Preferences.developerMode
    }

    //
    // Console overlay (RetroShell / Logger). Port of SiC64Window's own --
    // no explicit z, so it paints below SiAmToolbar's z: 10 and the toolbar
    // stays reachable (to close the console again) while this is up.
    //

    Item {

        id: overlayPanel
        anchors.fill: parent
        opacity: (root.amiga.retroShell || root.loggerOpen) ? 0.85 : 0.0
        visible: opacity > 0.0

        Behavior on opacity {

            NumberAnimation {

                duration: 500
                easing.type: Easing.InOutQuad
            }
        }

        Rectangle {

            anchors.fill: parent
            color: "#000000"
        }

        StackView {

            id: overlayStack
            anchors.fill: parent

            replaceEnter: Transition {
                NumberAnimation { property: "opacity"; from: 0; to: 1 }
            }
            replaceExit: Transition {
                NumberAnimation { property: "opacity"; from: 1; to: 0 }
            }
        }
    }

    Component {

        id: retroShellComponent
        SiAmRetroShell {
            controller: root.amiga
            blinkingCursor: false
        }
    }

    Component {

        id: loggerComponent
        LogView {
        }
    }

    property Component currentOverlayComponent: null

    function updateOverlayStack() {

        const targetComponent = root.amiga.retroShell ? retroShellComponent
                               : root.loggerOpen ? loggerComponent
                               : null

        if (targetComponent && targetComponent !== currentOverlayComponent) {

            if (currentOverlayComponent) {
                overlayStack.replace(targetComponent)
            } else {
                overlayStack.replace(targetComponent, StackView.Immediate)
            }

            currentOverlayComponent = targetComponent
        }
    }

    onLoggerOpenChanged: updateOverlayStack()

    Connections {

        target: root.amiga

        function onRetroShellChanged() {
            updateOverlayStack()
        }
    }

    Component.onCompleted: updateOverlayStack()

    // Floats over the canvas (z above it) rather than using header:, which
    // would reserve its own layout slot above the content area -- see
    // SiC64Window.qml for the full rationale (auto-hide reveals the canvas
    // underneath instead of plain window background).
    SiAmToolbar {

        id: toolbar

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        z: 10

        amiga: root.amiga
        window: root

        onOpenAbout: aboutWindow.show()
        onOpenConfigurator: (page) => configWindow.showPage(page)
        onOpenKeyboard: {
            keyboardWindow.show()
            keyboardWindow.raise()
            keyboardWindow.requestActivate()
        }
        onOpenInspector: inspectorWindow.showPage(inspectorWindow.currentIndex)

        compactMenu: root.compactMenu

        toolbarVisible: root.toolbarVisible
        statusBarVisible: root.statusBarVisible

        onToggleToolbar: root.toolbarVisible = !root.toolbarVisible
        onToggleStatusBar: root.statusBarVisible = !root.statusBarVisible
    }

    footer: SiAmStatusbar {

        id: statusbar
        amiga: root.amiga

        visible: root.statusBarVisible
    }

    SiAmConfigWindow {

        id: configWindow
        controller: root.amiga
    }

    SiAmKeyboardWindow {

        id: keyboardWindow
        controller: root.amiga
    }

    SiAmInspectorWindow {

        id: inspectorWindow
        controller: root.amiga
    }

    SiAmAbout {

        id: aboutWindow
        visible: false
    }
}
