import QtQuick
import QtQuick.Layouts

Item {

    id: root

    property real size: -1
    property bool debug: SulfurSettings.debug

    Layout.fillWidth: size === -1
    Layout.fillHeight: true
    Layout.maximumHeight: 8
    Layout.preferredWidth: size >= 0 ? size : 0

    Rectangle {

        anchors.fill: parent
        color: "#6666ff"
        opacity: 0.3
        visible: root.debug
    }
}