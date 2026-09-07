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
    // Preferences.romLibrary), shown in the dropdown opened by the bookmarks
    // button; installRom(index) fires when one is picked.
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

            RowLayout {

                Layout.fillWidth: true
                layoutDirection: descColumn.alignRight ? Qt.RightToLeft : Qt.LeftToRight
                spacing: Style.smallSpacing

                // Close to the big Rom image -- to its right for a tile whose
                // image sits on the right (alignRight), to its left otherwise.
                SiSymbolButton {

                    id: libraryButton
                    phosphor: "bookmarks"
                    scale: 1.0
                    size: Size.regular
                    enabled: root.libraryRoms.length > 0
                    onClicked: libraryMenu.open()

                    DebugRect {}

                    SiMenu {

                        id: libraryMenu
                        y: libraryButton.height

                        // Dynamically generate one item per Rom the library
                        // scan found for this slot (see availableRoms in
                        // SiC64ConfigController).
                        Instantiator {

                            model: root.libraryRoms
                            delegate: SiMenuItem {
                                text: modelData
                                onTriggered: root.installRom(index)
                            }
                            onObjectAdded: (index, object) => libraryMenu.insertItem(index, object)
                            onObjectRemoved: (index, object) => libraryMenu.removeItem(object)
                        }
                    }
                }

                SiText {

                    text: root.title
                    font.pixelSize: Style.regular
                    font.bold: true
                    color: Palette.primary
                    Layout.fillWidth: true
                    horizontalAlignment: descColumn.alignRight ? Text.AlignRight : Text.AlignLeft
                }
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