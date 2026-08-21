// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "EmulationKey.h"
#include <QKeySequence>

QString
EmulationKey::name() const
{
    // Check virtual keycodes first

    // macOS
    switch (pKey) {

        case 54: return "Right Cmd";
        case 55: return "Left Cmd";
        case 56: return "Left Shift";
        case 58: return "Left Option";
        case 59: return "Control";
        case 60: return "Right Shift";
        case 61: return "Right Option";
    }

    // Return the Qt generated default name
    return qKey >= 0 ? QKeySequence(qKey).toString() : "";
}