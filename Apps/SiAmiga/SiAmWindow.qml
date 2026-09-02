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

    // No menu action opens the keyboard window yet -- there's no
    // SiAmKeyboardWindow.qml to show (see SiC64KeyboardWindow.qml for what
    // that eventually looks like).
    SiAmConfigWindow {

        id: configWindow
        controller: root.amiga
    }

    SiAmAbout {

        id: aboutWindow
        visible: false
    }
}
