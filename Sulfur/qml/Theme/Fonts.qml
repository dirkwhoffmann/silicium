// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

import QtQuick

pragma Singleton

QtObject {

    property FontLoader awesomeFont: FontLoader {
        source: "qrc:/qt/qml/Sulfur/fonts/Font-Awesome-7-Free-Solid-900.otf"
    }

    property FontLoader azeretFont: FontLoader {
        source: "qrc:/qt/qml/Sulfur/fonts/AzeretMono-VariableFont_wght.ttf"
    }

    property FontLoader bellefairFont: FontLoader {
        source: "qrc:/qt/qml/Sulfur/fonts/EBGaramond-VariableFont_wght.ttf"
    }

    property FontLoader c64Font: FontLoader {
        source: "qrc:/qt/qml/Sulfur/fonts/C64_Pro_Mono-STYLE.ttf"
    }

    property FontLoader dejaVuFont: FontLoader {
        source: "qrc:/qt/qml/Sulfur/fonts/DejaVuSans.ttf"
    }

    property FontLoader dejaVuMonoFont: FontLoader {
        source: "qrc:/qt/qml/Sulfur/fonts/DejaVuSansMono.ttf"
    }

    property FontLoader dejaVuMonoBoldFont: FontLoader {
        source: "qrc:/qt/qml/Sulfur/fonts/DejaVuSansMono-Bold.ttf"
    }

    property FontLoader dmmonoFont: FontLoader {
        source: "qrc:/qt/qml/Sulfur/fonts/DMMono-Regular.ttf"
    }

    property FontLoader garamondFont: FontLoader {
        source: "qrc:/qt/qml/Sulfur/fonts/EBGaramond-VariableFont_wght.ttf"
    }

    property FontLoader interFont: FontLoader {
        source: "qrc:/qt/qml/Sulfur/fonts/Inter-VariableFont_opsz,wght.ttf"
    }

    property FontLoader libertinusFont: FontLoader {
        source: "qrc:/qt/qml/Sulfur/fonts/LibertinusMono-Regular.ttf"
    }

    property FontLoader phosphorFont: FontLoader {
        source: "qrc:/qt/qml/Sulfur/fonts/Phosphor.ttf"
    }

    property FontLoader josefinFont: FontLoader {
        source: "qrc:/qt/qml/Sulfur/fonts/JosefinSans-VariableFont_wght.ttf"
    }

    property FontLoader sairaFont: FontLoader {
        source: "qrc:/qt/qml/Sulfur/fonts/SairaStencil-VariableFont_wdth,wght.ttf"
    }

    property FontLoader sofiaExtraFont: FontLoader {
        source: "qrc:/qt/qml/Sulfur/fonts/SofiaSansExtraCondensed-VariableFont_wght.ttf"
    }

    property FontLoader sofiaSemiFont: FontLoader {
        source: "qrc:/qt/qml/Sulfur/fonts/SofiaSansSemiCondensed-VariableFont_wght.ttf"
    }

    property FontLoader sonoFont: FontLoader {
        source: "qrc:/qt/qml/Sulfur/fonts/Sono-VariableFont_MONO,wght.ttf"
    }

    property FontLoader symbolsFont: FontLoader {
        source: "qrc:/qt/qml/Sulfur/fonts/MaterialSymbolsRounded.ttf"
    }

    readonly property string main: {

        switch (SulfurSettings.fontTheme) {

            case 0:  return Qt.application.font.family;
            case 1:  return interFont.name;
            case 2:  return sairaFont.name;
            default: return dejaVuFont.name;
        }
    }
    readonly property string mono: {

        switch (SulfurSettings.monoFontTheme) {

            case 0:  return dejaVuMonoFont.name;
            default: return libertinusFont.name;
        }
    }
    readonly property string c64: c64Font.name
    readonly property string showcaseTitleFont: sofiaExtraFont.name
    readonly property string showcaseSubtitleFont: sofiaSemiFont.name
    readonly property string showcaseMainFont: josefinFont.name
    readonly property string sono: sonoFont.name
    readonly property string awesome: awesomeFont.name
    readonly property string symbols: symbolsFont.name
    readonly property string phosphor: phosphorFont.name

    // Each Phosphor weight file implements its icons via OpenType ligatures,
    // and every weight but Regular requires the icon name to carry a
    // matching suffix (e.g. "gear-bold" instead of "gear") for the
    // ligature rule to match -- otherwise the font falls back to rendering
    // the literal letters. Derived from the loaded file's name so callers
    // (see SiSymbol.qml) don't need to know which weight is active.
    readonly property string phosphorSuffix: {
        const src = phosphorFont.source.toString();
        if (src.indexOf("Phosphor-Bold") !== -1) return "-bold";
        if (src.indexOf("Phosphor-Fill") !== -1) return "-fill";
        return "";
    }

    // Icon helpers: map an icon given by one of the three icon-font names
    // (Material symbol, Phosphor, Awesome; first non-empty wins) to the text
    // and font family needed to draw it.
    function iconText(sym, phos, awe) {
        return sym ? sym
            : phos ? phos + phosphorSuffix
            : awe ? awe : "";
    }
    function iconFamily(sym, phos, awe) {
        return sym ? symbols : phos ? phosphor : awesome;
    }

    // Font-specific compensation for large leadings
    readonly property int vgapFix: SulfurSettings.fontTheme == 2 ? -4 : 0 // DEPRECATED
}