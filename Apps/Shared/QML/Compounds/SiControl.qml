import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Silicium.Preferences
import Silicium.Theme

// Layout:
//
//                ---                  ---------                  ---                   -------------
// <-- indent -->| l |<-- lspacing -->| control |<-- rspacing -->| r |<-- aspacing --> | attachments |
//                ---                  ---------                  ---                   -------------
//
// A RowLayout itself, rather than an Item wrapping an anchors.fill inner
// RowLayout -- that older shape derived implicitWidth/Height from a child
// that was, in turn, sized from this item's own width/height, which is a
// real (if usually latent) feedback loop once SiControl ends up nested
// inside other flexible layouts (see SiBox/ScrollView for a case where the
// equivalent pattern actually broke). Being a RowLayout directly gives a
// correct, non-circular implicit size for free, computed from the children
// below.

RowLayout {

    id: root

    // Control-size level (see Size), propagated to the labels and available
    // to the concrete control a subclass supplies (e.g. SiNumberViewControl).
    property int size: Size.regular

    property int indent: 0
    property alias l: leftText.text
    property int lwidth: 0
    property int lspacing: Size.spacing(size)
    property alias r: rightText.text
    property int rspacing: Size.spacing(size)
    property int rwidth: 0
    property int controlWidth: -1
    property int aspacing: Style.smallSpacing
    // Kept for subclasses/callers that want to tint their own background;
    // SiControl itself no longer draws one (see note below).
    property bool debug: Preferences.qtDebug

    // property alias help: helpButton
    property alias control: controlContainer.data
    default property alias accessories: accessoryContainer.data

    property bool hasFlexControl: controlWidth === -1
    readonly property bool hasAccessories: accessoryContainer.children.length > 0 // accessoryContainer.visible

    // signal helpClicked()

    spacing: 0

    // Only expand to fill a parent layout's extra space when this control
    // actually wants to flex (e.g. a combo box control that should stretch
    // to the available width); otherwise size to natural content, like a
    // plain RowLayout would.
    Layout.fillWidth: hasFlexControl
    Layout.fillHeight: false

    //
    // Indent
    //

    Item {

        Layout.preferredWidth: root.indent
        Layout.fillWidth: false
        visible: root.indent > 0
    }

    //
    // Left label
    //

    SiLabel {

        id: leftText
        size: root.size
        visible: text !== "" || lwidth > 0
        enabled: root.enabled
        text: ""
        horizontalAlignment: Text.AlignRight
        Layout.preferredWidth: root.lwidth === 0 ? leftText.implicitWidth : root.lwidth
        Layout.alignment: Qt.AlignVCenter
        rightPadding: root.lspacing

        DebugRect { }
    }

    //
    // Control element
    //

    RowLayout {

        id: controlContainer
        Layout.margins: 0
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        spacing: 0
    }

    //
    // Right label
    //

    SiLabel {

        id: rightText
        size: root.size
        visible: text !== ""
        enabled: root.enabled
        text: ""
        Layout.preferredWidth: root.rwidth === 0 ? rightText.implicitWidth : root.rwidth
        Layout.alignment: Qt.AlignVCenter
        leftPadding: root.rspacing

        DebugRect { }
    }

    //
    // Attachments
    //

    RowLayout {

        id: accessoryContainer
        visible: root.hasAccessories
        Layout.fillWidth: !hasFlexControl
        Layout.alignment: Qt.AlignVCenter
        Layout.leftMargin: root.aspacing
        spacing: Style.smallSpacing
        clip: true
    }
}
