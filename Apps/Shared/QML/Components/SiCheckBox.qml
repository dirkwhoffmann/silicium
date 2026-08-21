import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Silicium.Theme

CheckBox {

    id: root

    property int size: Size.regular

    // When true, the checkbox ignores clicks -- a read-only status
    // indicator (e.g. the CPU flags, IRQ/NMI/RDY) rather than an editable
    // control. Unlike "enabled: false" (still available and unaffected,
    // for controls that are genuinely unavailable), this doesn't fade the
    // control out; it still renders as if enabled.
    property bool readOnly: false

    // Selects the indicator glyph: false (default) draws a checkmark when
    // checked and nothing when unchecked; true draws "1"/"0" instead,
    // always visible -- the style formerly provided by SiBitBox.
    property bool bitStyle: false

    Layout.alignment: Qt.AlignVCenter
    Layout.fillWidth: false
    Layout.preferredHeight: checkmark.implicitHeight
    Layout.preferredWidth: checkmark.implicitWidth

    topPadding: 0
    bottomPadding: 0
    leftPadding: 0
    rightPadding: 0
    spacing: 0

    // onClicked: root.clicked()

    // Swallows all mouse events while readOnly, before they reach the
    // control's own press/click handling underneath -- disabled (and so
    // fully transparent to hit-testing) otherwise, leaving normal
    // interaction untouched.
    MouseArea {

        anchors.fill: parent
        z: 1
        enabled: root.readOnly
        acceptedButtons: Qt.AllButtons
    }

    indicator: Rectangle {

        id: checkmark
        implicitWidth: Size.indicatorSize(size)
        implicitHeight: Size.indicatorSize(size)
        x: 0
        y: parent.height / 2 - height / 2
        radius: Style.radius

        color: checked ? Palette.accent : Palette.control
        border.color: checked ? Palette.accent : Palette.controlBorder
        opacity: enabled ? 1.0 : 0.4
        border.width: 1

        //
        // Checkmark / bit glyph
        //

        SiText {

            width: parent.width
            height: parent.height
            text: root.bitStyle ? (checked ? "1" : "0") : "check"
            font.family: root.bitStyle ? Fonts.mono : Fonts.symbols // awesome
            color: root.bitStyle ? (checked ? Palette.accentText : Palette.primary) : "white"
            font.pixelSize: root.bitStyle ? [8, 9, 11][size] : Size.indicatorSize(size) - 2
            font.bold: !root.bitStyle
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            visible: root.bitStyle || checked
        }
    }

    contentItem: Item {
    }
}