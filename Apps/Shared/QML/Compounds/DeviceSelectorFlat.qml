import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Silicium.Theme

AbstractButton {

    id: control

    required property var deviceModel
    property string port: ""

    /* Display only -- the caller binds this to whatever holds the real
     * selection, and this control never assigns to it. Writing to it here
     * would sever that binding (QML drops a declarative binding the moment
     * its property is assigned imperatively), leaving the button frozen on
     * the value it last set and blind to any later change made elsewhere --
     * such as the input manager unplugging this port because the device was
     * claimed by the other one. Report the click instead, and let whoever
     * owns the state decide what the selection becomes.
     */
    property int currentIndex: 0

    signal deviceSelected(int index)

    readonly property var currentDevice:
        deviceModel && currentIndex >= 0 && currentIndex < deviceModel.length
            ? deviceModel[currentIndex] : undefined

    readonly property bool active: menu.visible || control.pressed || control.hovered

    Layout.preferredWidth: 32
    Layout.fillHeight: true
    padding: 0
    topPadding: 0
    bottomPadding: 0

    onClicked: menu.open()

    contentItem: SiSymbol {

        symbol: control.currentDevice ? control.currentDevice.icon : ""
        scale: 0.7
        opacity: 0.8

        color: !control.enabled ? Palette.disabled
            : control.active ? Palette.accentText
                : Palette.primary
    }

    background: Rectangle {

        anchors.fill: parent
        anchors.margins: 0
        radius: 0

        color: control.enabled && control.active ? Palette.accent : "transparent"
    }

    SiToolTip {

        text: (!control.currentDevice || control.currentDevice.type === 0) ? port : control.currentDevice.name
    }

    SiMenu {

        id: menu
        y: control.height

        Instantiator {

            model: control.deviceModel

            delegate: SiMenuItem {

                action: Action {

                    text: modelData.name
                    icon.name: modelData.icon
                    checkable: true
                    checked: index === control.currentIndex

                    onTriggered: {

                        control.deviceSelected(index)

                        // Clicking a checkable action's item flips `checked`
                        // imperatively, which severs this binding. Restore it
                        // so the checkmark keeps tracking the real selection
                        // instead of freezing at whatever this one click set.
                        checked = Qt.binding(() => index === control.currentIndex)
                    }
                }
            }

            onObjectAdded: (index, object) => menu.insertItem(index, object)
            onObjectRemoved: (index, object) => menu.removeItem(object)
        }
    }
}
