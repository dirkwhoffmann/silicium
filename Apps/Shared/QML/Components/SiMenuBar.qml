import QtQuick
import QtQuick.Controls
import Silicium.Theme

MenuBar {

    id: root

    onVisibleChanged: if (!visible) currentIndex = -1

    delegate: SiMenuBarItem { }

    background: Rectangle {

        color: Palette.toolbar
    }
}
