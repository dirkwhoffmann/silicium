import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Silicium.Theme

Item {

    id: root

    // The drop targets shown in the sliding panel, left to right. Was
    // action1..action5 (a fixed five zones) until the Amiga port needed a
    // variable count -- four zones, whose four Actions themselves change
    // (df0..df3 vs. hd0..hd3) depending on what's being dragged -- see
    // SiAmDropOverlay.qml. A plain list covers both: SiC64DropOverlay binds
    // five Actions once, SiAmDropOverlay rebinds four whenever the dragged
    // file's extension changes.
    property list<Action> actions

    property string path: ""
    property string extension: ""
    property bool initialized: false

    readonly property int zoneCount: Math.max(1, actions.length)
    readonly property int zoneWidth: Math.min((width - (zoneCount + 1) * Style.mediumSpacing) / zoneCount, 128)

    // property bool active: false
    property bool mouseInRect: false

    // Number of zones currently under a drag, tallied by each DropZone
    // delegate below (see zoneRepeater) since a dynamic Repeater has no
    // fixed zone1..zoneN ids to list here individually.
    property int zoneDragCount: 0

    readonly property bool active:
        windowDropArea.containsDrag ||
        overlayDragArea.containsDrag ||
        zoneDragCount > 0

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

            Repeater {

                id: zoneRepeater
                model: root.actions

                delegate: DropZone {

                    id: zoneDelegate

                    required property Action modelData

                    action: modelData
                    enabled: modelData.enabled
                    zoneWidth: root.zoneWidth

                    onContainsDragChanged: root.zoneDragCount += containsDrag ? 1 : -1

                    // A reassigned actions list (SiAmDropOverlay swaps all
                    // four when the dragged file's extension changes)
                    // destroys and recreates every delegate -- if one was
                    // mid-drag when that happened, its contribution to
                    // zoneDragCount would otherwise never get subtracted
                    // back out.
                    Component.onDestruction: if (containsDrag) root.zoneDragCount -= 1
                }
            }

            HSpacer {}
        }
    }
}
