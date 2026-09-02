import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Silicium.Controllers
import Silicium.Preferences
import Silicium.Theme

ApplicationWindow {

    id: root

    property SiAmController amiga: SiAmController

    // Referenced by SiAmMenu's View menu (the "Toolbar" shortcut hint) --
    // there's no toolbar to show/hide yet (see SiC64Window.qml for what
    // that eventually looks like), but the menu item needs a shortcut to
    // display regardless.
    readonly property string toolbarShortcut: "Ctrl+Alt+T"

    visible: true
    width: 800
    height: 600
    minimumWidth: 400
    minimumHeight: 300
    title: "SiAmiga"
    color: "black"

    Palette.appearance: Preferences.appearance
    Palette.theme: Preferences.colorTheme

    // SiC64Window doesn't hand SiC64Menu to ApplicationWindow.menuBar either
    // -- it's laid out as a row inside SiC64Toolbar instead (see
    // SiC64Toolbar.qml), which is what actually makes MenuBar-derived
    // SiMenuBar visible in this app's Fusion-styled, non-native-menu-bar
    // setup. This is a plain stand-in for that toolbar (no auto-hide, no
    // compact/hamburger mode) until SiAmiga gets one of its own.
    header: RowLayout {

        SiAmMenu {

            id: menu
            Layout.fillWidth: true
            amiga: root.amiga
            window: root

            onOpenAbout: aboutWindow.show()
            onOpenConfigurator: (page) => configWindow.showPage(page)
        }
    }

    SiAmCanvas {

        controller: root.amiga
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
