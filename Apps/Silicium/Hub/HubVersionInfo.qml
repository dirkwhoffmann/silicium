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
import Silicium.Preferences
import Silicium.Theme

Pane {

    Layout.fillWidth: true
    padding: Style.smallSpacing

    background: Rectangle { color: Palette.surface }

    RowLayout {

        spacing: Style.tinySpacing

        RoundButton {

            id: gitHubButton
            icon.source: Assets.iconUrl(Assets.GitHub)
            icon.width: 20
            icon.height: 20
            icon.color: hovered ? Palette.primary : Palette.tertiary

            readonly property url repository: "https://github.com/dirkwhoffmann/silicium"

            background: Rectangle {
                color: "transparent"
            }

            SiToolTip {
                text: gitHubButton.repository
            }
            onClicked: {
                Qt.openUrlExternally(gitHubButton.repository)
            }
        }

        ColumnLayout {

            spacing: Style.zeroTextSpacing

            SiText {
                text: hoverArea.containsMouse ? "Build Nr " + AppController.buildNr : "Version " + AppController.version
                font.pixelSize: Style.tiny
                font.bold: false
                color: Palette.tertiary

                MouseArea {
                    id: hoverArea
                    anchors.fill: parent
                    hoverEnabled: true
                }
            }
            SiText {
                text: "Build with Qt " + AppController.qtVersion
                font.pixelSize: Style.tiny
                font.bold: false
                color: Palette.tertiary
            }
        }
    }
}