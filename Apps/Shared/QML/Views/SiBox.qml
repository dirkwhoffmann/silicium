import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Silicium.Preferences
import Silicium.Theme

Item {

    id: root

    property alias title: header.text
    property alias font: header.font
    property color color: Palette.elevation
    property color borderColor: Palette.surface
    property alias spacing: container.spacing
    default property alias content: container.data

    // The Pane's own padding, i.e. the gap between the box's border and its
    // content -- exposed so a caller can zero it out (e.g. for content that
    // should cover the box edge-to-edge) without affecting every other box.
    property alias padding: pane.padding

    // Hides the title row so the Pane's border reaches the box's own top
    // edge -- useful when a caller wants to place its own accessory
    // straddling that border instead of a plain text title.
    // property bool showHeader: true

    // Control-size level (see Size), forwarded to any sized children placed
    // inside the box's content column.
    property int size: Size.regular

    implicitWidth: theColumn.implicitWidth
    implicitHeight: theColumn.implicitHeight

    ColumnLayout {

        id: theColumn
        anchors.fill: parent
        spacing: 0

        SiLabel {

            id: header
            visible: title !== ""
            leftPadding: Style.mediumSpacing
            font.pixelSize: Style.small
        }

        Pane {

            id: pane
            Layout.fillWidth: true
            Layout.fillHeight: true

            background: Rectangle {

                id: paneBg
                radius: Style.radius
                color: root.color
                border.width: 1
                border.color: root.borderColor
            }

            ColumnLayout {

                id: container
                anchors.fill: parent
            }
        }
    }
}
