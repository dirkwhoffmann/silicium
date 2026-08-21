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
import Silicium.Controllers
import Silicium.Theme

Rectangle {

    id: root

    required property HubSidebarController sidebarController
    required property string title
    required property string created
    required property string modified

    required property Action leftAction
    required property Action prevAction
    required property Action nextAction
    required property Action rightAction

    color: "transparent"

    RowLayout {

        anchors.fill: parent
        spacing: 0

        //
        // Left button
        //

        SiOverlayButton {

            size: 72
            symbol: leftAction?.icon.name ?? ""

            // Opacity will trigger the sliding button animation
            visible: opacity > 0
            opacity: root.leftAction ? 1.0 : 0.0

            Layout.fillHeight: true
            Layout.preferredWidth: root.leftAction ? size : 0
            Layout.preferredHeight: size

            Behavior on opacity {
                NumberAnimation { duration: 400; easing.type: Easing.InOutQuad }
            }
            Behavior on Layout.preferredWidth {
                NumberAnimation { duration: 400; easing.type: Easing.InOutQuad }
            }

            onClicked: root.leftAction.trigger()
        }

        //
        // Main info area
        //

        SiOverlayRect {

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: Style.mediumSpacing
            Layout.rightMargin: Style.mediumSpacing

            RowLayout {

                anchors.fill: parent
                spacing: Style.mediumSpacing

                ColumnLayout {

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 0

                    VSpacer {
                    }

                    RowLayout {

                        SiOverlayButton {

                            symbol: prevAction.icon.name
                            enabled: prevAction.enabled
                            background: Rectangle { color: "transparent" }
                            implicitWidth: 32
                            scaleFactor: 1.2
                            onClicked: prevAction.trigger()
                        }

                        SiText {

                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignHCenter
                            horizontalAlignment: Text.AlignHCenter
                            text: root.title
                            color: "white"
                            font.pixelSize: Style.large
                            font.bold: true
                        }

                        SiOverlayButton {

                            symbol: nextAction.icon.name
                            enabled:  nextAction.enabled
                            background: Rectangle { color: "transparent" }
                            implicitWidth: 32
                            scaleFactor: 1.2
                            onClicked: nextAction.trigger()
                        }
                    }

                    HLine {
                    }

                    SiText {

                        Layout.alignment: Qt.AlignHCenter
                        horizontalAlignment: Text.AlignHCenter
                        text: hoverArea.containsMouse ? "Modified on " + root.modified : "Created on " + root.created
                        font.pixelSize: Style.large
                        color: "#D0FFFFFF"

                        MouseArea {
                            id: hoverArea
                            anchors.fill: parent
                            hoverEnabled: true
                        }
                    }

                    VSpacer {
                    }
                }
            }
        }

        //
        // Right button
        //

        SiOverlayButton {

            size: 72
            symbol: rightAction?.icon.name ?? ""

            visible: opacity > 0
            opacity: root.rightAction ? 1.0 : 0.0
            Layout.fillHeight: true
            Layout.preferredWidth: root.rightAction ? size : 0
            Layout.preferredHeight: size

            Behavior on opacity {
                NumberAnimation { duration: 400; easing.type: Easing.InOutQuad }
            }
            Behavior on Layout.preferredWidth {
                NumberAnimation { duration: 400; easing.type: Easing.InOutQuad }
            }

            onClicked: root.rightAction.trigger()
        }
    }
}
