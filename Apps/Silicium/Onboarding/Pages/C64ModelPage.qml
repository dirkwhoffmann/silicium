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
            description: "Please select the C64 model you want to emulate."
        }

        VSpacer {}

        RowLayout {

            Layout.alignment: Qt.AlignHCenter
            spacing: 20

            OnboardingOption {
                icon.source: Assets.iconUrl(Assets.C64Monitor)
                text: "Early C64"
                checked: controller.modelC64 == "early"
                onClicked: controller.modelC64 = "early"
            }

            OnboardingOption {
                icon.source: Assets.iconUrl(Assets.C64Monitor)
                text: "C64"
                checked: controller.modelC64 == "c64"
                onClicked: controller.modelC64 = "c64"
            }

            OnboardingOption {
                icon.source: Assets.iconUrl(Assets.C64Monitor)
                text: "C64 II"
                checked: controller.modelC64 == "c64ii"
                onClicked: controller.modelC64 = "c64ii"
            }
        }

        VSpacer {}
    }
}