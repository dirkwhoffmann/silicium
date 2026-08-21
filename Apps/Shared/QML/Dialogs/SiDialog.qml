import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Silicium.Theme

Dialog {

    id: root

    property string okLabel: "OK"
    property string cancelLabel: "Cancel"
    property bool sound: false

    property alias buttons: buttonBox.standardButtons
    default property alias paneContent: container.data

    property var acceptedCallback: null

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
    closePolicy: Popup.CloseOnEscape
    header: Item { visible: false }

    //
    // Footer
    //

    footer: SiDialogButtonBox {

        id: buttonBox
        alignment: Qt.AlignRight
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
        border.color: Palette.border
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
