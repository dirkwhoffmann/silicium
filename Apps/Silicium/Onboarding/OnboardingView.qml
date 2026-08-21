import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Silicium.Controllers
import Silicium.Theme

Pane {

    id: root

    required property OnboardingController onboardingController

    property alias oc: root.onboardingController

    Component.onCompleted: {

        Palette.theme = Palette.Theme.AppDefault
        Palette.appearance = Palette.Appearance.Dark
    }

    Connections {

        target: onboardingController

        function onPageChanged() {
            updateStack()
        }
    }

    //
    // Local components
    //

    component NavSymbolButton: RoundButton {

        id: root
        implicitWidth: Style.iconLarge
        implicitHeight: Style.iconLarge
        radius: Style.borderRadius

        font.pixelSize: 0.8 * implicitWidth
        font.family: Fonts.symbols

        readonly property color textColor: enabled ? Palette.primary : Palette.tertiary

        contentItem: SiText {

            text: root.text
            font: root.font
            color: root.textColor
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        background: Rectangle {

            color: root.pressed ? "#44ffffff" : "#11ffffff"
            radius: root.radius
            border.color: root.pressed ? "white" : root.enabled ? "#44ffffff" : "#11ffffff"
            border.width: 1
        }
    }

    component NavButton: RoundButton {

        id: root
        implicitWidth: Style.iconLarge
        implicitHeight: Style.iconLarge
        radius: Style.borderRadius

        icon.width: root.implicitWidth * 0.8
        icon.height: root.implicitHeight * 0.8
        icon.color: enabled ? Palette.primary : Palette.tertiary

        background: Rectangle {

            color: root.pressed ? "#44ffffff" : "#11ffffff"
            radius: root.radius
            border.color: root.pressed ? "white" : root.enabled ? "#44ffffff" : "#11ffffff"
            border.width: 1
        }
    }

    //
    // Background image
    //

    background: Rectangle { color: "transparent" }

    //
    // Main layout
    //

    ColumnLayout {

        anchors.fill: parent
        spacing: 10

        StackView {

            id: stack
            property bool forward: true
            property int duration: 400
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            Component.onCompleted: { updateStack() }

            // initialItem: welcomeComponent

            replaceEnter: Transition {
                NumberAnimation {
                    property: "x"
                    from: stack.forward ? stack.width : -stack.width
                    to: 0
                    duration: stack.duration
                    easing.type: Easing.OutCubic
                }
            }

            replaceExit: Transition {
                NumberAnimation {
                    property: "x"
                    from: 0
                    to: stack.forward ? -stack.width * 0.3 : stack.width * 0.3
                    duration: 0
                }
            }
        }

        Component {
            id: welcomeComponent
            WelcomePage {
                controller: oc
            }
        }

        Component {
            id: c64ModelComponent
            C64ModelPage {
                controller: oc
            }
        }

        Component {
            id: c64RomsComponent
            C64RomPage {
                controller: oc
            }
        }

        Component {
            id: amigaModelComponent
            AmigaModelPage {
                controller: oc
            }
        }

        Component {
            id: amigaRomsComponent
            AmigaRomPage {
                controller: oc
            }
        }

        Component {
            id: summaryComponent
            SummaryPage {
                controller: oc
            }
        }

        //
        // Navigation bar
        //

        RowLayout {

            Layout.fillWidth: true
            spacing: 10

            Item { Layout.fillWidth: true }

            NavSymbolButton {

                id: prevButton
                text: "chevron_left"
                enabled: oc.hasPrevPage

                onClicked: {

                    stack.forward = false
                    stack.duration = 400
                    oc.prev()
                }
            }

            PageIndicator {

                id: indicator
                count: oc.pageCount
                currentIndex: oc.index

                delegate: Rectangle {

                    implicitWidth: 8
                    implicitHeight: 8
                    radius: width / 2
                    color: "white"
                    opacity: index === indicator.currentIndex ? 1.0 : 0.4
                    Behavior on opacity {
                        NumberAnimation { duration: 250 }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            oc.index = index
                            stack.duration = 0
                        }
                    }
                }
            }

            NavSymbolButton {

                id: nextButton
                text: "chevron_right"
                enabled: oc.hasNextPage

                onClicked: {

                    stack.forward = true
                    stack.duration = 400
                    oc.next()
                }
            }

            Item { Layout.fillWidth: true }
        }
    }

    function updateStack() {

        if (oc.page == "welcome") stack.replace(welcomeComponent);
        if (oc.page == "c64Model") stack.replace(c64ModelComponent);
        if (oc.page == "c64Roms") stack.replace(c64RomsComponent);
        if (oc.page == "amigaModel") stack.replace(amigaModelComponent);
        if (oc.page == "amigaRoms") stack.replace(amigaRomsComponent);
        if (oc.page == "summary") stack.replace(summaryComponent);
    }
}