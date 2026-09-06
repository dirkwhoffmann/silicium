// -----------------------------------------------------------------------------
// This file is part of RetroVault
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#pragma once

#include "Roms/RomTypes.h"
#include <vector>

namespace retro::vault {

/* The Rom database. Holds every Rom RetroVault can put a name to, across all
 * machines -- the C64 and Amiga tables used to live in a RomDatabase.h of their
 * own inside VCCore and VACore respectively.
 *
 * Roms are identified by hash, and which hash depends on the machine: C64 Roms
 * carry an FNV-1a, Amiga Roms a CRC32, and each entry leaves the other at zero.
 * That is why the two lookups are named rather than overloaded, and why both
 * refuse a zero key -- searching for one would otherwise match the entries of
 * the other machine wholesale.
 */
class RomManager {

public:

    RomManager();
    ~RomManager();

    // Provides access to the raw database
    static const std::vector<RomTraits> &database();

    // Looks up a Rom by hash (returns nullptr if the Rom is unknown)
    static const RomTraits *findByFnv(u64 fnv);
    static const RomTraits *findByCrc(u32 crc);
};

}
