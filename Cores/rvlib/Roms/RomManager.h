// -----------------------------------------------------------------------------
// This file is part of RetroVault
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#pragma once

namespace retro::vault {

/* Will eventually hold the single, shared Rom database that SiC64's
 * VCCore and SiAmiga's VACore each keep their own copy of today (both
 * called RomDatabase.h). Nothing lives here yet -- this class is a
 * placeholder to build against while that unification is worked out.
 */
class RomManager {

public:

    RomManager();
    ~RomManager();
};

}
