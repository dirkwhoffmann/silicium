// -----------------------------------------------------------------------------
// This file is part of VirtualC64
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// This FILE is dual-licensed. You are free to choose between:
//
//     - The GNU General Public License v3 (or any later version)
//     - The Mozilla Public License v2
//
// SPDX-License-Identifier: GPL-3.0-or-later OR MPL-2.0
// -----------------------------------------------------------------------------

#pragma once

#include "BasicTypes.h"

namespace vc64 {

//
// Enumerations
//

/// Byte layout of a 32-bit host pixel (HOST_TEX_FORMAT)
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
