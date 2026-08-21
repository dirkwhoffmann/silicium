import QtQuick
import QtQuick.Layouts
import Silicium.Controllers
import Silicium.Preferences

Item {

    id: root

    required property real aspectRatio // : 16 / 9
    required property int resizeMode

    // Resize modes
    readonly property int stretch: 0
    readonly property int fit: 1
    readonly property int crop: 2
    property bool fadeIn: true

    // Background color (for letterboxing)
    property color backgroundColor: "black"

    // Expose the actual canvas size
    readonly property real contentWidth: container.width
    readonly property real contentHeight: container.height

    // Default content
    default property alias content: contentItem.data

    implicitWidth: 400
    implicitHeight: 300

    signal clicked()
    signal doubleClicked()

    //
    // Background
    //

    Image {

        id: bgImage
        anchors.fill: parent
        visible: slowAnimation.running || fastAnimation.running
        source: Assets.iconUrl(Assets.Background)
        fillMode: Image.PreserveAspectCrop

        Image {

            source: Assets.iconUrl(Assets.PoweredByVC)
            anchors.centerIn: parent
            width: 0.65 * parent.width
            fillMode: Image.PreserveAspectFit
        }
    }

    //
    // Mouse capture
    //

    /* Below the foreground on purpose.
     *
     * This is the fallback "click the canvas to grab the mouse" handler, so
     * it has to sit underneath whatever the caller puts in the wrapper --
     * declared last it would cover the content and swallow its input (which
     * is what happened to SiC64DevPanel). The canvas itself accepts no mouse
     * events, so clicks on it still fall through to here.
     */
    MouseArea {

        // id: mouseCaptureArea
        anchors.fill: parent
        hoverEnabled: true
        preventStealing: true

        onPressed: {

            root.clicked()
        /*
            //if (Preferences.retainMouseByClicking && !controller.retroShell) {
            if (Preferences.retainMouseByClicking) {
                console.log("Capture mouse")
                // AppController.inputManager.captureMouse = true
            }

         */
        }

        onDoubleClicked: root.doubleClicked()
    }

    //
    // Foreground
    //

    Rectangle {

        id: container
        anchors.fill: parent
        color: root.backgroundColor
        opacity: 0

        //
        // Emulator texture
        //

        Item {

            anchors.centerIn: parent

            width: {
                switch (root.resizeMode) {
                    case root.stretch:
                        return root.width
                    case root.fit:
                        return Math.min(root.width, root.height * root.aspectRatio)
                    case root.crop:
                        return Math.max(root.width, root.height * root.aspectRatio)
                }
            }

            height: {
                switch (root.resizeMode) {
                    case root.stretch:
                        return root.height
                    case root.fit:
                    case root.crop:
                        return width / root.aspectRatio
                }
            }

            clip: root.resizeMode === root.Crop

            //
            // User content area
            //

            Item {

                id: contentItem
                anchors.centerIn: parent
                width: parent.width
                height: parent.height
            }
        }
        SequentialAnimation {

            id: fastAnimation
            running: !fadeIn

            PauseAnimation {

                duration: 100
            }
            OpacityAnimator {

                target: container
                from: 0
                to: 1
                duration: 100
                easing.type: Easing.InCirc
            }
        }

        SequentialAnimation {

            id: slowAnimation
            running: fadeIn

            PauseAnimation {

                duration: 300
            }

            OpacityAnimator {

                target: container
                from: 0
                to: 1
                duration: 1500
                easing.type: Easing.InCirc
            }
        }
    }
    // Escape hatch: Press Escape to get your mouse back
    /*
    Shortcut {
        sequence: "Escape"
        onActivated: {
            console.log("ESCAPE")
            AppController.inputManager.captureMouse = false
        }
    }
     */
}