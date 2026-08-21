import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Silicium.Theme

ColumnLayout {

    id: root
    spacing: 6
    default property alias content: buttonRow.data

    readonly property color widgetColor: Palette.widget

    //
    // 3D Container
    //

    Rectangle {

        id: frame
        Layout.alignment: Qt.AlignHCenter
        implicitHeight: 26
        implicitWidth: buttonRow.implicitWidth // + 1 // 2
        radius: 5
        clip: true

        //
        // Border
        //

        border.color: Palette.widgetShadow
        border.width: 1

        //
        // Main Gradient
        //

        gradient: Gradient {

            GradientStop {
                position: 0.0
                color: root.widgetColor.lighter(1.4)
            }
            GradientStop {
                position: 1.0
                color: root.widgetColor.darker(1.05)
            }
        }

        //
        // Drop Shadow
        //

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#40000000"
            shadowBlur: 0.1
            shadowVerticalOffset: 1
            shadowHorizontalOffset: 1
        }

        //
        // Bevel
        //

        Rectangle {

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 1
            anchors.leftMargin: 4
            anchors.rightMargin: 4
            height: 1
            color: "#80ffffff"
        }

        //
        // Injected Buttons
        //

        RowLayout {

            id: buttonRow
            anchors.fill: parent
            anchors.topMargin: 0 // 1
            anchors.leftMargin: 0 // 1
            anchors.rightMargin: 0
            anchors.bottomMargin: 0
            spacing: 0
        }
    }
}
