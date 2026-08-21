import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Silicium.Theme

Item {

    id: root
    property string topLabel: ""
    property string bottomLabel: ""
    property string leftLabel: ""
    property string rightLabel: ""
    property string centerLabel: ""
    property alias orientation : axis.rotation
    property alias value: axis.value
    property int length: 50

    readonly property bool vertical: orientation === 90 || orientation === -90
    Layout.preferredWidth: vertical ? 40 : length
    Layout.preferredHeight: vertical ? length : 40

    SiProgressBar {

        id: axis
        from: 0
        to: 10
        anchors.centerIn: parent
        implicitWidth: root.length
        implicitHeight: 25
        backgroundColor: Palette.surface
    }

    // Top
    SiText {

        text: root.topLabel
        anchors.bottom: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 2
        font.pixelSize: 10
        color: Palette.secondary
    }

    // Bottom
    SiText {

        text: root.bottomLabel
        anchors.top: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 2
        font.pixelSize: 10
        color: Palette.secondary
    }

    // Left
    SiText {

        text: root.leftLabel
        anchors.right: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 6
        font.pixelSize: 10
        color: Palette.secondary
    }

    // Right
    SiText {

        text: root.rightLabel
        anchors.left: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 6
        font.pixelSize: 10
        color: Palette.secondary
    }

    // Center
    SiText {

        text: root.centerLabel
        anchors.centerIn: parent
        font.bold: true
        font.pixelSize: 16
        color: Palette.primary
    }
}