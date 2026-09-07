import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Silicium.Theme

SiControl {

    id: root

    property alias model: control.model
    property alias currentIndex: control.currentIndex
    property alias currentText: control.currentText
    property alias delegate: control.delegate
    property alias isItemEnabled: control.isItemEnabled
    property alias readOnly: control.readOnly

    // Model roles: 'textRole' names the role to display, 'iconRole' optionally
    // names one holding a symbol to show beside it (see SiComboBox).
    property alias textRole: control.textRole
    property alias iconRole: control.iconRole

    /* Set false to keep the combo box out of the focus chain, e.g. so it can't
     * swallow the standard emulation keys. Not an alias to the inner
     * focusPolicy: SiControl is an Item, and Item carries a focusPolicy of its
     * own (Qt 6.7+), so an alias of that name would shadow a base member.
     */
    property bool focusable: true

    control: [

        SiComboBox {

            id: control
            size: root.size
            enabled: root.enabled
            // Qt.StrongFocus is what a ComboBox uses by default, so the
            // focusable default leaves existing callers untouched.
            focusPolicy: root.focusable ? Qt.StrongFocus : Qt.NoFocus
            Layout.fillWidth: hasFlexControl
            Layout.fillHeight: false
            Layout.preferredWidth: hasFlexControl ? control.implicitWidth : root.controlWidth
            Layout.preferredHeight: Size.controlHeight(root.size)
            Layout.minimumWidth: hasFlexControl ? 40 : root.controlWidth
            Layout.maximumWidth: hasFlexControl ? 9999 : root.controlWidth
            Layout.alignment: Qt.AlignVCenter
            onCurrentIndexChanged: root.currentIndexChanged()
        }
    ]
}