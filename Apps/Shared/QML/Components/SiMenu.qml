import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Silicium.Theme

Menu {

    id: root

    topPadding: Style.mediumSpacing
    bottomPadding: Style.mediumSpacing
    leftPadding: Style.mediumSpacing
    rightPadding: Style.mediumSpacing

    delegate: SiMenuItem {
    }

    // True if at least one item in this menu currently shows a checkmark.
    // Consulted by SiMenuItem to decide whether the checkmark gutter should
    // be reserved for every row (so labels line up) or dropped entirely
    // (so a menu with no checkable items isn't needlessly indented).
    readonly property bool hasCheckmark: {

        for (let i = 0; i < count; i++) {

            const item = itemAt(i)
            if (item && item.checkable && item.checked) return true
        }
        return false
    }

    readonly property real maxItemWidth: {

        let w = 0
        for (let i = 0; i < count; i++) {

            const item = itemAt(i)
            if (item) w = Math.max(w, item.implicitWidth)
        }
        return w
    }

    implicitWidth: Math.max(maxItemWidth + leftPadding + rightPadding, 160)

    background: Rectangle {

        color: Qt.alpha(Palette.background, 0.96)
        radius: Style.radius
        border.color: Palette.border
        border.width: 1
    }
}
