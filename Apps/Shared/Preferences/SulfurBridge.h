// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#pragma once

#include "Assets.h"

/* Tells Sulfur, the UI toolkit, what the user has set up.
 *
 * Sulfur knows nothing about Silicium's preferences. This bridge copies the
 * few that concern the toolkit (color scheme, color theme, fonts, layout debug
 * aids) into SulfurSettings, once at startup and again whenever they change.
 */
class SulfurBridge {

public:

    // Call once, before the first QML window is created. The icon is the one of
    // the app; the message dialogs show it.
    static void install(Assets::Icon appIcon);
};
