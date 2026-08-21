import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Silicium.Controllers
import Silicium.Theme

Item {

    id: root
    required property OnboardingController controller

    ColumnLayout {

        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        spacing: 20

        VSpacer {}

        OnboardingHeader {
            Layout.fillWidth: true
            title: "Getting Started"
            description: "We’ll have you ready in just a few steps. Start by selecting the computer model you want to emulate."
        }

        VSpacer {}

        RowLayout {

            Layout.alignment: Qt.AlignHCenter
            spacing: 20

            OnboardingOption {
                icon.source: Assets.iconUrl(Assets.C64Logo)
                text: "C64"
                checked: controller.platform == "c64"
                onClicked: controller.platform = "c64"
            }

            OnboardingOption {
                icon.source: Assets.iconUrl(Assets.AmigaLogo)
                text: "Amiga"
                checked: controller.platform == "amiga"
                onClicked: controller.platform = "amiga"
            }
        }

        VSpacer {}
    }
}