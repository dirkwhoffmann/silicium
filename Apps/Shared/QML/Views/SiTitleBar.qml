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

Rectangle {

    id: root

    // Text shown in the center
    property string title: ""

    // Visual style
    required property bool overlayed
    required property bool unified
    required property bool hidden

    // Items placed at the right-hand side of the bar
    property alias content: slot.data

    // Computed properties
    readonly property bool hideTitleBar: hidden && overlayed && unified

    // Colors
    readonly property real alpha: overlayed && unified ? 0.9 : 1.0
    readonly property color titleBarBg: unified ? Palette.toolbar : Palette.background

    color: hideTitleBar ? "transparent" : Qt.alpha(root.titleBarBg, root.alpha)

    //
    // Mouse area
    //

    MouseArea {

        anchors.fill: parent
        onPressed: Window.window.startSystemMove()
    }

    //
    // Main
    //

    Text {

        anchors.centerIn: parent
        visible: !root.hideTitleBar
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

    //
    // Separator
    //

    Rectangle {

        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; bottomMargin: 0 }
        height: 1

        visible: !root.hideTitleBar
        // color: Qt.alpha(Palette.backdrop, root.alpha)
        color: Qt.alpha(Palette.toolbar.lighter(1.05), root.alpha)
    }

    Rectangle {

        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; bottomMargin: 1 }
        height: 1

        visible: !root.hideTitleBar
        // color: Palette.toolbar.darker(1.1)
        color: Qt.alpha(Palette.toolbar.darker(1.1), root.alpha)
    }
}
