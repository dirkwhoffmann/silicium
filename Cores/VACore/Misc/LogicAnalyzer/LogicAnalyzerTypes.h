// This file is part of vAmiga
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#pragma once

#include "BusTypes.h"
#include "Constants.h"

namespace vamiga {

//
// Enumerations
//

enum class Probe : long
{
    NONE,
    MEMORY,
    IPL
};

struct ProbeEnum : Reflectable<ProbeEnum, Probe>
{
    static constexpr long minVal = 0;
    static constexpr long maxVal = long(Probe::IPL);
    
    static const char *_key(Probe value)
    {
        switch (value) {
                
            case Probe::NONE:            return "NONE";
            case Probe::MEMORY:          return "MEMORY";
            case Probe::IPL:             return "IPL";
        }
        return "???";
    }
    static const char *help(Probe value)
    {
        return "";
    }
};


//
// Structures
//

typedef struct
{
    // The logic analyzer channels
    Probe channel[4];
    
    // Probe address (in case of memory probing)
    u32 addr[4];
}
LogicAnalyzerConfig;

/* One recorded DMA cycle.
 *
 * The analyzer keeps a ring of these, so an entry has to say which cycle it
 * is: the ring is a flat sequence spanning several scanlines, and a reader
 * walking it has no other way to tell one line from the next. Storing the
 * position also removes any dependence on where the beam happens to be when
 * the ring is read -- an entry means the same thing a frame later.
 */
typedef struct
{
    // Where this cycle sat in the beam's travel
    isize vpos;
    isize hpos;

    /* The bus, as it stood once the cycle had finished.
     *
     * busOwner is what says whether the cycle holds anything: Agnus leaves
     * addrBus/dataBus untouched between lines, so they are stale wherever no
     * DMA took place and must be read only when an owner is present.
     */
    BusOwner busOwner;
    u32 addrBus;
    u16 dataBus;

    // One value per probe channel; -1 marks a channel that recorded nothing
    isize channel[4];
}
LogicAnalyzerTrace;

typedef struct
{

    const BusOwner *busOwner;
    const u32 *addrBus;
    const u16 *dataBus;
    const isize *channel[4];
}
LogicAnalyzerInfo;

}
