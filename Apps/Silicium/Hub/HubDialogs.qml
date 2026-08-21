import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import Silicium.Controllers
import Silicium.Theme

Item {

    id: root

    required property HubController hc
    required property Window window

    // property alias error: errorDialog
    property alias openSvmFile: openSvmFileDialog
    property alias clone: cloneDialog
    property alias close: closeDialog

    SiUserDialog {

        id: alert
        parent: window.contentItem
        sound: true
    }

    FileDialog {

        id: openSvmFileDialog
        title: "Select an .svm File"
        nameFilters: ["Virtual machines (*.svm)"]

        onAccepted: {
            try {
                hc.addVM(selectedFile)
            } catch (e) {
                hc.showError(e.message)
            }
        }
    }

    FileDialog {

        id: cloneDialog

        property string uuid: ""

        title: "Save As"
        fileMode: FileDialog.SaveFile
        nameFilters: ["Virtual machines (*.svm)"]

        function openWithUUID(uuid) {

            cloneDialog.uuid = uuid
            cloneDialog.open()
        }

        onAccepted: {
            console.log("User selected file: " + selectedFile, " UUID: ", uuid)
            hc.cloneVM(uuid, selectedFile)
        }
    }

    SiUserDialog {

        id: closeDialog
        parent: window.contentItem
        readonly property string machines: hc.numOpen == 1 ? "machine" : "machines"
        titleText: "Quit"
        badgeSource: Assets.iconUrl(Assets.Help)
        bodyText: "You have " + hc.numOpen + " active virtual " + machines + " running. Do you really want to quit?"
        buttons: Dialog.Cancel | Dialog.Ok
        okLabel: "Quit"

        onAccepted: {
            window.closeApproved = true
            window.close()
        }
    }

    Connections {

        target: hc

        function onShowError(title, text) {

            console.log("onShowError: " + title + ", " + text)

            alert.titleText = title
            alert.bodyText = text
            alert.buttons = Dialog.Ok
            alert.acceptedCallback = function () {
                console.log("Error acknowledged")
            }
            alert.open()
        }

        // Ambiguous UUID dialog (shown when an existing UUIDs is detect)
        /*
        function onAmbiguousUUID(url) {

            alert.title = "Duplicate UUID detected"
            alert.text = "A virtual machine with the same UUID already exists in the database. If you proceed, a new UUID will be assigned to make the virtual machine unique."
            alert.buttons = Dialog.Cancel | Dialog.Ok
            alert.onButtonClickedCallback = function (label) {
                console.log("Label = ", label)
                if (label === "OK") {

                    // Add the virtual machine with a new UUID
                    hc.addVM(url, true)
                } else {
                    console.log("User cancelled")
                }
            }
            dialogs.error.open()
        }

         */

        /*
        function onShowNotification(message) {

            const component = Qt.createComponent("components/Toast.qml");
            if (component.status === Component.Ready) {
                // Create the toast as a child of the root window
                component.createObject(root, {"text": message});
            }
        }

         */
    }
}