import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Silicium.Theme

Rectangle {

    id: root

    property int maxHeight: 800
    property int maxWidth: 400
    property int watchdog: 0

    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.margins: Style.largeSpacing
    implicitHeight: Math.min(maxHeight, layout.implicitHeight + Style.largeSpacing)
    implicitWidth: Math.min(400, maxWidth)

    ListModel {
        id: notificationsModel
    }

    visible: notificationsModel.count > 0
    radius: Style.radius
    border.color: Palette.border
    color: Palette.background
    clip: true

    readonly property int info: 0
    readonly property int warning: 1

    function show(title, message, severity) {

        notificationsModel.append({
            "title": title,
            "message": message,
            "severity": severity ?? 0
        })
    }

    function close() {

        closeAnim.start()
    }

    Timer {

        id: watchdogTimer
        interval: root.watchdog
        running: interval > 0 && notificationsModel.count > 0 && !hoverHandler.hovered
        repeat: false
        onTriggered: root.close()
    }

    ScrollView {

        id: scrollView
        anchors.fill: parent

        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        ColumnLayout {

            id: layout
            width: scrollView.availableWidth
            spacing: 0

            Repeater {

                model: notificationsModel

                delegate: ItemDelegate {

                    id: delegate
                    required property string title
                    required property string message
                    required property int severity
                    required property int index

                    Layout.fillWidth: true
                    Layout.preferredHeight: notification.implicitHeight
                    Layout.leftMargin: Style.largeSpacing
                    Layout.rightMargin: Style.largeSpacing
                    Layout.topMargin: Style.largeSpacing

                    background: Rectangle {

                        anchors.fill: parent
                        color: "transparent"
                    }

                    Notification {

                        id: notification
                        implicitWidth: parent.width
                        title: delegate.title
                        message: delegate.message
                        severity: delegate.severity

                        onClose: notificationsModel.remove(delegate.index)
                    }
                }
            }
        }
    }

    //
    // Animations
    //

    Behavior on implicitHeight {

        NumberAnimation {

            duration: 800
            easing.type: Easing.InOutQuad
        }
    }

    ParallelAnimation {

        id: closeAnim

        NumberAnimation {

            target: root
            property: "height"
            to: 0
            duration: 800
            easing.type: Easing.InOutQuad
        }

        onFinished: notificationsModel.clear()
    }

    HoverHandler {

        id: hoverHandler
    }

    SiSymbolButton {

        visible: hoverHandler.hovered
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: Style.mediumSpacing
        anchors.rightMargin: Style.mediumSpacing
        symbol: "close"
        font.pixelSize: Style.huge
        onClicked: root.close()
    }
}
