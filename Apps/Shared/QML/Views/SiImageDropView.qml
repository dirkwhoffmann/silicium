import QtQuick
import QtQuick.Controls

Item {
    id: root

    // Image shown inside the drop zone
    property alias source: image.source

    // Emitted when something is dropped
    signal urlsDropped(var urls)

    // Emitted when the view is clicked
    signal clicked()

    // Override from outside to decide acceptance
    property var acceptUrls: function(urls) { return true }

    implicitWidth: 120
    implicitHeight: 120

    Rectangle {

        id: background
        anchors.fill: parent
        radius: 12

        // No hover or drag highlight while disabled -- the zone must not
        // invite an interaction it is going to refuse.
        color: root.enabled && (dropArea.containsDrag || mouseArea.containsMouse) ? "#30ffffff" : "#10ffffff"
        border.color: root.enabled && dropArea.containsDrag ? "#a0ffffff" : "#40ffffff"
        border.width: 2

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }

        Image {

            id: image
            anchors.centerIn: parent
            width: parent.width * 0.9
            height: parent.height * 0.9
            fillMode: Image.PreserveAspectFit
        }
    }

    DropArea {

        id: dropArea
        anchors.fill: parent

        onDropped: (drop) => {

            /* A disabled DropArea already stops receiving drags, so this is a
             * backstop rather than the primary gate -- but leaving the drop
             * ungated would mean any future path that reaches this handler
             * silently bypasses the lock, and refusing the action here is what
             * makes the rejection explicit to the drag source.
             */
            if (!root.enabled)
                return

            if (!drop.hasUrls)
                return

            const urls = drop.urls
            if (root.acceptUrls(urls)) {
                root.urlsDropped(urls)
                drop.acceptProposedAction()
            }
        }
    }

    MouseArea {

        id: mouseArea

        /* Told explicitly rather than left to inherit: MouseArea redeclares
         * `enabled`, so unlike the DropArea above it does not pick up a
         * disabled ancestor -- the property keeps reading true and the
         * hover highlight and click-to-browse would survive the lock.
         */
        enabled: root.enabled

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}