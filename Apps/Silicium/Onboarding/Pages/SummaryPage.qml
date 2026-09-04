import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtCore
import Silicium.Controllers
import Silicium.Preferences
import Silicium.Theme

Item {

    id: root
    required property OnboardingController controller
    readonly property string name: controller.name
    readonly property string svmName: name !== "" ? name + ".svm" : "Untitled.svm"

    Component.onCompleted: {

        Palette.appearance = Palette.Appearance.Dark
    }

    FileDialog {

        id: saveDialog

        title: "Select Destination"
        currentFolder: StandardPaths.writableLocation(StandardPaths.DocumentsLocation)
        fileMode: FileDialog.SaveFile

        onAccepted: {

            const url = controller.create(selectedFile)

            if (url.toString() !== "") {
                const uuid = HubController.addVM(url)
                HubController.select(uuid)
                HubController.open()
            }
        }
    }

    ColumnLayout {

        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        spacing: 20

        VSpacer {}

        OnboardingHeader {
            Layout.fillWidth: true
            image: controller.platformIcon
            title: "Almost Done!"
            description: "Name your virtual machine and click Save to create the machine as an .svm file on disk."
        }

        VSpacer {}

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: parent.width * 0.8
            Layout.fillWidth: false
            spacing: 10

            SiText {
                text: "Machine Name"
                color: "#bbffffff"
                font.pixelSize: Style.regular
                Layout.alignment: Qt.AlignLeft
            }

            // New RowLayout to put the field and button side-by-side
            RowLayout {
                Layout.fillWidth: true
                spacing: 15

                TextField {
                    id: nameField
                    // 1. Text field takes up all remaining horizontal space
                    Layout.fillWidth: true

                    placeholderText: "Untitled"
                    text: root.name
                    font.pixelSize: Style.large

                    // 2. Setting the text color
                    color: Palette.primary
                    placeholderTextColor: Palette.secondary

                    verticalAlignment: TextInput.AlignVCenter

                    background: Rectangle {
                        implicitHeight: 38
                        color: nameField.activeFocus ? "#44ffffff" : "#22ffffff"
                        radius: Style.borderRadius
                        border.color: nameField.activeFocus ? "white" : "#66ffffff"
                        border.width: nameField.activeFocus ? 2 : 1
                    }

                    onTextChanged: controller.name = text
                }

                OnboardingButton {

                    implicitWidth: 96
                    implicitHeight: nameField.implicitHeight

                    text: "Save..."
                    font.pixelSize: Style.large
                    onClicked: { saveDialog.open() }
                }
            }
        }

        VSpacer {}
    }
}