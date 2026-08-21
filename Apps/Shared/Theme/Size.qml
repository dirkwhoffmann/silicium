import QtQuick
import Silicium.Theme

pragma Singleton

// Control-size scale, analogous to Cocoa's controlSize (regular / small / mini).
//
// A component's size is a per-instance property (see SiControl.size); this
// singleton only maps a chosen level to the concrete metrics every sized
// component should use, so the font/height/padding relationships live in one
// place. Regular deliberately maps to the app's existing defaults, so adding a
// size property to a component is a no-op until a smaller level is requested.
//
// Usage:
//
//   SiNumberViewControl { size: Size.small; ... }
//
QtObject {

    // Size levels (used as array indices into the metric tables below)
    readonly property int tiny: 0
    readonly property int small: 1
    readonly property int regular: 2
    readonly property int large: 3
    readonly property int huge: 4

    // Metrics keyed by level
    function fontSize(s)      { return [Style.tiny, Style.small, Style.regular, Style.large, Style.huge][s] }
    function controlHeight(s) { return [18, 20, 24, 30, 40][s] }
    function hPadding(s)      { return [4, 6, Style.mediumSpacing, 12, Style.largeSpacing][s] }
    function spacing(s)       { return [Style.smallSpacing, Style.smallSpacing, Style.smallSpacing, Style.smallSpacing, Style.smallSpacing][s] }

    // Square indicator size (e.g. a checkbox box)
    function indicatorSize(s) { return [12, 14, 16, 20, 24][s] }

    // Square icon glyph size (SiSymbol / SiSymbolButton). Regular deliberately
    // maps to the components' historical 20px default.
    function iconSize(s) { return [16, 18, 20, 24, 30][s] }
}
