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
import Silicium.Controllers
import Silicium.Theme

Item {

    id: root

    property bool lockText: false

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    signal clicked()

    RowLayout {

        id: layout
        spacing: Style.smallSpacing
        Layout.alignment: Qt.AlignVCenter

        ColumnLayout {

            visible: root.lockText
            spacing: Style.zeroTextSpacing

            SiText {

                DebugRect {}
                text: "Some options are locked."
                Layout.alignment: Qt.AlignRight
                font.pixelSize: Style.small
                font.bold: true
                horizontalAlignment: Text.AlignRight
                width: contentWidth
            }
            SiText {

                DebugRect {}
                text: "Click to power down and unlock."
                Layout.alignment: Qt.AlignRight
                font.pixelSize: Style.small
                horizontalAlignment: Text.AlignRight
                width: contentWidth
            }
        }

        SiSymbolButton {

            Layout.preferredWidth: Style.iconLarge
            Layout.preferredHeight: Style.iconLarge
            font.pixelSize: Style.huge
            symbol: "power_settings_new"
            DebugRect {}
            onClicked: root.clicked()
        }
    }
}
