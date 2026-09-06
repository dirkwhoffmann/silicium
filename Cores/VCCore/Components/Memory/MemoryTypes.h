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
/// @file

#pragma once

#include "BasicTypes.h"

namespace vc64 {

//
// Enumerations
//

/// Memory type
enum class MemType : long
{
    NONE,         ///< Unmapped
    RAM,          ///< Ram
    CHAR,         ///< Character Rom
    KERNAL,       ///< Kernal Rom
    BASIC,        ///< Basic Rom
    IO,           ///< IO space
    CRTLO,        ///< Cartridge Rom (low bank)
    CRTHI,        ///< Cartridge Rom (high bank)
    PP,           ///< Processor port
};

struct MemoryTypeEnum : Reflectable<MemoryTypeEnum, MemType> {

    static constexpr long minVal = 1;
    static constexpr long maxVal = long(MemType::NONE);

    static const char *_key(MemType value)
    {
        switch (value) {

            case MemType::NONE:    return "NONE";
            case MemType::RAM:     return "RAM";
            case MemType::CHAR:    return "CHAR";
            case MemType::KERNAL:  return "KERNAL";
            case MemType::BASIC:   return "BASIC";
            case MemType::IO:      return "IO";
            case MemType::CRTLO:   return "CRTLO";
            case MemType::CRTHI:   return "CRTHI";
            case MemType::PP:      return "PP";
        }
        return "???";
    }
    
    static const char *help(MemType value)
    {
        return "";
    }
};

/// Ram startup pattern
enum class RamPattern : long
{
    VICE,       ///< Pattern used by the VICE emulator
    CCS,        ///< Pattern used by the CCS emulator
    ZEROES,     ///< Initialize with all zeroes
    ONES,       ///< Initialize with all ones
    RANDOM      ///< Initialize with pseudo-random values
};

struct RamPatternEnum : Reflectable<RamPatternEnum, RamPattern> {

    static constexpr long minVal = 0;
    static constexpr long maxVal = long(RamPattern::RANDOM);

    static const char *_key(RamPattern value)
    {
        switch (value) {

            case RamPattern::VICE:   return "VICE";
            case RamPattern::CCS:    return "CCS";
            case RamPattern::ZEROES: return "ZEROES";
            case RamPattern::ONES:   return "ONES";
            case RamPattern::RANDOM: return "RANDOM";
        }
        return "???";
    }
    
    static const char *help(RamPattern value)
    {
        return "";
    }
};

/* Shared by all cores. The AMIGA_ entries are meaningless to the C64 and the
 * C64 entries are meaningless to the Amiga, but both cores describe their Roms
 * with the same RomTraits struct, so both need to name the same enum. VACore's
 * copy in Media/Rom/RomFileTypes.h has to stay identical to this one.
 */
enum class RomType : long
{
    BASIC,
    CHAR,
    KERNAL,
    VC1541,
    AMIGA_KICKSTART,
    AMIGA_BOOT
};

struct RomTypeEnum : Reflectable<RomTypeEnum, RomType> {

    static constexpr long minVal = 0;
    static constexpr long maxVal = long(RomType::AMIGA_BOOT);

    static const char *_key(RomType value)
    {
        switch (value) {

            case RomType::BASIC:            return "BASIC";
            case RomType::CHAR:             return "CHAR";
            case RomType::KERNAL:           return "KERNAL";
            case RomType::VC1541:           return "VC1541";
            case RomType::AMIGA_KICKSTART:  return "AMIGA_KICKSTART";
            case RomType::AMIGA_BOOT:       return "AMIGA_BOOT";
        }
        return "???";
    }

    static const char *help(RomType value)
    {
        switch (value) {

            case RomType::BASIC:            return "Basic ROM";
            case RomType::CHAR:             return "Character ROM";
            case RomType::KERNAL:           return "Kernal ROM";
            case RomType::VC1541:           return "Floppy Drive ROM";
            case RomType::AMIGA_KICKSTART:  return "Kickstart ROM";
            case RomType::AMIGA_BOOT:       return "Boot ROM";
        }
        return "";
    }
};

/* Shared by all cores -- VACore's copy in Media/Rom/RomFileTypes.h has to stay
 * identical to this one. Only MEGA65 is C64-specific and only AROS, HYPERION,
 * DEMO and EMUTOS are Amiga-specific; the rest applies to both.
 *
 * UNKNOWN is the zero value, so a database entry that leaves 'vendor' out gets
 * it by default -- name the vendor explicitly wherever it is known.
 */
enum class RomVendor
{
    UNKNOWN,
    COMMODORE,
    MEGA65,
    AROS,
    HYPERION,
    DEMO,
    DIAG,
    EMUTOS,
    OTHER
};

struct RomVendorEnum : Reflectable<RomVendorEnum, RomVendor> {

    static constexpr long minVal = 0;
    static constexpr long maxVal = long(RomVendor::OTHER);

    static const char *_key(RomVendor value)
    {
        switch (value) {

            case RomVendor::UNKNOWN:    return "UNKNOWN";
            case RomVendor::COMMODORE:  return "COMMODORE";
            case RomVendor::MEGA65:     return "MEGA65";
            case RomVendor::AROS:       return "AROS";
            case RomVendor::HYPERION:   return "HYPERION";
            case RomVendor::DEMO:       return "DEMO";
            case RomVendor::DIAG:       return "DIAG";
            case RomVendor::EMUTOS:     return "EMUTOS";
            case RomVendor::OTHER:      return "OTHER";
        }
        return "???";
    }
    
    static const char *help(RomVendor value)
    {
        return "";
    }
};


//
// Structures
//

typedef struct
{
    RamPattern ramPattern;
    bool saveRoms;
    bool heatmap; 
}
MemConfig;

typedef struct
{
    bool exrom;
    bool game;
    bool loram;
    bool hiram;
    bool charen;
    u8   bankMap;

    MemType peekSrc[16];
    MemType vicPeekSrc[16];
}
MemInfo;

typedef struct
{
    isize reads[65536];
    isize writes[65536];
}
MemStats;

/* Shared by all cores -- VACore's copy in Media/Rom/RomFileTypes.h has to stay
 * identical to this one. Cores fill in what they can identify a Rom by: the
 * C64 matches on 'fnv', the Amiga on 'crc'.
 */
typedef struct {

    u64 fnv;
    u32 crc;

    const char *title;
    const char *revision;
    const char *released;
    const char *model;

    RomVendor vendor;
    RomType type;
    bool patched;
}
RomTraits;

}
