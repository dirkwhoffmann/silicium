import QtQuick
import QtQuick.Controls

MenuBar {

    id: root

    onVisibleChanged: if (!visible) currentIndex = -1

    // The default paddings are the safe area margins, which under an expanded
    // client area include the title bar and would inflate the height.
    topPadding: 0
    bottomPadding: 0

    delegate: SiMenuBarItem { }

    background: Rectangle {

        color: "transparent"
    }
}
