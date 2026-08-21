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
            title: "ROMs"
            description: "For legal reasons, vAmiga does not include original Amiga ROMs. Choose to start with the AROS Kickstart replacement or DiagROM, and add your own ROMs later in Settings."
        }

        VSpacer {}

        RowLayout {

            Layout.alignment: Qt.AlignHCenter
            spacing: 20

            OnboardingOption {
                icon.source: Assets.iconUrl(Assets.RomAros)
                text: "Aros ROM"
                checked: controller.romAmiga == "aros"
                onClicked: controller.romAmiga = "aros"
            }

            OnboardingOption {
                icon.source: Assets.iconUrl(Assets.RomDiag)
                text: "DiagROM"
                checked: controller.romAmiga == "diag"
                onClicked: controller.romAmiga = "diag"
            }
        }

        VSpacer {}
    }
}