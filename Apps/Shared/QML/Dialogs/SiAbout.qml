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
import Silicium.Assets
import Silicium.Controllers
import Silicium.Preferences
import Sulfur

/* The About window of an emulator app. It doubles as the error window: an app
 * that could not open the virtual machine it was asked for shows this window
 * with an error message, instead of a machine window.
 */
ApplicationWindow {

    id: root

    // The name of the app (SiC64, SiAmiga, ...)
    property string appName: ""

    // The icon of the app
    property url iconSource

    // What the machine is, e.g. "C64 Virtual Machine"
    property string tagline: ""

    // Why the app could not do what it was asked to (empty if it could)
    property string errorMessage: ""

    readonly property bool hasError: errorMessage !== ""
    readonly property string author: qsTr("Dirk W. Hoffmann, 2026")
    readonly property string version: qsTr("Version %1").arg(AppController.version)
    readonly property string build: qsTr("Build %1").arg(AppController.buildNr)

    title: ""
    flags: Qt.Window | Qt.ExpandedClientAreaHint | Qt.NoTitleBarBackgroundHint
    visible: true

    topPadding: 0
    width: 420
    height: 380
    minimumWidth: width
    maximumWidth: width
    minimumHeight: height
    maximumHeight: height

    Palette.appearance: Palette.Appearance.Dark
    Palette.theme: Palette.Thema.AppDefault

    Image {

        anchors.fill: parent
        source: Assets.iconUrl(Assets.Background)
        fillMode: Image.PreserveAspectCrop
    }

    MouseArea {

        anchors.fill: parent
        onPressed: Window.window.startSystemMove()
    }

    Shortcut {

        sequence: "Escape"
        onActivated: root.hasError ? Qt.quit() : root.close()
    }

    ColumnLayout {

        anchors.fill: parent
        anchors.margins: Style.largeSpacing
        anchors.topMargin: root.contentItem.SafeArea.margins.top
        spacing: Style.tinySpacing

        Image {

            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Style.largeSpacing
            Layout.preferredWidth: 96
            Layout.preferredHeight: 96
            source: root.iconSource
            fillMode: Image.PreserveAspectFit
            smooth: true
        }

        VSpacer {}

        SuText {

            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Style.largeSpacing
            text: "Silicium Retro Emulator"
            font.pixelSize: Style.regular
        }

        SuText {

            Layout.alignment: Qt.AlignHCenter
            text: root.tagline
            color: Palette.secondary
            font.pixelSize: Style.small
        }

        SuText {

            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Style.largeSpacing
            text: hoverArea.containsMouse ? build : version
            font.pixelSize: Style.regular

            MouseArea {

                id: hoverArea
                anchors.fill: parent
                hoverEnabled: true
            }
        }

        SuText {

            Layout.alignment: Qt.AlignHCenter
            text: root.author
            color: Palette.secondary
            font.pixelSize: Style.small
        }

        RoundButton {

            readonly property url repository: "https://github.com/dirkwhoffmann/silicium"

            id: gitHubButton
            visible: !root.hasError
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Style.largeSpacing
            icon.source: Assets.iconUrl(Assets.GitHub)
            icon.width: 20
            icon.height: 20
            icon.color: hovered ? Palette.secondary : Palette.primary  //  "#ffffff" : "#d0ffffff"

            background: Rectangle { color: "transparent" }
            SuToolTip { text: gitHubButton.repository }
            onClicked: Qt.openUrlExternally(gitHubButton.repository)
        }

        SuText {

            visible: root.hasError
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Style.largeSpacing
            text: "Error: " + root.errorMessage
            color: "lightcoral"
            wrapMode: Text.WordWrap
        }

        VSpacer {}

        SuButton {

            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: Style.largeSpacing
            text: root.hasError ? qsTr("Quit") : qsTr("OK")
            onClicked: root.hasError ? Qt.quit() : root.close()
        }
    }
}
