import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Silicium.Theme

SiControl {

    id: root

    property alias model: control.model
    property alias currentIndex: control.currentIndex
    property alias currentText: control.currentText
    property alias displayText: control.displayText
    property alias delegate: control.delegate
    property alias textRole: control.textRole
    property alias placeholderText: control.placeholderText

    /* Rejects what the field must not hold, e.g.
     *
     *     validator: RegularExpressionValidator {
     *         regularExpression: /[0-9]{0,6}/
     *     }
     *
     * Applies to typing only, as a validator does: a keystroke that would
     * leave the text unacceptable never lands. It says nothing about what
     * the dropdown offers, and nothing about a value that is well-formed but
     * out of range -- that is still the caller's to judge.
     */
    property alias validator: control.validator
    readonly property alias acceptableInput: control.acceptableInput

    /* What the field shows, for a caller that has a value to show.
     *
     * Bind this, never editText. An editable ComboBox assigns its own
     * editText on every keystroke and on every selection from the list, and
     * a plain assignment destroys whatever binding the property carried --
     * so a caller binding editText loses that binding at the first
     * keystroke, and the field stops following its source. This property is
     * the way around it: nothing in here ever writes it, so a binding on it
     * survives everything the user does.
     *
     * The value flows one way, inwards. What the user types comes back out
     * through accepted()/editingFinished() and the editText below, and the
     * caller is expected to write it to wherever the binding reads from --
     * the same arrangement SiNumberInputControl has with valueEdited().
     *
     * Once the caller has had its say, the field is put back in step with
     * this property (see resync), which is what makes the source the last
     * word: an edit the caller accepted has changed it by then and the field
     * keeps the new text, while an edit the caller refused leaves it as it
     * was and the field returns to it. Leave the property unset and none of
     * that applies -- the field then answers to nobody but the user, which
     * is what a free-standing input wants.
     */
    property var text: undefined
    readonly property bool driven: root.text !== undefined

    /* What the field holds right now, including what the user is in the
     * middle of typing. Read it freely; assign it if a caller has to put the
     * field into a particular shape (SiAmHardDiskCreator normalizes "384"
     * to "384 MB" this way). Just never bind it -- see 'text' above.
     */
    property alias editText: control.editText

    // Forwarded from the inner ComboInput: fires only on user interaction
    // (unlike currentIndexChanged, which also fires on programmatic changes).
    signal activated(int index)
    signal accepted()
    signal editingFinished()

    /* Set false to keep the control out of the focus chain, e.g. so it can't
     * swallow the standard emulation keys. Not an alias to the inner
     * focusPolicy: SiControl is an Item, and Item carries a focusPolicy of its
     * own (Qt 6.7+), so an alias of that name would shadow a base member.
     */
    property bool focusable: true

    // Puts the field back on 'text'. A plain assignment to the inner combo
    // box, which owns no binding of the caller's -- the whole point of
    // keeping the two properties apart.
    function resync() {

        if (!root.driven) return
        if (control.editText !== root.text) control.editText = root.text
    }

    /* Scheduled rather than immediate: this runs from the inner control's
     * own handlers, which fire before the ones the call site declared, and
     * it is the call site that decides whether to take the edit. Qt.callLater
     * puts the resync after all of them, so it sees the answer.
     */
    function scheduleResync() {

        if (root.driven) Qt.callLater(root.resync)
    }

    /* Follows the source. A Connections object rather than an onTextChanged
     * handler on root: a call site declaring one of those would replace the
     * handler declared here rather than run alongside it (the same reason
     * SiComboBoxControl watches its own currentIndex this way).
     */
    Connections {

        target: root
        function onTextChanged() { root.resync() }
    }

    control: [

        SiComboInput {

            id: control
            size: root.size
            enabled: root.enabled
            // Qt.StrongFocus is what an editable ComboBox uses by default,
            // so the focusable default leaves existing callers untouched.
            focusPolicy: root.focusable ? Qt.StrongFocus : Qt.NoFocus
            Layout.fillWidth: hasFlexControl
            Layout.fillHeight: false
            Layout.preferredWidth: hasFlexControl ? control.implicitWidth : root.controlWidth
            Layout.preferredHeight: Size.controlHeight(root.size)
            Layout.minimumWidth: hasFlexControl ? 40 : root.controlWidth
            Layout.maximumWidth: hasFlexControl ? 9999 : root.controlWidth
            Layout.alignment: Qt.AlignVCenter
            onCurrentIndexChanged: root.currentIndexChanged()

            /* Forwarded from here rather than from handlers on root, which a
             * call site would replace by declaring its own -- these have to
             * run whatever the call site does, because each one also puts
             * the field back in step with 'text'.
             */
            onActivated: (index) => { root.activated(index); root.scheduleResync() }
            onAccepted: { root.accepted(); root.scheduleResync() }
            onEditingFinished: { root.editingFinished(); root.scheduleResync() }

            // Bindings are evaluated before completion runs, so 'text' holds
            // whatever the caller bound it to by the time this fires.
            Component.onCompleted: root.resync()
        }
    ]
}
