import QtQuick
import Silicium.Preferences

pragma Singleton

QtObject {

    //
    // Layout
    //

    readonly property real gridUnit: Qt.application.font.pixelSize

    readonly property real tinySpacing: 2
    readonly property real smallSpacing: 4
    readonly property real mediumSpacing: 8
    readonly property real largeSpacing: 16
    readonly property real hugeSpacing: 32

    readonly property real glyphCompensation: Preferences.fontTheme == 2 ? -4 : 0
    readonly property real zeroTextSpacing: glyphCompensation
    readonly property real tinyTextSpacing: tinySpacing + glyphCompensation
    readonly property real smallTextSpacing: smallSpacing + glyphCompensation
    readonly property real mediumTextSpacing: mediumSpacing + glyphCompensation
    readonly property real largeTextSpacing: largeSpacing + glyphCompensation


    //
    // Appearance
    //

    readonly property int radius: 4
    readonly property int borderRadius: radius // DEPRECATED

    //
    // Dimensions
    //

    readonly property int iconSmall: 16
    readonly property int iconMedium: 22
    readonly property int iconLarge: 30
    readonly property int iconHuge: 60
    readonly property int iconEpic: 96

    readonly property int toolbarHeight: 22
    readonly property int fontSize: 16

    //
    // Animations
    //

    readonly property int shortDuration: 150
    readonly property int longDuration: 250

    //
    // Typography
    //

    readonly property real _baseSize: Qt.application.font.pixelSize
    readonly property real heading: _baseSize * 2.0
    readonly property real huge: _baseSize * 1.5
    readonly property real large: _baseSize * 1.25
    readonly property real regular: _baseSize
    readonly property real small: _baseSize * 0.85
    readonly property real tiny: _baseSize * 0.75

    readonly property int weightBold: Font.Bold
    readonly property int weightMedium: Font.Medium
}
