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

Item {

    id: root

    property bool shift: false
    property bool commodore: false
    property bool control: false
    property bool lowercase: false

    implicitWidth: iconRow.implicitWidth
    implicitHeight: iconRow.implicitHeight

    RowLayout {

        id: iconRow
        spacing: 12

        component Divider: Rectangle {

            Layout.preferredWidth: 1
            Layout.fillHeight: true
            Layout.topMargin: Style.tinySpacing
            Layout.bottomMargin: Style.tinySpacing
            color: Palette.tertiary
        }

        component ToggleLabel: AbstractButton {

            id: toggle

            checkable: true

            contentItem: SiText {

                text: toggle.text
                font.pixelSize: Style.small
                color: toggle.checked ? Palette.accent : Palette.tertiary
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            background: null
        }

        ToggleLabel {

            text: "SHIFT"
            checked: root.shift
            onClicked: root.shift = !root.shift
        }

        Divider {
        }

        ToggleLabel {

            text: "COMMODORE"
            checked: root.commodore
            onClicked: root.commodore = !root.commodore
        }

        Divider {
        }

        ToggleLabel {

            text: "CONTROL"
            checked: root.control
            onClicked: root.control = !root.control
        }

        Divider {
        }

        ToggleLabel {

            text: "LOWER CASE"
            checked: root.lowercase
            onClicked: root.lowercase = !root.lowercase
        }
    }
}
