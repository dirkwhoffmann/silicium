import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Silicium.Theme

// Toolbar button styled to match SiMenuBarItem (the menu bar's own item
// look): a borderless, rounded highlight in the accent color instead of the
// bordered, square-cornered "boxed icon" look. The toolbar is meant to read
// as the menu bar with icons standing in for text labels.
AbstractButton {

    id: control

    readonly property bool active: control.checked || control.pressed || control.hovered

    property string symbol: ""
    property string awesome: ""
    property string phosphor: ""

    /* Asks for a size in both directions.
     *
     * Height as well as width, so that a row of these is as tall as they
     * are rather than the other way round -- a toolbar that stated its own
     * height would leave the buttons stretching to whatever it happened to
     * be. Filling is kept for the case where something else in the row is
     * taller.
     */
    Layout.preferredWidth: 32
    Layout.preferredHeight: 28
    Layout.fillHeight: true
    padding: 0

    contentItem: SiSymbol {

        symbol: control.symbol
        awesome: control.awesome
        phosphor: control.phosphor
        scale: 0.7
        opacity: 0.8

        color: !control.enabled ? Palette.disabled
            : control.active   ? Palette.accentText
                : Palette.primary
    }

    background: Rectangle {

        // Inset from the button's own bounds so the highlight never touches
        // whatever the toolbar borders (e.g., the window's title bar) --
        // leaves a strip of the toolbar's own background color visible
        // around it, on all four sides.
        anchors.fill: parent
        anchors.margins: 0
        radius: 0 // Style.radius

        color: control.enabled && control.active ? Palette.accent : "transparent"
        border.color: "black"
        border.width: 0 //2
    }

    SiToolTip {

        text: control.text
    }
}
