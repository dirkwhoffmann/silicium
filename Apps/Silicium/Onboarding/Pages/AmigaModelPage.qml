import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Silicium.Controllers
import Silicium.Theme

Item {

    id: root
    required property OnboardingController controller

    Component.onCompleted: {

        Palette.appearance = Palette.Appearance.Dark
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
            title: "Model"
            description: "Please select the Amiga model you want to emulate."
        }

        VSpacer {}

        RowLayout {

            Layout.alignment: Qt.AlignHCenter
            spacing: 20

            OnboardingOption {
                icon.source: Assets.iconUrl(Assets.AmigaMonitor)
                text: "Amiga 500"
                checked: controller.modelAmiga == "a500"
                onClicked: controller.modelAmiga = "a500"
            }

            OnboardingOption {
                icon.source: Assets.iconUrl(Assets.AmigaMonitor)
                text: "Amiga 1000"
                checked: controller.modelAmiga == "a1000"
                onClicked: controller.modelAmiga = "a1000"
            }
        }

        RowLayout {

            Layout.alignment: Qt.AlignHCenter
            spacing: 20

            OnboardingOption {
                icon.source: Assets.iconUrl(Assets.AmigaMonitor)
                text: "Amiga 2000"
                checked: controller.modelAmiga == "a2000"
                onClicked: controller.modelAmiga = "a2000"
            }

            OnboardingOption {
                icon.source: Assets.iconUrl(Assets.AmigaMonitor)
                text: "Amiga 1200"
                checked: controller.modelAmiga == "a1200"
                onClicked: controller.modelAmiga = "a1200"
            }
        }

        VSpacer {}
    }
}