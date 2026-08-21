// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

import QtQuick
import Silicium.Preferences

pragma Singleton

QtObject {

    property FontLoader awesomeFont: FontLoader {
        source: "qrc:/fonts/Font-Awesome-7-Free-Solid-900.otf"
    }

    property FontLoader azeretFont: FontLoader {
        source: "qrc:/fonts/AzeretMono-VariableFont_wght.ttf"
    }

    property FontLoader bellefairFont: FontLoader {
        source: "qrc:/fonts/EBGaramond-VariableFont_wght.ttf"
    }

    property FontLoader c64Font: FontLoader {
        source: "qrc:/fonts/C64_Pro_Mono-STYLE.ttf"
    }

    property FontLoader dejaVuFont: FontLoader {
        source: "qrc:/fonts/DejaVuSans.ttf"
    }

    property FontLoader dejaVuMonoFont: FontLoader {
        source: "qrc:/fonts/DejaVuSansMono.ttf"
    }

    property FontLoader dejaVuMonoBoldFont: FontLoader {
        source: "qrc:/fonts/DejaVuSansMono-Bold.ttf"
    }

    property FontLoader dmmonoFont: FontLoader {
        source: "qrc:/fonts/DMMono-Regular.ttf"
    }

    property FontLoader garamondFont: FontLoader {
        source: "qrc:/fonts/EBGaramond-VariableFont_wght.ttf"
    }

    property FontLoader interFont: FontLoader {
        source: "qrc:/fonts/Inter-VariableFont_opsz,wght.ttf"
    }

    property FontLoader libertinusFont: FontLoader {
        source: "qrc:/fonts/LibertinusMono-Regular.ttf"
    }

    property FontLoader phosphorFont: FontLoader {
        source: "qrc:/fonts/Phosphor.ttf"
    }

    property FontLoader josefinFont: FontLoader {
        source: "qrc:/fonts/JosefinSans-VariableFont_wght.ttf"
    }

    property FontLoader sairaFont: FontLoader {
        source: "qrc:/fonts/SairaStencil-VariableFont_wdth,wght.ttf"
    }

    property FontLoader sofiaExtraFont: FontLoader {
        source: "qrc:/fonts/SofiaSansExtraCondensed-VariableFont_wght.ttf"
    }

    property FontLoader sofiaSemiFont: FontLoader {
        source: "qrc:/fonts/SofiaSansSemiCondensed-VariableFont_wght.ttf"
    }

    property FontLoader sonoFont: FontLoader {
        source: "qrc:/fonts/Sono-VariableFont_MONO,wght.ttf"
    }

    property FontLoader symbolsFont: FontLoader {
        source: "qrc:/fonts/MaterialSymbolsRounded.ttf"
    }

    readonly property string main: {

        switch (Preferences.fontTheme) {

            case 0:  return Qt.application.font.family;
            case 1:  return interFont.name;
            case 2:  return sairaFont.name;
            default: return dejaVuFont.name;
        }
    }
    readonly property string mono: {

        switch (Preferences.monoFontTheme) {

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

    // Font-specific compensation for large leadings
    readonly property int vgapFix: Preferences.fontTheme == 2 ? -4 : 0 // DEPRECATED
}