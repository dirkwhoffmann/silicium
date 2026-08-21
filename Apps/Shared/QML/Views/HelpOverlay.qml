import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Silicium.Assets
import Silicium.Theme

Rectangle {

    id: root

    property bool shown: false
    property string markdown: ""
    property int duration: 500

    anchors.fill: parent
    visible: opacity > 0.01 // shown
    opacity: shown ? 1.0 : 0.0

    color: "#80000000"

    function showMarkdown(name)
    {
        markdown = Assets.markdown(name)
        shown = true
    }

    function hide()
    {
        shown = false
    }

    Behavior on opacity {
        NumberAnimation {
            duration: root.duration
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {

        scale: root.shown ? 1.0 : 0.0

        anchors.fill: parent
        anchors.margins: Style.largeSpacing

        color: Palette.surface
        border.color: Palette.border
        radius: 12

        Behavior on scale {
            NumberAnimation {
                duration: root.duration
                easing.type: Easing.OutCubic
            }
        }

        ScrollView {

            id: scrollView

            anchors.fill: parent
            anchors.margins: Style.largeSpacing

            ScrollBar.vertical.policy: ScrollBar.AlwaysOff
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            TextArea {
                width: scrollView.availableWidth

                readOnly: true
                background: null

                text: root.markdown
                textFormat: TextEdit.MarkdownText
                wrapMode: TextEdit.Wrap
            }
        }

        SiSymbolButton {

            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: Style.mediumSpacing
            symbol: "close"
            // Larger than any Size level -- keep the explicit pixel dimensions.
            implicitWidth: Style.iconLarge
            implicitHeight: Style.iconLarge
            onClicked: root.hide()
        }
    }
}
