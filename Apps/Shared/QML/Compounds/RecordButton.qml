import QtQuick
import QtQuick.Controls
import Silicium.Controllers
import Silicium.Theme

FocusScope {

    id: root

    property string topLabel: ""
    property string bottomLabel: ""
    property string leftLabel: ""
    property string rightLabel: ""
    property string centerLabel: ""
    property bool triggered: false
    property bool listening: false
    property bool recordable: false
    property bool labels: recordable

    onListeningChanged: {

        if (listening) {
            root.forceActiveFocus()
        }
    }

    implicitWidth: 40
    implicitHeight: 40

    // Rather than installing a per-item event filter, watch the input
    // manager's last-pressed-key properties directly: AppController.inputManager
    // updates qKey/pKey and emits keyChanged() for every key event in the
    // app, regardless of which item currently has focus.
    Connections {

        target: AppController.inputManager

        function onKeyChanged() {

            if (root.listening) {

                const key = AppController.inputManager.qKey
                const virtualKey = AppController.inputManager.pKey

                console.log("KEY RECORDED " + key + " virtual: " + virtualKey)
                if (key >= 0) {
                    keyRecorded(key, virtualKey)
                }
            }
        }
    }

    signal keyRecorded(int key, int virtualKey)
    signal clicked()

    SiButton {

        id: keyButton

        anchors.fill: parent
        enabled: root.recordable
        text: root.centerLabel
        font.pixelSize: Style.small
        accentedDown: true
        down: root.listening

        onClicked: root.clicked()

        Rectangle {

            anchors.fill: parent
            radius: Style.radius
            color: "#400080FF"
            visible: root.triggered
        }

        //
        // Top
        //

        SiText {

            visible: root.labels
            text: root.topLabel
            anchors.bottom: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 2
            font.pixelSize: 10
            color: Palette.secondary
        }

        //
        // Bottom
        //

        SiText {

            visible: root.labels
            text: root.bottomLabel
            anchors.top: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 2
            font.pixelSize: 10
            color: Palette.secondary
        }

        //
        // Left
        //

        SiText {

            visible: root.labels
            text: root.leftLabel
            anchors.right: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: 6
            font.pixelSize: 10
            color: Palette.secondary
        }

        //
        // Right
        //

        SiText {

            visible: root.labels
            text: root.rightLabel
            anchors.left: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 6
            font.pixelSize: 10
            color: Palette.secondary
        }
    }
}
