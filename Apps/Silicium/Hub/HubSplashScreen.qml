// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

import QtMultimedia
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Silicium.Assets
import Silicium.Controllers
import Silicium.Preferences
import Silicium.Theme

Pane {

    id: root
    readonly property bool selectedVM: HubController.currentIndex >= 0 // screenshot !== ""

    padding: 0
    background: Rectangle { color: "transparent" }

    StackView {

        anchors.fill: parent
        id: mainStack
        initialItem: splashPage
        padding: 0
        Layout.margins: 0

        Component {
            id: splashPage
            Item {
                Image {
                    id: bgImage
                    anchors.fill: parent
                    source: Assets.iconUrl(Assets.Background)
                    fillMode: Image.Stretch
                    mipmap: true

                    Image {

                        id: overlayImage
                        source: Assets.iconUrl(Assets.Logo)
                        width: bgImage.width / 2
                        height: bgImage.height / 2
                        anchors.centerIn: parent
                        fillMode: Image.PreserveAspectFit
                        opacity: selectedVM ? 0 : 1
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 800
                                easing.type: Easing.Bezier
                            }
                        }

                        // Add a star animation effect
                        Image {
                            id: star
                            source: Assets.iconUrl(Assets.Star)
                            width: 32
                            height: 32
                            visible: opacity > 0
                            opacity: 0

                            // Position it roughly at the top-right corner
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.topMargin: 38
                            anchors.rightMargin: -10

                            // Animation sequence
                            /*
                            SoundEffect {
                                id: starSound
                                source: "qrc:/sounds/startup-sound.wav" // Note: SoundEffect prefers .wav, use Audio for .mp3
                                volume: 0.5
                                Component.onCompleted: play()
                            }
                            */
                            SequentialAnimation on opacity {
                                PauseAnimation { duration: 400 }
                                NumberAnimation { from: 0; to: 1; duration: 900; easing.type: Easing.InOutQuad }
                                NumberAnimation { from: 1; to: 0; duration: 900; easing.type: Easing.InOutQuad }
                                Component.onCompleted: start()
                            }
                            SequentialAnimation on scale {
                                PauseAnimation { duration: 400 }
                                NumberAnimation { from: 0.8; to: 1.6; duration: 900; easing.type: Easing.InOutSine }
                                NumberAnimation { from: 1.6; to: 0.8; duration: 900; easing.type: Easing.InOutSine }
                                Component.onCompleted: start()
                            }
                            RotationAnimation on rotation {
                                from: 0
                                to: 45
                                duration: 2200
                                Component.onCompleted: start()
                            }
                        }
                    }
                }
            }
        }
    }
}