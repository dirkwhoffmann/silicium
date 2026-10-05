// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "SulfurBridge.h"
#include "Assets.h"
#include "Preferences.h"
#include "SulfurSettings.h"

void
SulfurBridge::install()
{
    auto &prefs = Preferences::instance();
    auto &sulfur = SulfurSettings::instance();

    // Copies everything over. The settings only announce what actually changed,
    // so there is no need to find out which preference it was.
    auto sync = [&prefs, &sulfur]() {

        sulfur.setAppearance(prefs.getAppearance());
        sulfur.setColorTheme(prefs.getColorTheme());
        sulfur.setFontTheme(prefs.getFontTheme());
        sulfur.setDataFontTheme(prefs.getDataFontTheme());
        sulfur.setConsoleFontTheme(prefs.getConsoleFontTheme());
        // (The developer getters are private; the property is not)
        sulfur.setDebug(prefs.property("qtDebug").toBool());
    };

    sync();

    // The pictures of the message dialogs never change
    auto *assets = Assets::instance();
    sulfur.setDialogIcon(assets->iconUrl(Assets::Icon::AppIcon));
    sulfur.setDialogBadge(assets->iconUrl(Assets::Icon::Biohazard));

    QObject::connect(&prefs, &Preferences::appearancePrefsChanged, &sulfur, sync);
    QObject::connect(&prefs, &Preferences::developerPrefsChanged, &sulfur, sync);
}
