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
import Silicium.Assets
import Silicium.Controllers
import Silicium.Theme

Image {

    property string title: ""
    property string author: ""
    property string description: ""
    property bool comingSoon: false

    fillMode: Image.PreserveAspectCrop
    smooth: true
    cache: false

    //
    // Showcase overlay
    //

    Item {

        anchors.fill: parent
        visible:  description !== ""

        //
        // Left Gradient
        //

        Rectangle {

            visible: description !== ""
            anchors.fill: parent
            gradient: Gradient {

                orientation: Gradient.Horizontal
                GradientStop {
                    position: 0.2; color: "#d0000000"
                }
                GradientStop {
                    position: 0.5; color: "#b0000000"
                }
                GradientStop {
                    position: 1.0; color: "transparent"
                }
            }
        }

        //
        // Description
        //

        Rectangle {

            visible: description !== ""
            width: parent.width
            height: parent.height * 0.85
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.leftMargin: Style.largeSpacing
            anchors.topMargin: Style.smallSpacing

            color: "transparent"

            ScrollView {

                id: scrollView
                anchors.fill: parent
                anchors.margins: Style.largeSpacing
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical.policy: ScrollBar.AlwaysOff

                contentWidth: availableWidth

                ColumnLayout {

                    width: scrollView.availableWidth
                    spacing: 0

                    SiText {

                        color: "#CCE5FF" // "#99CCFF"
                        font.pixelSize: 64
                        font.family: Fonts.showcaseTitleFont
                        text: title

                        DebugRect {
                        }
                    }

                    SiText {

                        Layout.topMargin: -8
                        text: author
                        color: "white"
                        font.pixelSize: Style.huge
                        font.family: Fonts.showcaseSubtitleFont
                        font.bold: true
                        Layout.bottomMargin: Style.largeSpacing

                        DebugRect {
                        }
                    }

                    SiText {

                        Layout.preferredWidth: 0.6 * scrollView.availableWidth
                        text: description + "\n\n\n"
                        wrapMode: Text.WordWrap
                        textFormat: TextEdit.MarkdownText
                        color: "#cccccc"
                        font.family: Fonts.showcaseMainFont
                        font.pixelSize: Style.huge

                        DebugRect {
                        }
                    }
                }
            }
        }

        //
        // Bottom Gradient
        //

        /*
        Rectangle {

            anchors.fill: parent
            gradient: Gradient {

                orientation: Gradient.Vertical
                GradientStop {
                    position: 0.65; color: "transparent"
                }
                GradientStop {
                    position: 0.80; color: "black"
                }
            }
        }
        */

        Image {

            visible: comingSoon
            anchors.centerIn: parent
            source: Assets.iconUrl(Assets.ComingSoon)
            sourceSize.width: 400
            fillMode: Image.PreserveAspectFit
            rotation: 0
        }
    }

    //
    // Animation
    //

    NumberAnimation on opacity {

        id: screenshotFadeIn
        duration: 800
        easing.type: Easing.OutCubic
        from: 0
        to: 1
    }

    Connections {

        target: HubController

        function onSelectionChanged() {
            screenshotFadeIn.restart()
        }
    }
}