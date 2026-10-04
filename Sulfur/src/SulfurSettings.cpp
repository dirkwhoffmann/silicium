// -----------------------------------------------------------------------------
// This file is part of Sulfur, the Silicium UI toolkit
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "SulfurSettings.h"

SulfurSettings &
SulfurSettings::instance()
{
    static SulfurSettings settings;
    return settings;
}

SulfurSettings *
SulfurSettings::create(QQmlEngine *, QJSEngine *)
{
    // The instance outlives every engine, so the engine must not delete it
    QJSEngine::setObjectOwnership(&instance(), QJSEngine::CppOwnership);
    return &instance();
}
