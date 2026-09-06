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

namespace vc64 {

#define BASIC       RomType::BASIC
#define KERNAL      RomType::KERNAL
#define CHAR        RomType::CHAR
#define VC1541      RomType::VC1541

#define COMMODORE   RomVendor::COMMODORE
#define MEGA65      RomVendor::MEGA65
#define OTHER       RomVendor::OTHER

static std::vector<RomTraits> roms = {

    //
    // Basic ROMs
    //

    {
        .fnv        = 0x20765FEA67A8762D,
        .title      = "Basic Rom",
        .revision   = "V2",
        .model      = "Generic C64",
        .vendor     = COMMODORE,
        .type       = BASIC
    },

    //
    // Character ROMs
    //

    {
        .fnv        = 0xACC576F7B332AC15,
        .title      = "Character Rom",
        .revision   = "V1",
        .model      = "Generic C64",
        .vendor     = COMMODORE,
        .type       = CHAR
    },{
        .fnv        = 0x3CA9D37AA3DE0969,
        .title      = "Character Rom",
        .revision   = "",
        .model      = "Swedish C64 (C2D007)",
        .vendor     = COMMODORE,
        .type       = CHAR
    },{
        .fnv        = 0x6E3827A65FFF116F,
        .title      = "Character Rom",
        .revision   = "",
        .model      = "Swedish C64",
        .vendor     = COMMODORE,
        .type       = CHAR
    },{
        .fnv        = 0x623CDF045B74B691,
        .title      = "Character Rom",
        .revision   = "",
        .model      = "Spanish C64C",
        .vendor     = COMMODORE,
        .type       = CHAR
    },{
        .fnv        = 0x79A236A3B3645231,
        .title      = "Character Rom",
        .revision   = "V3",
        .model      = "Danish C64",
        .vendor     = COMMODORE,
        .type       = CHAR
    },{
        .fnv        = 0x8550B7ECEEED00C5,
        .title      = "Character Rom",
        .revision   = "",
        .model      = "Japanese C64",
        .vendor     = COMMODORE,
        .type       = CHAR
    },{
        .fnv        = 0x2D5C504BBC4E5631,
        .title      = "Character Rom",
        .revision   = "",
        .model      = "Croatian C64",
        .vendor     = COMMODORE,
        .type       = CHAR
    },{
        .fnv        = 0x4D31ECBF4F967DC3,
        .title      = "Character Rom",
        .revision   = "",
        .model      = "M.E.G.A C64 OpenROM",
        .vendor     = MEGA65,
        .type       = CHAR
    },{
        .fnv        = 0x564e103e962682dd,
        .title      = "Character Rom",
        .revision   = "V2.3",
        .model      = "PXLfont",
        .vendor     = MEGA65,
        .type       = CHAR
    },{
        .fnv        = 0x1130C1CE287876DD,
        .title      = "Patched Character Rom",
        .revision   = "",
        .model      = "Atari 800 Font",
        .vendor     = OTHER,
        .type       = CHAR,
        .patched    = true
    },{
        .fnv        = 0x975546A5B6168FFD,
        .title      = "Patched Character Rom",
        .revision   = "",
        .model      = "MSX Font",
        .vendor     = OTHER,
        .type       = CHAR,
        .patched    = true
    },{
        .fnv        = 0x7C74107C9365F735,
        .title      = "Patched Character Rom",
        .revision   = "",
        .model      = "ZX Spectrum Font",
        .vendor     = OTHER,
        .type       = CHAR,
        .patched    = true
    },{
        .fnv        = 0xAFFE8B0EE2176CBD,
        .title      = "Patched Character Rom",
        .revision   = "",
        .model      = "Amstrad Font",
        .vendor     = OTHER,
        .type       = CHAR,
        .patched    = true
    },{
        .fnv        = 0xD14C5BE4FEE17705,
        .title      = "Patched Character Rom",
        .revision   = "",
        .model      = "Topaz Font",
        .vendor     = OTHER,
        .type       = CHAR,
        .patched    = true
    },{
        .fnv        = 0xA2C6A6E2C0477981,
        .title      = "Patched Character Rom",
        .revision   = "V2",
        .model      = "Topaz Font",
        .vendor     = OTHER,
        .type       = CHAR,
        .patched    = true
    },{
        .fnv        = 0x3BF55C821EE80365,
        .title      = "Patched Character Rom",
        .revision   = "V2 (broken)",
        .model      = "Topaz Font",
        .vendor     = OTHER,
        .type       = CHAR,
        .patched    = true
    },{
        .fnv        = 0x19F0DD3F3F9C4FE9,
        .title      = "Patched Character Rom",
        .revision   = "V2",
        .model      = "Topaz Font",
        .vendor     = OTHER,
        .type       = CHAR,
        .patched    = true
    },{
        .fnv        = 0xE527AD3E0DDE930D,
        .title      = "Patched Character Rom",
        .revision   = "",
        .model      = "Teletext Font",
        .vendor     = OTHER,
        .type       = CHAR,
        .patched    = true
    },

    //
    // Kernal ROMs
    //

    {
        .fnv        = 0xFB166E49AF709AB8,
        .title      = "Kernal Rom",
        .revision   = "V1",
        .model      = "Generic C64",
        .vendor     = COMMODORE,
        .type       = KERNAL
    },{
        .fnv        = 0x4232D81CCD24FAAE,
        .title      = "Kernal Rom",
        .revision   = "V2",
        .model      = "Generic C64",
        .vendor     = COMMODORE,
        .type       = KERNAL
    },{
        .fnv        = 0x4AF60EE54BEC9701,
        .title      = "Kernal Rom",
        .revision   = "V3",
        .model      = "Generic C64",
        .vendor     = COMMODORE,
        .type       = KERNAL
    },{
        .fnv        = 0x429EA22675CAB478,
        .title      = "Kernal Rom",
        .revision   = "V3",
        .model      = "Danish C64",
        .vendor     = COMMODORE,
        .type       = KERNAL
    },{
        .fnv        = 0xF695289f3EC48A38,
        .title      = "Kernal Rom",
        .revision   = "",
        .model      = "Japanese C64",
        .vendor     = COMMODORE,
        .type       = KERNAL
    },{
        .fnv        = 0x1124ECFFE9ED2FE9,
        .title      = "Kernal Rom",
        .revision   = "",
        .model      = "Croatian C64",
        .vendor     = COMMODORE,
        .type       = KERNAL
    },{
        .fnv        = 0x8C4548E2202CB366,
        .title      = "Kernal Rom",
        .revision   = "",
        .model      = "Generic SX64",
        .vendor     = COMMODORE,
        .type       = KERNAL
    },{
        .fnv        = 0x746EB1BC008B07E1,
        .title      = "Kernal Rom",
        .revision   = "",
        .model      = "Scandinavian SX64",
        .vendor     = COMMODORE,
        .type       = KERNAL
    },{
        .fnv        = 0x49A7074F1E6A896F,
        .title      = "Kernal Rom",
        .revision   = "V1",
        .model      = "PET64",
        .vendor     = COMMODORE,
        .type       = KERNAL
    },{
        .fnv        = 0xDE7F07008B787040,
        .title      = "Kernal Rom",
        .revision   = "",
        .model      = "JiffyDOS",
        .vendor     = OTHER,
        .type       = KERNAL,
        .patched    = true
    },{
        .fnv        = 0xA9D2AD1A4E5F782C,
        .title      = "Kernal Rom",
        .revision   = "",
        .model      = "JiffyDOS (SX64)",
        .vendor     = OTHER,
        .type       = KERNAL,
        .patched    = true
    },{
        .fnv        = 0x750617B8DE6DBA82,
        .title      = "Kernal Rom",
        .revision   = "V1",
        .model      = "Turbo Rom",
        .vendor     = OTHER,
        .type       = KERNAL,
        .patched    = true
    },{
        .fnv        = 0x7E0A124C3F192818,
        .title      = "Kernal Rom",
        .revision   = "V3.2+",
        .model      = "Datel Rom",
        .vendor     = OTHER,
        .type       = KERNAL,
        .patched    = true
    },{
        .fnv        = 0x211EAC45AB03A2CA,
        .title      = "Kernal Rom",
        .revision   = "V3",
        .model      = "Exos Rom",
        .vendor     = OTHER,
        .type       = KERNAL,
        .patched    = true
    },{
        .fnv        = 0xF2A39FF166D338AE,
        .title      = "Kernal Rom",
        .revision   = "V0.1",
        .model      = "Turbo Tape",
        .vendor     = OTHER,
        .type       = KERNAL
    },{
        .fnv        = 0xFD1EBD928024F8D5,
        .title      = "Patched Kernal Rom",
        .revision   = "V1.0",
        .model      = "Turbo 250",
        .vendor     = OTHER,
        .type       = KERNAL,
        .patched    = true
    },{
        .fnv        = 0x7202DEA530E1C172,
        .title      = "Patched Kernal Rom",
        .revision   = "V3",
        .model      = "64'er DOS",
        .vendor     = OTHER,
        .type       = KERNAL,
        .patched    = true
    },{
        .fnv        = 0x7E3AEFF7886684A2,
        .title      = "Patched Kernal Rom",
        .revision   = "",
        .model      = "SpeedDOS Plus",
        .vendor     = OTHER,
        .type       = KERNAL,
        .patched    = true
    },{
        .fnv        = 0x6E6190177D93D2BB,
        .title      = "Patched Kernal Rom",
        .revision   = "V2.7",
        .model      = "SpeedDOS Plus (TRIAD)",
        .vendor     = OTHER,
        .type       = KERNAL,
        .patched    = true
    },{
        .fnv        = 0x141A584872021C25,
        .title      = "Patched Kernal Rom",
        .revision   = "V1.1",
        .model      = "Dolphin DOS2 (donnchawp)",
        .vendor     = OTHER,
        .type       = KERNAL,
        .patched    = true
    },{
        .fnv        = 0xD135F409F4FA10F2,
        .title      = "Patched Kernal Rom",
        .revision   = "V1.0",
        .model      = "Dolphin DOS",
        .vendor     = OTHER,
        .type       = KERNAL,
        .patched    = true
    },{
        .fnv        = 0x32CAF94AAA196DB6,
        .title      = "Patched Kernal Rom",
        .revision   = "V2.0 Rev 1",
        .model      = "Dolphin DOS",
        .vendor     = OTHER,
        .type       = KERNAL,
        .patched    = true
    },{
        .fnv        = 0xAE3DEC803423CE60,
        .title      = "Patched Kernal Rom",
        .revision   = "V2.0 Rev 1 (M.A.)",
        .model      = "Dolphin DOS",
        .vendor     = OTHER,
        .type       = KERNAL,
        .patched    = true
    },{
        .fnv        = 0x4D3C32F9415972C3,
        .title      = "Patched Kernal Rom",
        .revision   = "V2.0 Rev 2",
        .model      = "Dolphin DOS",
        .vendor     = OTHER,
        .type       = KERNAL,
        .patched    = true
    },{
        .fnv        = 0xA5D930343EE32459,
        .title      = "Patched Kernal Rom",
        .revision   = "V2.0 Rev 3",
        .model      = "Dolphin DOS",
        .vendor     = OTHER,
        .type       = KERNAL,
        .patched    = true
    },{
        .fnv        = 0x7D34E8277F74A321,
        .title      = "Patched Kernal Rom",
        .revision   = "V2.0 (SilverDream)",
        .model      = "Dolphin DOS",
        .vendor     = OTHER,
        .type       = KERNAL,
        .patched    = true
    },{
        .fnv        = 0x877E38DA5DAFEC30,
        .title      = "Patched Kernal Rom",
        .revision   = "V3.0",
        .model      = "Dolphin DOS",
        .vendor     = OTHER,
        .type       = KERNAL,
        .patched    = true
    },{
        .fnv        = 0x2d7ca552f0332aef,
        .title      = "Patched Kernal Rom",
        .revision   = "2015",
        .model      = "JiffyDOS Dolphin Mod",
        .vendor     = OTHER,
        .type       = KERNAL,
        .patched    = true
    },{
        .fnv        = 0x7D6153CE2E12474F,
        .title      = "Patched Kernal Rom",
        .revision   = "V3.0",
        .model      = "Masterom (Norland)",
        .vendor     = OTHER,
        .type       = KERNAL,
        .patched    = true
    },{
        .fnv        = 0x99692773DB9D7DF4,
        .title      = "Patched Kernal Rom",
        .revision   = "V2.2",
        .model      = "SD2IEC",
        .vendor     = OTHER,
        .type       = KERNAL,
        .patched    = true
    },{
        .fnv        = 0x57C8266769C5B580,
        .title      = "Patched Kernal Rom",
        .revision   = "V1.3",
        .model      = "JaffyDOS",
        .vendor     = OTHER,
        .type       = KERNAL,
        .patched    = true
    },

    //
    // VC1541 ROM
    //

    // until here

    {
        .fnv        = 0x361A1EC48F04F5A4,
        .title      = "Floppy Drive Firmware",
        .revision   = "",
        .model      = "MOS 251968-01",
        .vendor     = COMMODORE,
        .type       = VC1541
    },{
        .fnv        = 0xB938E2DA07F4FE40,
        .title      = "Floppy Drive Firmware",
        .revision   = "",
        .model      = "MOS 251968-02",
        .vendor     = COMMODORE,
        .type       = VC1541
    },{
        .fnv        = 0x44BBA0EAC5898597,
        .title      = "Floppy Drive Firmware",
        .revision   = "",
        .model      = "MOS 251968-03",
        .vendor     = COMMODORE,
        .type       = VC1541
    },{
        .fnv        = 0xA1D36980A17C8756,
        .title      = "Floppy Drive Firmware",
        .revision   = "",
        .model      = "MOS 355640-01",
        .vendor     = COMMODORE,
        .type       = VC1541
    },{
        .fnv        = 0x47CBA55F16FB3E09,
        .title      = "Patched Drive Firmware",
        .revision   = "",
        .model      = "Relocation Patch",
        .vendor     = OTHER,
        .type       = VC1541,
        .patched    = true
    },{
        .fnv        = 0x8B2A523E29BED889,
        .title      = "Patched Drive Firmware",
        .revision   = "",
        .model      = "JiffyDOS Patch",
        .vendor     = OTHER,
        .type       = VC1541,
        .patched    = true
    },{
        .fnv        = 0xF7F4D931219DBB5D,
        .title      = "Patched Drive Firmware",
        .revision   = "V6.0",
        .model      = "JiffyDOS Patch",
        .vendor     = OTHER,
        .type       = VC1541,
        .patched    = true
    },{
        .fnv        = 0xB4027D6D9D61378A,
        .title      = "Patched Drive Firmware",
        .revision   = "V3",
        .model      = "64'er DOS",
        .vendor     = OTHER,
        .type       = VC1541,
        .patched    = true
    },{
        .fnv        = 0xC50EAFCBA50C4B63,
        .title      = "Patched Drive Firmware",
        .revision   = "",
        .model      = "SpeedDOS Plus",
        .vendor     = OTHER,
        .type       = VC1541,
        .patched    = true
    },{
        .fnv        = 0x92ADEBA1BCCD8D31,
        .title      = "Patched Drive Firmware",
        .revision   = "V2.7 (TRIAD)",
        .model      = "SpeedDOS Plus",
        .vendor     = OTHER,
        .type       = VC1541,
        .patched    = true
    },{
        .fnv        = 0x682B5C77E7535B4A,
        .title      = "Patched Drive Firmware",
        .revision   = "V1.1",
        .model      = "Dolphin DOS2 (donnchawp)",
        .vendor     = OTHER,
        .type       = VC1541,
        .patched    = true
    },{
        .fnv        = 0x28CD4E47A40C41CA,
        .title      = "Patched Drive Firmware",
        .revision   = "V2.0",
        .model      = "Dolphin DOS",
        .vendor     = OTHER,
        .type       = VC1541,
        .patched    = true
    },{
        .fnv        = 0x1C1DDD64E02CAD32,
        .title      = "Patched Drive Firmware",
        .revision   = "V2.0 (SilverDream)",
        .model      = "Dolphin DOS",
        .vendor     = OTHER,
        .type       = VC1541,
        .patched    = true
    },{
        .fnv        = 0x09D8FBAB61E59FF0,
        .title      = "Patched Drive Firmware",
        .revision   = "V3.0",
        .model      = "Dolphin DOS",
        .vendor     = OTHER,
        .type       = VC1541,
        .patched    = true
    },{
        .fnv        = 0xF684F72388EE5364,
        .title      = "Patched Drive Firmware",
        .revision   = "V3.0 (SilverDream)",
        .model      = "Dolphin DOS",
        .vendor     = OTHER,
        .type       = VC1541,
        .patched    = true
    }
};

#undef BASIC
#undef KERNAL
#undef CHAR
#undef VC1541

#undef COMMODORE
#undef MEGA65
#undef OTHER

}
