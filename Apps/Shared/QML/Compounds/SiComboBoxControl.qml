import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Silicium.Theme

SiControl {

    id: root

    property alias model: control.model
    property alias currentText: control.currentText
    property alias displayText: control.displayText
    property alias delegate: control.delegate
    property alias readOnly: control.readOnly

    /* The value each entry stands for, in model order, after the fashion of an
     * NSMenuItem's tag.
     *
     * Leave it empty and an entry's value is its position, which is what a
     * combo box does by default. Supply it and the two come apart, so that a
     * control driving an option whose values aren't consecutive can still list
     * only the entries worth offering:
     *
     *     model: ["7 MHz", "14 MHz", "28 MHz", "56 MHz"]
     *     tags:  [0, 2, 4, 8]
     *
     * Everything this control exposes outwards -- currentIndex, activated(),
     * the index handed to isItemEnabled -- is then a tag rather than a
     * position. Nothing inside the combo box itself changes, so keyboard
     * navigation, type-ahead and popup sizing are unaffected.
     */
    property var tags: []

    /* The selected entry, as a tag. -1 when no entry carries the current
     * value, which leaves the field blank -- the same thing an NSPopUpButton
     * does when asked to select a tag none of its items carries.
     */
    property int currentIndex: -1

    // Tag <-> position. Both are the identity while no tags are given.
    function tagAt(position) {
        return root.tags.length === 0 ? position
             : position >= 0 && position < root.tags.length ? root.tags[position] : -1
    }
    function positionOf(tag) {
        return root.tags.length === 0 ? tag : root.tags.indexOf(tag)
    }

    // Whether an entry can be picked. Not an alias to the inner combo box's
    // own predicate: that one is called with a position, and every index this
    // control hands out is a tag (see 'tags').
    property var isItemEnabled: function(itemText, index) { return true; }

    // Forwarded from the inner ComboBox: fires only on user interaction
    // (unlike currentIndexChanged, which also fires on programmatic changes).
    signal activated(int index)

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

    /* Keeps the inner combo box on whatever currentIndex says.
     *
     * A Connections object rather than an onCurrentIndexChanged handler on
     * root: call sites routinely declare one of those themselves (to write the
     * new value back to a config option), and a handler declared at the use
     * site replaces the one declared here rather than running alongside it.
     */
    Connections {

        target: root
        function onCurrentIndexChanged() { root.syncControl() }
        function onTagsChanged() { root.syncControl() }
    }

    /* Set while syncControl() is driving the inner combo box, so the write-back
     * below can tell a selection the user made from the echo of one this
     * control just pushed down. Without it a currentIndex carried by no entry
     * comes straight back up as the -1 the combo box was given, and a caller
     * writing currentIndex to its config option stores that -1.
     */
    property bool syncing: false
    property bool initialized: false

    function syncControl() {

        const position = root.positionOf(root.currentIndex)
        if (control.currentIndex === position) return

        root.syncing = true
        control.currentIndex = position
        root.syncing = false
    }

    control: [

        SiComboBox {

            id: control
            size: root.size
            enabled: root.enabled
            isItemEnabled: (itemText, position) => root.isItemEnabled(itemText, root.tagAt(position))
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

            onCurrentIndexChanged: {
                if (!root.initialized || root.syncing) return
                const tag = root.tagAt(currentIndex)
                if (root.currentIndex !== tag) root.currentIndex = tag
            }
            onActivated: (index) => root.activated(root.tagAt(index))

            /* Arms the write-back from here rather than from a
             * Component.onCompleted on root: a call site declaring one of
             * those replaces the component's own (DevicesPrefs.qml does), and
             * the write-back would then stay disabled for good. Nothing can
             * reach this one. Bindings are evaluated before completion runs,
             * so root.currentIndex already holds whatever the caller bound it
             * to by the time this fires.
             */
            Component.onCompleted: { root.initialized = true; root.syncControl() }
        }
    ]
}
