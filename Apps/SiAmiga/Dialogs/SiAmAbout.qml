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
import Silicium.Theme

ApplicationWindow {

    id: root

    property string errorMessage: SiAmController.errorMessage
    readonly property bool hasError: errorMessage !== ""
    readonly property string version: qsTr("Version %1").arg(AppController.version)
    readonly property string build: qsTr("Build %1").arg(AppController.buildNr)

    title: hasError ? qsTr("SiAmiga - Error") : qsTr("About SiAmiga")
    visible: true
    width: 420
    height: 320
    minimumWidth: width
    maximumWidth: width
    minimumHeight: height
    maximumHeight: height

    Palette.appearance: Preferences.appearance
    Palette.theme: Preferences.colorTheme

    Image {

        anchors.fill: parent
        source: Assets.iconUrl(Assets.Background)
        fillMode: Image.PreserveAspectCrop
    }

    ColumnLayout {

        anchors.fill: parent
        anchors.margins: Style.largeSpacing
        spacing: Style.mediumSpacing

        Image {

            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Style.largeSpacing
            Layout.preferredWidth: 260
            Layout.preferredHeight: 110
            source: Assets.iconUrl(Assets.AmigaLogo)
            fillMode: Image.PreserveAspectFit
        }

        SiText {

            Layout.alignment: Qt.AlignHCenter
            text: qsTr("Amiga Virtual Machine")
            color: "white"
            font.pixelSize: Style.regular
        }

        SiText {

            Layout.alignment: Qt.AlignHCenter
            text: hoverArea.containsMouse ? build : version
            color: "white"
            font.pixelSize: Style.regular

            MouseArea {

                id: hoverArea
                anchors.fill: parent
                hoverEnabled: true
            }
        }

        RoundButton {

            readonly property url repository: "https://github.com/dirkwhoffmann/silicium"

            id: gitHubButton
            visible: !root.hasError
            Layout.alignment: Qt.AlignHCenter
            icon.source: Assets.iconUrl(Assets.GitHub)
            icon.width: 20
            icon.height: 20
            icon.color: hovered ? "#ffffff" : "#d0ffffff"

            background: Rectangle { color: "transparent" }
            SiToolTip { text: gitHubButton.repository }
            onClicked: Qt.openUrlExternally(gitHubButton.repository)
        }

        SiText {

            visible: root.hasError
            Layout.fillWidth: true
            text: "Error: " + root.errorMessage
            color: "lightcoral"
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
        }

        VSpacer {}

        SiButton {

            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: Style.largeSpacing
            text: root.hasError ? qsTr("Quit") : qsTr("OK")
            onClicked: root.hasError ? Qt.quit() : root.close()
        }
    }
}
