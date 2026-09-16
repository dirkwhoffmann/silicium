// -----------------------------------------------------------------------------
// This file is part of vAmiga
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#pragma once

#include "BasicTypes.h"

namespace vamiga {

//
// Enumerations
//

/* Byte layout of a 32-bit host pixel (HOST_TEX_FORMAT). GpuColor is
 * templated on this (see Colors.h) rather than carrying a fixed internal
 * layout that gets translated at the edges: a GpuColor<F>'s rawValue is
 * always already packed exactly as a texel of format F, so constructing one
 * from raw channel values or reading r()/g()/b()/a() back out is correct by
 * construction, for whichever F it was made with. There is no longer a
 * separate "convert this GpuColor to/from the host's texel format" step
 * where the two could quietly disagree about which layout is in play.
 */
enum class TexelFormat : long
{
    ABGR,                       ///< AABBGGRR
    ARGB,                       ///< AARRGGBB
    RGBA                        ///< RRGGBBAA
};

struct TexelFormatEnum : Reflectable<TexelFormatEnum, TexelFormat> {

    static constexpr long minVal = 0;
    static constexpr long maxVal = long(TexelFormat::RGBA);

    static const char *_key(TexelFormat value)
    {
        switch (value) {

            case TexelFormat::ABGR:       return "ABGR";
            case TexelFormat::ARGB:       return "ARGB";
            case TexelFormat::RGBA:       return "RGBA";
        }
        return "???";
    }
    static const char *help(TexelFormat value)
    {
        switch (value) {

            case TexelFormat::ABGR:       return "32 bit AABBGGRR";
            case TexelFormat::ARGB:       return "32 bit AARRGGBB";
            case TexelFormat::RGBA:       return "32 bit RRGGBBAA";
        }
        return "???";
    }
};

}
