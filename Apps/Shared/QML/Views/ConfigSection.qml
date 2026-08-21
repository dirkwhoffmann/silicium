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
import Silicium.Preferences
import Silicium.Theme

Pane {

    id: root

    property bool debug: Preferences.qtDebug
    property alias header: category.text
    property int size: 0
    property bool checkable: false
    property alias checked: checkbox.checked
    property alias layout: mainLayout
    default property alias content: accessoryContainer.data

    implicitWidth: mainLayout.implicitWidth
    implicitHeight: mainLayout.implicitHeight + topPadding + bottomPadding
    Layout.preferredWidth: root.implicitWidth
    Layout.preferredHeight: root.implicitHeight
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.alignment: Qt.AlignTop

    clip: true

    background: Rectangle {
        color: debug ? "#3000ff00" : "transparent"
    }

    signal clicked()

    ColumnLayout {

        id: mainLayout
        anchors.fill: parent
        anchors.topMargin: 0
        spacing: Style.mediumTextSpacing

        //
        // Header
        //

        RowLayout {

            spacing: Style.smallSpacing
            Layout.preferredHeight: category.implicitHeight
            Layout.fillHeight: false

            SiCheckBox {

                id: checkbox
                visible: root.checkable
                enabled: root.enabled
                Layout.fillWidth: false
                Layout.alignment: Qt.AlignVCenter
                onClicked: root.clicked()
            }

            SiText {

                id: category
                Layout.alignment: Qt.AlignVCenter
                color: Palette.tertiary
                font.bold: true
                font.pixelSize: Style.regular
                horizontalAlignment: Text.AlignLeft
                elide: Text.ElideRight
            }

            HSpacer {}
        }

        //
        // Injected children
        //

        ColumnLayout {

            id: accessoryContainer
            visible: children.length > 0
            spacing: Style.smallSpacing
        }

        VSpacer {}
    }
}