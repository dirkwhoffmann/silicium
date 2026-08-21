import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Silicium.Theme

SiControl {

    id: root

    property alias text: control.text
    property alias placeholderText: control.placeholderText

    // Base used to parse the field's numeric value (10 or 16), unless the
    // text itself carries a "0x"/"$" hex prefix, which always wins -- there
    // is no standard decimal-equivalent prefix to check for.
    property int base: 10

    signal accepted()
    signal editingFinished()

    // The current text parsed as a number per 'base' (or forced to hex by
    // a "0x"/"$" prefix). NaN if the (prefix-stripped) text isn't a valid
    // number in the resulting base.
    readonly property int value: parseValue(text)

    function parseValue(str) {

        let s = str.trim()
        let b = root.base

        if (s.startsWith("0x") || s.startsWith("0X")) {
            s = s.slice(2)
            b = 16
        } else if (s.startsWith("$")) {
            s = s.slice(1)
            b = 16
        }

        return parseInt(s, b)
    }

    control: [

        TextField {

            id: control

            placeholderText: qsTr("Search")
            placeholderTextColor: Palette.disabled
            color: enabled ? Palette.primary : Palette.disabled
            font.family: Fonts.main
            font.pixelSize: Size.fontSize(root.size)
            selectByMouse: true

            Layout.fillWidth: hasFlexControl
            Layout.fillHeight: false
            Layout.preferredWidth: hasFlexControl ? control.implicitWidth : root.controlWidth
            Layout.preferredHeight: Size.controlHeight(root.size)
            Layout.minimumWidth: hasFlexControl ? 40 : root.controlWidth
            Layout.maximumWidth: hasFlexControl ? 9999 : root.controlWidth
            Layout.alignment: Qt.AlignVCenter

            // Room for the magnifier icon on the left
            leftPadding: height * 1.1
            rightPadding: Size.hPadding(root.size)

            background: Rectangle {

                radius: control.height / 2
                color: Palette.control
                border.width: 1
                border.color: control.activeFocus ? Palette.controlBorderSelected : Palette.controlBorder
            }

            SiSymbol {

                symbol: "search"
                // Sized to the field height -- set the glyph pixels directly.
                width: control.height - 6
                height: control.height - 6
                scale: 1.0
                color: Palette.disabled
                anchors.left: parent.left
                anchors.leftMargin: 6 // (control.height - size) / 2
                anchors.verticalCenter: parent.verticalCenter
            }

            onAccepted: root.accepted()
            onEditingFinished: root.editingFinished()
        }
    ]
}
