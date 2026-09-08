import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Silicium.Theme

Item {

    id: root

    property int orientation: Qt.LeftToRight
    property alias imageSource: dropView.source
    property alias acceptUrls: dropView.acceptUrls

    property string title: ""
    property string subtitle: ""
    property string details: ""

    // Display names of the Roms available in the user's Rom library (see
    // Preferences.romLibrary), listed in the combo box below "None";
    // installRom(index) fires when one is picked.
    property var libraryRoms: []

    signal urlsDropped(var urls)
    signal deleteRom()
    signal installRom(int index)
    signal clicked()

    implicitWidth: 220
    implicitHeight: 120

    // Dim the whole tile -- image, labels and delete button -- when disabled.
    // Applied here rather than inside SiImageDropView so the two do not
    // compound into a double-dimmed image when this tile is switched off.
    opacity: enabled ? 1.0 : 0.4

    DebugRect { }

    RowLayout {

        anchors.fill: parent
        spacing: Style.mediumSpacing
        layoutDirection: root.orientation

        //
        // Image
        //

        SiImageDropView {

            id: dropView
            Layout.preferredWidth: 120
            Layout.preferredHeight: 120

            onUrlsDropped: (urls) => root.urlsDropped(urls)
            onClicked: root.clicked()
        }

        //
        // Description
        //

        ColumnLayout {

            id: descColumn

            Layout.topMargin: Style.mediumSpacing
            Layout.bottomMargin: Style.mediumSpacing
            Layout.fillWidth: true
            Layout.preferredHeight: dropView.preferredHeight ?? 0
            spacing: Style.smallTextSpacing
            clip: true

            readonly property bool alignRight: root.orientation === Qt.RightToLeft

            SiComboBoxControl {

                Layout.fillWidth: true

                // "None" removes the Rom (same as the delete button below);
                // the rest are the Roms found in the user's Rom library.
                model: ["None"].concat(root.libraryRoms)
                currentIndex: -1
                displayText: root.title

                onActivated: (index) => {
                    if (index === 0) root.deleteRom()
                    else root.installRom(index - 1)
                }

                DebugRect {}
            }

            SiText {

                text: root.subtitle
                font.pixelSize: Style.small
                color: Palette.secondary
                Layout.fillWidth: true
                horizontalAlignment: parent.alignRight ? Text.AlignRight : Text.AlignLeft
            }

            SiText {

                text: root.details
                font.pixelSize: Style.small
                color: Palette.tertiary
                Layout.fillWidth: true
                horizontalAlignment: parent.alignRight ? Text.AlignRight : Text.AlignLeft
            }

            VSpacer {}

            SiSymbolButton {

                symbol: "delete"
                scale: 1.0
                size: Size.regular
                Layout.alignment: parent.alignRight ? Qt.AlignRight : Qt.AlignLeft
                onClicked: deleteRom()

                DebugRect {}
            }
        }
    }
}