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
import QtQuick.Effects
import Silicium.Components
import Silicium.Controllers
import Silicium.Preferences
import Silicium.Theme

Rectangle {

    color: "transparent"

    ListView {

        anchors.fill: parent
        anchors.margins: Style.mediumSpacing
        model: Logger.filtered
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.AutoFlickIfNeeded
        clip: true

        // Follow the tail: keep the newest entries in view as they arrive
        onCountChanged: Qt.callLater(positionViewAtEnd)

        Connections {

            target: Preferences

            function onDeveloperPrefsChanged() {
                Logger.verbosity = Preferences.logVerbosity
            }
        }

        Component.onCompleted: {

            Logger.verbosity = Preferences.logVerbosity
            Qt.callLater(positionViewAtEnd)
        }

        delegate: Item {

            width: ListView.view.width
            height: Math.max(leftText.implicitHeight, rightText.implicitHeight)

            readonly property string prefix: {

                let indentation = "   ".repeat(model.depth || 0)

                if (Preferences.developerMode && model.message !== "") {
                    return indentation + "[" + (model.time || "") + "] "
                } else {
                    return indentation
                }
            }

            readonly property string taskText: {

                if (Preferences.developerMode && model.status === "OK") {
                    return "[" + (model.elapsed || "") + "]"
                } else {
                    return "[" + (model.status || "") + "]"
                }
            }

            readonly property color taskColor: {

                switch (model.status) {

                    case "FAILED":
                        return "lightcoral"
                    case "OK":
                        return "lightgreen"
                    default:
                        return "lightblue"
                }
            }

            readonly property color itemColor: {

                if (model.isTask) return taskColor

                switch (model.level) {

                    case Logger.Critical:
                        return "lightcoral"
                    case Logger.Warning:
                        return "yellow"
                    case Logger.Debug:
                        return "lightsteelblue"
                    default:
                        return "white"
                }
            }

            SiText {

                id: leftText
                anchors.left: parent.left
                anchors.right: rightText.left
                anchors.rightMargin: Style.mediumSpacing
                text: prefix + (model.message || "")
                color: itemColor
                font.pixelSize: 14
                font.bold: true
                wrapMode: Text.WordWrap
                maximumLineCount: 5
                elide: Text.ElideRight
            }

            SiText {

                id: rightText
                visible: model.isTask
                anchors.right: parent.right
                text: taskText
                color: taskColor
                font.pixelSize: 14
                font.bold: true
            }
        }

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }
    }
}
