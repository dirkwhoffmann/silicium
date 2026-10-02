// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

import QtQuick
import Silicium.Theme

/* The window's title bar row, drawn in QML. The native title is not used,
 * because its view swallows mouse clicks and so blocks dragging the window.
 *
 * Dragging the bar moves the window.
 *
 * The component is as tall as it is told to be (set 'height' to the title bar
 * inset of the window) and doesn't position itself.
 *
 * unified:
 *
 *   If true, the title bar gets the same colour as the command bar, so both
 *   read as one block of chrome. If false, it gets the window background.
 *
 * hidden:
 *
 *   True if the command bar is hidden. A unified title bar then disappears
 *   with it, leaving only the window buttons.
 */

Rectangle {

    id: root

    // Text shown in the center
    property string title: ""

    // Visual style
    property bool unified: false
    property bool hidden: false

    // Items placed at the right-hand side of the bar
    property alias content: slot.data

    // Computed properties
    readonly property bool showTitleBar: !root.hidden || !root.unified

    // Colors
    readonly property real alpha: 1.0
    readonly property color titleBarBg: root.unified ? Palette.toolbar : Palette.background

    color: showTitleBar ? Qt.alpha(root.titleBarBg, root.alpha) : "transparent"

    // Dragging the title bar moves the window. Declared first, so that the
    // items on top of it (the title and the content) get their clicks.
    MouseArea {

        anchors.fill: parent
        onPressed: Window.window.startSystemMove()
    }

    Text {

        anchors.centerIn: parent
        visible: root.showTitleBar
        text: root.title
        color: Palette.secondary
        font.bold: true
        elide: Text.ElideRight
        width: Math.min(implicitWidth, parent.width / 2)
        horizontalAlignment: Text.AlignHCenter
    }

    Row {

        id: slot

        anchors.right: parent.right
        anchors.rightMargin: Style.mediumSpacing
        anchors.verticalCenter: parent.verticalCenter

        spacing: Style.smallSpacing
    }
}
