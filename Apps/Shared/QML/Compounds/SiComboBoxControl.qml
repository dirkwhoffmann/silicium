import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Silicium.Theme

SiControl {

    id: root

    /* The model in full, hidden entries included.
     *
     * Not an alias to the inner combo box any more: that one is handed the
     * filtered list (see visibleModel), so Qt never learns the hidden entries
     * exist and keyboard navigation, mouse selection, popup sizing and
     * type-ahead all keep working with no special cases. Everything this
     * control exposes outwards -- currentIndex above all -- stays in terms of
     * the full model.
     */
    property var model: []

    /* Which entries the dropdown actually offers, as a predicate over an
     * entry's text and its index in the full model.
     *
     * The point is to let an index mean something to the caller other than a
     * position in a list. Where a combo box drives a core option whose values
     * aren't consecutive, pad the model with dummy entries at the values that
     * have no place in the list and hide them, and currentIndex stays the
     * option value:
     *
     *     model: ["7 MHz", "", "14 MHz", "", "28 MHz"]
     *     isItemVisible: (text) => text !== ""
     *
     * Filtering needs a model QML can index and count, which every caller
     * passing a JS array or a QVariantList has; anything else is passed to the
     * combo box untouched and the two index spaces coincide, exactly as they
     * did before this existed.
     */
    property var isItemVisible: function(itemText, index) { return true; }

    readonly property bool filtering: root.model !== undefined && root.model !== null &&
                                      root.model.length !== undefined

    // Indices of the full model that survive the filter, in order. Doubles as
    // the visible-index -> model-index map; indexOf() is the way back.
    readonly property var visibleIndexes: {

        if (!root.filtering) return []

        let result = []
        for (let i = 0; i < root.model.length; i++) {
            if (root.isItemVisible(control.itemText(root.model[i]), i)) result.push(i)
        }
        return result
    }

    readonly property var visibleModel:
        root.filtering ? root.visibleIndexes.map(i => root.model[i]) : root.model

    // Index translation. Both are the identity while nothing is filtered out.
    function toVisibleIndex(modelIndex) {
        return root.filtering ? root.visibleIndexes.indexOf(modelIndex) : modelIndex
    }
    function toModelIndex(visibleIndex) {
        if (!root.filtering) return visibleIndex
        return visibleIndex >= 0 && visibleIndex < root.visibleIndexes.length
                ? root.visibleIndexes[visibleIndex] : -1
    }

    /* The selected entry, as an index into the full model. -1 when the current
     * value belongs to a hidden entry, which leaves the field blank -- the same
     * thing an NSPopUpButton does when no item carries the tag it was asked to
     * select.
     */
    property int currentIndex: -1

    property alias currentText: control.currentText
    property alias displayText: control.displayText
    property alias delegate: control.delegate
    property alias readOnly: control.readOnly

    // Whether an offered entry can be picked. Indices are in the full model's
    // space, like every other index here.
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
     * new index back to a config option), and a handler declared at the use
     * site replaces the one declared here rather than running alongside it.
     */
    Connections {

        target: root
        function onCurrentIndexChanged() { root.syncControl() }
        function onVisibleIndexesChanged() { root.syncControl() }
    }

    /* Set while syncControl() is driving the inner combo box, so that the
     * write-back below can tell a selection the user made from the echo of one
     * this control just pushed down. Without it, a currentIndex that maps to a
     * hidden entry (a core value with no place in the list) comes straight back
     * up as the -1 the inner combo box was given, and a caller writing
     * currentIndex to its config option stores that -1.
     */
    property bool syncing: false

    function syncControl() {

        const index = root.toVisibleIndex(root.currentIndex)
        if (control.currentIndex === index) return

        root.syncing = true
        control.currentIndex = index
        root.syncing = false
    }

    /* Guards the inner combo box's initial currentIndex (0, before any caller's
     * binding has been evaluated) from being written back to root.currentIndex,
     * which would break that binding before it ever took effect.
     */
    property bool initialized: false

    control: [

        SiComboBox {

            id: control
            size: root.size
            enabled: root.enabled
            model: root.visibleModel
            isItemEnabled: function(itemText, index) {
                return root.isItemEnabled(itemText, root.toModelIndex(index))
            }
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
                const index = root.toModelIndex(currentIndex)
                if (root.currentIndex !== index) root.currentIndex = index
            }
            onActivated: (index) => root.activated(root.toModelIndex(index))

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
