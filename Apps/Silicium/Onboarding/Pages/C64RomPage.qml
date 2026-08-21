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
            description: "For legal reasons, VirtualC64 does not include original Commodore ROMs. Choose to start with the M.E.G.A. Open ROMs, and add your own ROMs later in Settings."
        }

        VSpacer {}

        RowLayout {

            Layout.alignment: Qt.AlignHCenter
            spacing: 20

            OnboardingOption {
                icon.source: Assets.iconUrl(Assets.RomMega)
                text: "OpenROMs"
                checked: controller.romC64 == "mega"
                onClicked: controller.romC64 = "mega"
            }
        }

        VSpacer {}
    }
}