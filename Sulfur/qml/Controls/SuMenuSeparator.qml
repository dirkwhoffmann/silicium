import QtQuick
import QtQuick.Controls
import Sulfur

// Styled replacement for MenuSeparator, matching the SuMenu family: a
// plain hairline instead of the platform-drawn groove.

MenuSeparator {

    id: root

    topPadding: Style.smallSpacing
    bottomPadding: Style.smallSpacing
    leftPadding: Style.mediumSpacing
    rightPadding: Style.mediumSpacing

    // Collapse to nothing when hidden -- otherwise the menu still reserves the
    // separator's height (padding + hairline), leaving a gap. Matches the
    // way SuMenuItem zeroes its height when invisible.
    implicitHeight: visible ? implicitContentHeight + topPadding + bottomPadding : 0

    contentItem: Rectangle {

        implicitHeight: 1
        color: Palette.surfaceBorder
        opacity: 0.5
    }
}
