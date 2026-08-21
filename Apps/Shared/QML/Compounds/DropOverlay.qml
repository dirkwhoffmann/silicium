import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Silicium.Theme

Item {

    id: root

    property alias action1: zone1.action
    property alias action2: zone2.action
    property alias action3: zone3.action
    property alias action4: zone4.action
    property alias action5: zone5.action

    property string path: ""
    property string extension: ""
    property bool initialized: false

    readonly property int zoneWidth: Math.min((width - 6 * Style.mediumSpacing)  / 5, 128)

    // property bool active: false
    property bool mouseInRect: false
    readonly property bool active:
        windowDropArea.containsDrag ||
        overlayDragArea.containsDrag ||
        zone1.containsDrag ||
        zone2.containsDrag ||
        zone3.containsDrag ||
        zone4.containsDrag ||
        zone5.containsDrag

    Component.onCompleted: {
        initialized = true;
    }

    //
    // Outer drop area (covers the entire window)
    //

    DropArea {

        id: windowDropArea
        anchors.fill: parent

        onEntered: function(drag) {

            if (drag.urls.length !== 0) {

                path = drag.urls[0].toString()
                let name = path.substring(path.lastIndexOf("/") + 1)
                let dot  = name.lastIndexOf(".")
                extension = dot >= 0 ? name.substring(dot + 1).toLowerCase() : ""
            }
        }

        // onExited: extension = ""
    }

    //
    // Overlay
    //

    Rectangle {

        id: slidingPanel
        height: zoneRow.implicitHeight
        width:  parent.width
        color: "transparent"
        layer.enabled: true

        // Default to the hidden position and visibility
        y: -height
        visible: false

        states: [

            State {
                name: "visibleState"
                when: active
                PropertyChanges { target: slidingPanel; y: Style.largeSpacing; opacity: 1.0; visible: true }
            },
            State {
                name: "hiddenState"
                when: !active
                PropertyChanges { target: slidingPanel; y: -height; opacity: 0.0; visible: false }
            }
        ]

        transitions: [

            Transition {
                from: "hiddenState"
                to: "visibleState"
                SequentialAnimation {
                    NumberAnimation { properties: "y,opacity"; duration: 350; easing.type: Easing.OutCubic }
                }
            },
            Transition {
                from: "visibleState"
                to: "hiddenState"
                SequentialAnimation {
                    NumberAnimation { properties: "y,opacity"; duration: 350; easing.type: Easing.InCubic }
                    PropertyAction { property: "visible" }
                }
            }
        ]

        //
        // Mid drop area (covers the overlay rect)
        //

        DropArea {

            DebugRect {}

            id: overlayDragArea
            anchors.fill: parent

            onEntered: {
                console.log("Rect entered")
                mouseInRect = true
            }
            onExited: {
                console.log("Rect exited")
                mouseInRect = false
            }
        }

        //
        // Drop zones
        //

        RowLayout {

            id: zoneRow

            width: parent.width
            spacing: Style.mediumSpacing

            HSpacer {}

            DropZone {

                id: zone1
                enabled: action1.enabled
                zoneWidth: root.zoneWidth
            }

            DropZone {

                id: zone2
                enabled: action2.enabled
                zoneWidth: root.zoneWidth
            }

            DropZone {

                id: zone3
                enabled: action3.enabled
                zoneWidth: root.zoneWidth
            }

            DropZone {

                id: zone4
                enabled: action4.enabled
                zoneWidth: root.zoneWidth
            }

            DropZone {

                id: zone5
                enabled: action5.enabled
                zoneWidth: root.zoneWidth
            }

            HSpacer {}
        }
    }
}