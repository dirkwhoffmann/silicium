import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Sulfur

DialogButtonBox {

    // Standard buttons are drawn as SuButtons; accepting ones are accented
    delegate: SuButton {
        accented: DialogButtonBox.buttonRole === DialogButtonBox.AcceptRole
    }

    alignment: Qt.AlignRight
    spacing: Style.mediumSpacing
    background: Rectangle {
        color: "transparent"
    }
    topPadding: 0
    bottomPadding: Style.largeSpacing
    rightPadding: Style.largeSpacing
}