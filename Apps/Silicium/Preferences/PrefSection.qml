// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Silicium.Theme

Pane {

    id: root

    property bool debug: false
    property alias header: category.text
    default property alias content: mainLayout.data

    Layout.fillWidth: true
    Layout.alignment: Qt.AlignTop
    padding: Style.smallSpacing
    clip: true

    background: Rectangle {
        color: debug ? "#3000ff00" : "transparent"
    }

    ColumnLayout {

        id: mainLayout
        anchors.fill: parent
        // anchors.margins: 0
        anchors.topMargin: 0
        spacing: Style.smallSpacing

        Category {

            id: category
            topPadding: 0 // Style.mediumSpacing
            bottomPadding: Style.smallSpacing
            Layout.fillWidth: true

            Rectangle {
                anchors.fill: parent; color: "#20ff0000"; visible: root.debug
            }
        }

        // Injected children appear here
    }
}