import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Sulfur

Dialog {

    id: root

    property string okLabel: "OK"
    property string cancelLabel: "Cancel"

    /* Apply carries no accept role, so a dialog offering it stays open when
     * it is pressed. That is what a dialog which turns into a progress
     * display needs (see SiAmDropOverlay).
     */
    property string applyLabel: "Apply"
    property bool sound: false

    property alias buttons: buttonBox.standardButtons
    default property alias paneContent: container.data

    property var acceptedCallback: null

    /* Runs work in the background. The controller's run() takes a C++ lambda,
     * so it is the C++ side that calls it, e.g.
     *
     *     auto *c = dialog->property("controller").value<SuDialogController *>();
     *     c->run([] { ... });
     *
     * While a job is running, the buttons are disabled and the dialog cannot
     * be dismissed.
     */
    readonly property SuDialogController controller: SuDialogController { }
    readonly property bool busy: controller.busy

    signal taskFinished()
    signal taskFailed(string message)

    Connections {
        target: root.controller
        function onFinished() { root.taskFinished() }
        function onFailed(message) { root.taskFailed(message) }
    }

    onAccepted: {
        if (acceptedCallback) acceptedCallback()
    }

    onOkLabelChanged: {

        var btn = buttonBox.standardButton(Dialog.Ok)
        if (btn) btn.text = root.okLabel
    }

    onCancelLabelChanged: {

        var btn = buttonBox.standardButton(Dialog.Cancel)
        if (btn) btn.text = root.cancelLabel
    }

    onApplyLabelChanged: {

        var btn = buttonBox.standardButton(Dialog.Apply)
        if (btn) btn.text = root.applyLabel
    }

    // Enables or disables one of the standard buttons, e.g. to stop a job
    // being started twice while the first is still running.
    function setButtonEnabled(which, value) {

        var btn = buttonBox.standardButton(which)
        if (btn) btn.enabled = value
    }

    // Positioning & Sizing
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    width: 420
    height: implicitHeight

    implicitHeight:
        container.implicitHeight +
        topPadding +
        bottomPadding +
        (footer ? footer.implicitHeight : 0)

    padding: Style.largeSpacing
    modal: true
    closePolicy: busy ? Popup.NoAutoClose : Popup.CloseOnEscape
    header: Item { visible: false }

    //
    // Footer
    //

    footer: SuDialogButtonBox {

        id: buttonBox
        alignment: Qt.AlignRight
        enabled: !root.busy
        spacing: Style.mediumSpacing
        background: Rectangle { color: "transparent" }
        topPadding: 0
        bottomPadding: Style.largeSpacing
        rightPadding: Style.largeSpacing
    }

    //
    // Background
    //

    background: Rectangle {

        color: Palette.surface
        radius: Style.borderRadius
        border.color: Palette.surfaceBorder
        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            radius: 30; samples: 20
            color: "#60000000"; verticalOffset: 10
        }
    }

    //
    // Animations
    //

    enter: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 150 }
            NumberAnimation { property: "scale"; from: 0.9; to: 1.0; duration: 200; easing.type: Easing.OutBack }
        }
    }
    exit: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 150 }
            NumberAnimation { property: "scale"; from: 1.0; to: 0.9; duration: 150 }
        }
    }

    //
    // Sound effects
    //

    onOpened: {
        if (sound) {
            Sounds.playAlert()
        }
    }

    //
    // Custom item container
    //

    contentItem: ColumnLayout {

        id: container
        // implicitWidth: childrenRect.width
        // implicitHeight: childrenRect.height
    }
}
