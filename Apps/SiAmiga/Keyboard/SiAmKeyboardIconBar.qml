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

// Port of SiC64KeyboardIconBar.qml. The C64 bar toggles independent
// modifier previews (SHIFT/COMMODORE/CTRL/LOWER CASE); the Amiga keyboard
// has no such per-key label variants to preview. Instead this bar picks the
// physical keyboard itself -- two exclusive pairs, keyboard style (A500 vs
// A1000) and international standard (ANSI vs ISO) -- which together select
// one of AmigaKeyModel's four layouts (see its build/buildA500Ansi/
// buildA500Iso/buildA1000Ansi/buildA1000Iso).

Item {

    id: root

    property bool a1000: false
    property bool iso: false

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

        // Unlike SiC64's independent ToggleLabel, these come in pairs where
        // selecting one deselects its sibling -- a plain radio button, but
        // styled as a text label to match the rest of the bar.
        component RadioLabel: AbstractButton {

            id: radio

            checkable: true

            contentItem: SiText {

                text: radio.text
                font.pixelSize: Style.small
                color: radio.checked ? Palette.accent : Palette.tertiary
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            background: null
        }

        RadioLabel {

            text: "A500"
            checked: !root.a1000
            onClicked: root.a1000 = false
        }

        RadioLabel {

            text: "A1000"
            checked: root.a1000
            onClicked: root.a1000 = true
        }

        Divider {
        }

        RadioLabel {

            text: "ANSI"
            checked: !root.iso
            onClicked: root.iso = false
        }

        RadioLabel {

            text: "ISO"
            checked: root.iso
            onClicked: root.iso = true
        }
    }
}
