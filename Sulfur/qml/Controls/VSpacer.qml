import QtQuick
import QtQuick.Layouts

Item {

    id: root

    property real size: -1
    property bool debug: SulfurSettings.debug

    Layout.fillHeight: size === -1
    Layout.fillWidth: true
    Layout.maximumWidth: 8
    Layout.preferredHeight: size >= 0 ? size : 0

    Rectangle {

        anchors.fill: parent
        color: "#6666ff"
        opacity: 0.3
        visible: root.debug
    }
}