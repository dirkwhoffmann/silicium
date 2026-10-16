import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Sulfur

/* The base of the items in a bar (toolbar, ...). Defines the common style:
 * an icon that turns into a rounded accent-colored button on hover and press.
 */

AbstractButton {

    id: control

    property string symbol: ""
    property string awesome: ""
    property string phosphor: ""

    // Color of the icon while the item is neither disabled nor highlighted
    property color color: Palette.secondary

    // Draws the item highlighted, e.g., while a menu of the item is open
    property bool highlighted: false

    readonly property bool active: control.checked || control.pressed || control.hovered || control.highlighted

    Layout.preferredWidth: 32
    Layout.preferredHeight: Style.barItemHeight
    Layout.fillHeight: true

    padding: 0

    contentItem: SuSymbol {

        symbol: control.symbol
        awesome: control.awesome
        phosphor: control.phosphor
        scale: 0.7
        opacity: 0.8

        color: !control.enabled ? Palette.disabled
            : control.active ? Palette.accentText
                : control.color
    }

    background: Rectangle {

        anchors.fill: parent
        anchors.margins: 0
        radius: Style.radius
        color: control.enabled && control.active ? Palette.accent : "transparent"
    }
}
