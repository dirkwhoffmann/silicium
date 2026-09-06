// -----------------------------------------------------------------------------
// This file is part of RetroVault
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#include "Roms/RomManager.h"
#include "utl/storage/Buffer.h"
#include <algorithm>

namespace retro::vault {

/* The database itself. Entries are grouped by machine, but the grouping is
 * presentational only -- nothing looks up a Rom by position, and the two
 * lookups below tell the halves apart by which hash an entry carries.
 */
static const std::vector<RomTraits> roms = {

    //
    // C64 Roms (identified by FNV-1a)
    //

    //
    // Basic ROMs
    //

    {
        .fnv        = 0x20765FEA67A8762D,
        .title      = "Basic Rom",
        .revision   = "V2",
        .model      = RomModel::GENERIC_C64,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::C64_BASIC
    },

    //
    // Character ROMs
    //

    {
        .fnv        = 0xACC576F7B332AC15,
        .title      = "Character Rom",
        .revision   = "V1",
        .model      = RomModel::GENERIC_C64,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::C64_CHAR
    },{
        .fnv        = 0x3CA9D37AA3DE0969,
        .title      = "Character Rom",
        .revision   = "Swedish (C2D007)",
        .model      = RomModel::GENERIC_C64,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::C64_CHAR
    },{
        .fnv        = 0x6E3827A65FFF116F,
        .title      = "Character Rom",
        .revision   = "Swedish",
        .model      = RomModel::GENERIC_C64,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::C64_CHAR
    },{
        .fnv        = 0x623CDF045B74B691,
        .title      = "Character Rom",
        .revision   = "Spanish",
        .model      = RomModel::GENERIC_C64,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::C64_CHAR
    },{
        .fnv        = 0x79A236A3B3645231,
        .title      = "Character Rom",
        .revision   = "Danish V3",
        .model      = RomModel::GENERIC_C64,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::C64_CHAR
    },{
        .fnv        = 0x8550B7ECEEED00C5,
        .title      = "Character Rom",
        .revision   = "Japanese",
        .model      = RomModel::GENERIC_C64,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::C64_CHAR
    },{
        .fnv        = 0x2D5C504BBC4E5631,
        .title      = "Character Rom",
        .revision   = "Croatian",
        .model      = RomModel::GENERIC_C64,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::C64_CHAR
    },{
        .fnv        = 0x4D31ECBF4F967DC3,
        .title      = "Character Rom",
        .revision   = "M.E.G.A C64 OpenROM",
        .model      = RomModel::GENERIC_C64,
        .vendor     = RomVendor::MEGA65,
        .type       = RomType::C64_CHAR
    },{
        .fnv        = 0x564e103e962682dd,
        .title      = "Character Rom",
        .revision   = "PXLfont V2.3",
        .model      = RomModel::GENERIC_C64,
        .vendor     = RomVendor::MEGA65,
        .type       = RomType::C64_CHAR
    },{
        .fnv        = 0x1130C1CE287876DD,
        .title      = "Patched Character Rom",
        .revision   = "Atari 800 Font",
        .model      = RomModel::GENERIC_C64,
        .vendor     = RomVendor::OTHER,
        .type       = RomType::C64_CHAR,
        .patched    = true
    },{
        .fnv        = 0x975546A5B6168FFD,
        .title      = "Patched Character Rom",
        .revision   = "MSX Font",
        .model      = RomModel::GENERIC_C64,
        .vendor     = RomVendor::OTHER,
        .type       = RomType::C64_CHAR,
        .patched    = true
    },{
        .fnv        = 0x7C74107C9365F735,
        .title      = "Patched Character Rom",
        .revision   = "ZX Spectrum Font",
        .model      = RomModel::GENERIC_C64,
        .vendor     = RomVendor::OTHER,
        .type       = RomType::C64_CHAR,
        .patched    = true
    },{
        .fnv        = 0xAFFE8B0EE2176CBD,
        .title      = "Patched Character Rom",
        .revision   = "Amstrad Font",
        .model      = RomModel::GENERIC_C64,
        .vendor     = RomVendor::OTHER,
        .type       = RomType::C64_CHAR,
        .patched    = true
    },{
        .fnv        = 0xD14C5BE4FEE17705,
        .title      = "Patched Character Rom",
        .revision   = "Topaz Font",
        .model      = RomModel::GENERIC_C64,
        .vendor     = RomVendor::OTHER,
        .type       = RomType::C64_CHAR,
        .patched    = true
    },{
        .fnv        = 0xA2C6A6E2C0477981,
        .title      = "Patched Character Rom",
        .revision   = "Topaz Font V2",
        .model      = RomModel::GENERIC_C64,
        .vendor     = RomVendor::OTHER,
        .type       = RomType::C64_CHAR,
        .patched    = true
    },{
        .fnv        = 0x3BF55C821EE80365,
        .title      = "Patched Character Rom",
        .revision   = "Topaz Font V2 (broken)",
        .model      = RomModel::GENERIC_C64,
        .vendor     = RomVendor::OTHER,
        .type       = RomType::C64_CHAR,
        .patched    = true
    },{
        .fnv        = 0x19F0DD3F3F9C4FE9,
        .title      = "Patched Character Rom",
        .revision   = "Topaz Font V2",
        .model      = RomModel::GENERIC_C64,
        .vendor     = RomVendor::OTHER,
        .type       = RomType::C64_CHAR,
        .patched    = true
    },{
        .fnv        = 0xE527AD3E0DDE930D,
        .title      = "Patched Character Rom",
        .revision   = "Teletext Font",
        .model      = RomModel::GENERIC_C64,
        .vendor     = RomVendor::OTHER,
        .type       = RomType::C64_CHAR,
        .patched    = true
    },

    //
    // Kernal ROMs
    //

    {
        .fnv        = 0xFB166E49AF709AB8,
        .title      = "Kernal Rom",
        .revision   = "V1",
        .model      = RomModel::GENERIC_C64,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::C64_KERNAL
    },{
        .fnv        = 0x4232D81CCD24FAAE,
        .title      = "Kernal Rom",
        .revision   = "V2",
        .model      = RomModel::GENERIC_C64,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::C64_KERNAL
    },{
        .fnv        = 0x4AF60EE54BEC9701,
        .title      = "Kernal Rom",
        .revision   = "V3",
        .model      = RomModel::GENERIC_C64,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::C64_KERNAL
    },{
        .fnv        = 0x429EA22675CAB478,
        .title      = "Kernal Rom",
        .revision   = "Danish V3",
        .model      = RomModel::GENERIC_C64,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::C64_KERNAL
    },{
        .fnv        = 0xF695289f3EC48A38,
        .title      = "Kernal Rom",
        .revision   = "Japanese",
        .model      = RomModel::GENERIC_C64,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::C64_KERNAL
    },{
        .fnv        = 0x1124ECFFE9ED2FE9,
        .title      = "Kernal Rom",
        .revision   = "Croatian",
        .model      = RomModel::GENERIC_C64,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::C64_KERNAL
    },{
        .fnv        = 0x8C4548E2202CB366,
        .title      = "Kernal Rom",
        .revision   = "",
        .model      = RomModel::SX64,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::C64_KERNAL
    },{
        .fnv        = 0x746EB1BC008B07E1,
        .title      = "Kernal Rom",
        .revision   = "Scandinavian",
        .model      = RomModel::SX64,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::C64_KERNAL
    },{
        .fnv        = 0x49A7074F1E6A896F,
        .title      = "Kernal Rom",
        .revision   = "V1",
        .model      = RomModel::PET64,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::C64_KERNAL
    },{
        .fnv        = 0xDE7F07008B787040,
        .title      = "Kernal Rom",
        .revision   = "JiffyDOS",
        .model      = RomModel::GENERIC_C64,
        .vendor     = RomVendor::OTHER,
        .type       = RomType::C64_KERNAL,
        .patched    = true
    },{
        .fnv        = 0xA9D2AD1A4E5F782C,
        .title      = "Kernal Rom",
        .revision   = "JiffyDOS",
        .model      = RomModel::SX64,
        .vendor     = RomVendor::OTHER,
        .type       = RomType::C64_KERNAL,
        .patched    = true
    },{
        .fnv        = 0x750617B8DE6DBA82,
        .title      = "Kernal Rom",
        .revision   = "Turbo Rom V1",
        .model      = RomModel::GENERIC_C64,
        .vendor     = RomVendor::OTHER,
        .type       = RomType::C64_KERNAL,
        .patched    = true
    },{
        .fnv        = 0x7E0A124C3F192818,
        .title      = "Kernal Rom",
        .revision   = "Datel Rom V3.2+",
        .model      = RomModel::GENERIC_C64,
        .vendor     = RomVendor::OTHER,
        .type       = RomType::C64_KERNAL,
        .patched    = true
    },{
        .fnv        = 0x211EAC45AB03A2CA,
        .title      = "Kernal Rom",
        .revision   = "Exos Rom V3",
        .model      = RomModel::GENERIC_C64,
        .vendor     = RomVendor::OTHER,
        .type       = RomType::C64_KERNAL,
        .patched    = true
    },{
        .fnv        = 0xF2A39FF166D338AE,
        .title      = "Kernal Rom",
        .revision   = "Turbo Tape V0.1",
        .model      = RomModel::GENERIC_C64,
        .vendor     = RomVendor::OTHER,
        .type       = RomType::C64_KERNAL
    },{
        .fnv        = 0xFD1EBD928024F8D5,
        .title      = "Patched Kernal Rom",
        .revision   = "Turbo 250 V1.0",
        .model      = RomModel::GENERIC_C64,
        .vendor     = RomVendor::OTHER,
        .type       = RomType::C64_KERNAL,
        .patched    = true
    },{
        .fnv        = 0x7202DEA530E1C172,
        .title      = "Patched Kernal Rom",
        .revision   = "64'er DOS V3",
        .model      = RomModel::GENERIC_C64,
        .vendor     = RomVendor::OTHER,
        .type       = RomType::C64_KERNAL,
        .patched    = true
    },{
        .fnv        = 0x7E3AEFF7886684A2,
        .title      = "Patched Kernal Rom",
        .revision   = "SpeedDOS Plus",
        .model      = RomModel::GENERIC_C64,
        .vendor     = RomVendor::OTHER,
        .type       = RomType::C64_KERNAL,
        .patched    = true
    },{
        .fnv        = 0x6E6190177D93D2BB,
        .title      = "Patched Kernal Rom",
        .revision   = "SpeedDOS Plus (TRIAD) V2.7",
        .model      = RomModel::GENERIC_C64,
        .vendor     = RomVendor::OTHER,
        .type       = RomType::C64_KERNAL,
        .patched    = true
    },{
        .fnv        = 0x141A584872021C25,
        .title      = "Patched Kernal Rom",
        .revision   = "Dolphin DOS2 (donnchawp) V1.1",
        .model      = RomModel::GENERIC_C64,
        .vendor     = RomVendor::OTHER,
        .type       = RomType::C64_KERNAL,
        .patched    = true
    },{
        .fnv        = 0xD135F409F4FA10F2,
        .title      = "Patched Kernal Rom",
        .revision   = "Dolphin DOS V1.0",
        .model      = RomModel::GENERIC_C64,
        .vendor     = RomVendor::OTHER,
        .type       = RomType::C64_KERNAL,
        .patched    = true
    },{
        .fnv        = 0x32CAF94AAA196DB6,
        .title      = "Patched Kernal Rom",
        .revision   = "Dolphin DOS V2.0 Rev 1",
        .model      = RomModel::GENERIC_C64,
        .vendor     = RomVendor::OTHER,
        .type       = RomType::C64_KERNAL,
        .patched    = true
    },{
        .fnv        = 0xAE3DEC803423CE60,
        .title      = "Patched Kernal Rom",
        .revision   = "Dolphin DOS V2.0 Rev 1 (M.A.)",
        .model      = RomModel::GENERIC_C64,
        .vendor     = RomVendor::OTHER,
        .type       = RomType::C64_KERNAL,
        .patched    = true
    },{
        .fnv        = 0x4D3C32F9415972C3,
        .title      = "Patched Kernal Rom",
        .revision   = "Dolphin DOS V2.0 Rev 2",
        .model      = RomModel::GENERIC_C64,
        .vendor     = RomVendor::OTHER,
        .type       = RomType::C64_KERNAL,
        .patched    = true
    },{
        .fnv        = 0xA5D930343EE32459,
        .title      = "Patched Kernal Rom",
        .revision   = "Dolphin DOS V2.0 Rev 3",
        .model      = RomModel::GENERIC_C64,
        .vendor     = RomVendor::OTHER,
        .type       = RomType::C64_KERNAL,
        .patched    = true
    },{
        .fnv        = 0x7D34E8277F74A321,
        .title      = "Patched Kernal Rom",
        .revision   = "Dolphin DOS V2.0 (SilverDream)",
        .model      = RomModel::GENERIC_C64,
        .vendor     = RomVendor::OTHER,
        .type       = RomType::C64_KERNAL,
        .patched    = true
    },{
        .fnv        = 0x877E38DA5DAFEC30,
        .title      = "Patched Kernal Rom",
        .revision   = "Dolphin DOS V3.0",
        .model      = RomModel::GENERIC_C64,
        .vendor     = RomVendor::OTHER,
        .type       = RomType::C64_KERNAL,
        .patched    = true
    },{
        .fnv        = 0x2d7ca552f0332aef,
        .title      = "Patched Kernal Rom",
        .revision   = "JiffyDOS Dolphin Mod 2015",
        .model      = RomModel::GENERIC_C64,
        .vendor     = RomVendor::OTHER,
        .type       = RomType::C64_KERNAL,
        .patched    = true
    },{
        .fnv        = 0x7D6153CE2E12474F,
        .title      = "Patched Kernal Rom",
        .revision   = "Masterom (Norland) V3.0",
        .model      = RomModel::GENERIC_C64,
        .vendor     = RomVendor::OTHER,
        .type       = RomType::C64_KERNAL,
        .patched    = true
    },{
        .fnv        = 0x99692773DB9D7DF4,
        .title      = "Patched Kernal Rom",
        .revision   = "SD2IEC V2.2",
        .model      = RomModel::GENERIC_C64,
        .vendor     = RomVendor::OTHER,
        .type       = RomType::C64_KERNAL,
        .patched    = true
    },{
        .fnv        = 0x57C8266769C5B580,
        .title      = "Patched Kernal Rom",
        .revision   = "JaffyDOS V1.3",
        .model      = RomModel::GENERIC_C64,
        .vendor     = RomVendor::OTHER,
        .type       = RomType::C64_KERNAL,
        .patched    = true
    },

    //
    // VC1541 ROM
    //

    // until here

    {
        .fnv        = 0x361A1EC48F04F5A4,
        .title      = "Floppy Drive Firmware",
        .revision   = "MOS 251968-01",
        .model      = RomModel::GENERIC_VC1541,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::C64_VC1541
    },{
        .fnv        = 0xB938E2DA07F4FE40,
        .title      = "Floppy Drive Firmware",
        .revision   = "MOS 251968-02",
        .model      = RomModel::GENERIC_VC1541,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::C64_VC1541
    },{
        .fnv        = 0x44BBA0EAC5898597,
        .title      = "Floppy Drive Firmware",
        .revision   = "MOS 251968-03",
        .model      = RomModel::GENERIC_VC1541,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::C64_VC1541
    },{
        .fnv        = 0xA1D36980A17C8756,
        .title      = "Floppy Drive Firmware",
        .revision   = "MOS 355640-01",
        .model      = RomModel::GENERIC_VC1541,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::C64_VC1541
    },{
        .fnv        = 0x47CBA55F16FB3E09,
        .title      = "Patched Drive Firmware",
        .revision   = "Relocation Patch",
        .model      = RomModel::GENERIC_VC1541,
        .vendor     = RomVendor::OTHER,
        .type       = RomType::C64_VC1541,
        .patched    = true
    },{
        .fnv        = 0x8B2A523E29BED889,
        .title      = "Patched Drive Firmware",
        .revision   = "JiffyDOS Patch",
        .model      = RomModel::GENERIC_VC1541,
        .vendor     = RomVendor::OTHER,
        .type       = RomType::C64_VC1541,
        .patched    = true
    },{
        .fnv        = 0xF7F4D931219DBB5D,
        .title      = "Patched Drive Firmware",
        .revision   = "JiffyDOS Patch V6.0",
        .model      = RomModel::GENERIC_VC1541,
        .vendor     = RomVendor::OTHER,
        .type       = RomType::C64_VC1541,
        .patched    = true
    },{
        .fnv        = 0xB4027D6D9D61378A,
        .title      = "Patched Drive Firmware",
        .revision   = "64'er DOS V3",
        .model      = RomModel::GENERIC_VC1541,
        .vendor     = RomVendor::OTHER,
        .type       = RomType::C64_VC1541,
        .patched    = true
    },{
        .fnv        = 0xC50EAFCBA50C4B63,
        .title      = "Patched Drive Firmware",
        .revision   = "SpeedDOS Plus",
        .model      = RomModel::GENERIC_VC1541,
        .vendor     = RomVendor::OTHER,
        .type       = RomType::C64_VC1541,
        .patched    = true
    },{
        .fnv        = 0x92ADEBA1BCCD8D31,
        .title      = "Patched Drive Firmware",
        .revision   = "SpeedDOS Plus V2.7 (TRIAD)",
        .model      = RomModel::GENERIC_VC1541,
        .vendor     = RomVendor::OTHER,
        .type       = RomType::C64_VC1541,
        .patched    = true
    },{
        .fnv        = 0x682B5C77E7535B4A,
        .title      = "Patched Drive Firmware",
        .revision   = "Dolphin DOS2 (donnchawp) V1.1",
        .model      = RomModel::GENERIC_VC1541,
        .vendor     = RomVendor::OTHER,
        .type       = RomType::C64_VC1541,
        .patched    = true
    },{
        .fnv        = 0x28CD4E47A40C41CA,
        .title      = "Patched Drive Firmware",
        .revision   = "Dolphin DOS V2.0",
        .model      = RomModel::GENERIC_VC1541,
        .vendor     = RomVendor::OTHER,
        .type       = RomType::C64_VC1541,
        .patched    = true
    },{
        .fnv        = 0x1C1DDD64E02CAD32,
        .title      = "Patched Drive Firmware",
        .revision   = "Dolphin DOS V2.0 (SilverDream)",
        .model      = RomModel::GENERIC_VC1541,
        .vendor     = RomVendor::OTHER,
        .type       = RomType::C64_VC1541,
        .patched    = true
    },{
        .fnv        = 0x09D8FBAB61E59FF0,
        .title      = "Patched Drive Firmware",
        .revision   = "Dolphin DOS V3.0",
        .model      = RomModel::GENERIC_VC1541,
        .vendor     = RomVendor::OTHER,
        .type       = RomType::C64_VC1541,
        .patched    = true
    },{
        .fnv        = 0xF684F72388EE5364,
        .title      = "Patched Drive Firmware",
        .revision   = "Dolphin DOS V3.0 (SilverDream)",
        .model      = RomModel::GENERIC_VC1541,
        .vendor     = RomVendor::OTHER,
        .type       = RomType::C64_VC1541,
        .patched    = true
    },

    //
    // Amiga Roms (identified by CRC32)
    //
    
    {
        .crc        = CRC32_BOOT_A1000_8K,
        .title      = "Amiga 1000 Boot Rom",
        .revision   = "8K",
        .released   = { 1985, 0 },
        .model      = RomModel::A1000,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::AMIGA_BOOT
    },{
        .crc        = CRC32_BOOT_A1000_64K,
        .title      = "Amiga 1000 Boot Rom",
        .revision   = "64KB",
        .released   = { 1985, 0 },
        .model      = RomModel::A1000,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::AMIGA_BOOT
    },{
        .crc        = CRC32_KICK07_27_003_BETA,
        .title      = "Kickstart 0.7 Beta",
        .revision   = "Rev 27.003 NTSC",
        .released   = { 1985, 7 },
        .model      = 0,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_KICK10_30_NTSC,
        .title      = "Kickstart 1.0",
        .revision   = "Rev 30.000 NTSC",
        .released   = { 1985, 9 },
        .model      = RomModel::A1000,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_KICK11_31_034_NTSC,
        .title      = "Kickstart 1.1",
        .revision   = "Rev 31.034 NTSC",
        .released   = { 1985, 11 },
        .model      = RomModel::A1000,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_KICK11_32_034_PAL,
        .title      = "Kickstart 1.1",
        .revision   = "Rev 32.034 PAL",
        .released   = { 1986, 2 },
        .model      = RomModel::A1000,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_KICK12_33_166,
        .title      = "Kickstart 1.2",
        .revision   = "Rev 33.166",
        .released   = { 1986, 9 },
        .model      = RomModel::A1000,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_KICK12_33_180,
        .title      = "Kickstart 1.2",
        .revision   = "Rev 33.180",
        .released   = { 1986, 10 },
        .model      = RomModel::A500 | RomModel::A1000 | RomModel::A2000,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_KICK12_33_180_MRAS,
        .title      = "Kickstart 1.2",
        .revision   = "Rev 33.180 (MRAS patch)",
        .released   = { 2022, 0 },
        .model      = RomModel::A500 | RomModel::A1000 | RomModel::A2000,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_KICK12_33_180_G11R,
        .title      = "Kickstart 1.2",
        .revision   = "Rev 33.180 (Guardian patch)",
        .released   = { 1988, 0 },
        .model      = 0,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::AMIGA_KICKSTART,
        .patched    = true
    },{
        .crc        = CRC32_KICK121_34_004,
        .title      = "Kickstart 1.2",
        .revision   = "Rev 34.004",
        .released   = { 1986, 10 },
        .model      = 0,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_KICK13_34_005_A500,
        .title      = "Kickstart 1.3",
        .revision   = "Rev 34.005",
        .released   = { 1987, 12 },
        .model      = RomModel::A500 | RomModel::A1000 | RomModel::A2000 | RomModel::CDTV,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_KICK13_34_005_A3000,
        .title      = "Kickstart 1.3",
        .revision   = "Rev 34.005",
        .released   = { 1987, 12 },
        .model      = RomModel::A3000,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_KICK13_34_005_G12R,
        .title      = "Kickstart 1.3",
        .revision   = "Rev 34.005 (Guardian patch)",
        .released   = { 1988, 0 },
        .model      = 0,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::AMIGA_KICKSTART,
        .patched    = true
    },{
        .crc        = CRC32_KICK14_36_015,
        .title      = "Kickstart 1.4 Alpha 15",
        .revision   = "Rev 36.015",
        .released   = { 1989, 5 },
        .model      = RomModel::A2000,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_KICK14_36_002,
        .title      = "Kickstart 1.4 Alpha 18",
        .revision   = "Rev 36.020",
        .released   = { 1989, 12 },
        .model      = RomModel::A3000,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_KICK20_36_028,
        .title      = "Kickstart 2.0",
        .revision   = "Rev 36.028",
        .released   = { 1990, 3 },
        .model      = 0,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_KICK201_36_143,
        .title      = "Kickstart 2.01",
        .revision   = "Rev 36.143",
        .released   = { 1990, 8 },
        .model      = RomModel::A3000,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_KICK202_36_207_A3000,
        .title      = "Kickstart 2.02",
        .revision   = "Rev 36.207",
        .released   = { 1990, 10 },
        .model      = RomModel::A3000,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_KICK204_37_175_A500,
        .title      = "Kickstart 2.04",
        .revision   = "Rev 37.175",
        .released   = { 1991, 5 },
        .model      = RomModel::A500,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_KICK204_37_175_A3000,
        .title      = "Kickstart 2.04",
        .revision   = "Rev 37.175",
        .released   = { 1991, 5 },
        .model      = RomModel::A3000,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_KICK20x_37_210_A600,
        .title      = "Kickstart 2.0?",
        .revision   = "Rev 37.210",
        .released   = { 1991, 11 },
        .model      = RomModel::A600,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_KICK205_37_299_A600,
        .title      = "Kickstart 2.05",
        .revision   = "Rev 37.299",
        .released   = { 1991, 11 },
        .model      = RomModel::A600,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_KICK205_37_300_A600HD,
        .title      = "Kickstart 2.05",
        .revision   = "Rev 37.300",
        .released   = { 1991, 11 },
        .model      = 0,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_KICK205_37_350_A600HD,
        .title      = "Kickstart 2.05",
        .revision   = "Rev 37.350",
        .released   = { 1992, 4 },
        .model      = RomModel::A600HD,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_KICK30_39_106_A1200,
        .title      = "Kickstart 3.0",
        .revision   = "Rev 39.106",
        .released   = { 1992, 9 },
        .model      = RomModel::A1200,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_KICK30_39_106_A4000,
        .title      = "Kickstart 3.0",
        .revision   = "Rev 39.106",
        .released   = { 1992, 9 },
        .model      = RomModel::A4000,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_KICK31_40_055_A3000,
        .title      = "Kickstart 3.1",
        .revision   = "Rev 40.055",
        .released   = { 1993, 5 },
        .model      = RomModel::A3000,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_KICK31_40_060_CD32,
        .title      = "Kickstart 3.1",
        .revision   = "Rev 40.060",
        .released   = { 1993, 5 },
        .model      = RomModel::CD32,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_KICK31_40_063_A500,
        .title      = "Kickstart 3.1",
        .revision   = "Rev 40.063",
        .released   = { 1993, 7 },
        .model      = RomModel::A500 | RomModel::A600 | RomModel::A2000,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_KICK31_40_063_A500_R,
        .title      = "Kickstart 3.1",
        .revision   = "Rev 40.063 (ReKick image)",
        .released   = { 0, 0 },
        .model      = RomModel::A500 | RomModel::A600 | RomModel::A2000,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_KICK31_40_068_A1200,
        .title      = "Kickstart 3.1",
        .revision   = "Rev 40.068",
        .released   = { 1993, 12 },
        .model      = RomModel::A1200,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_KICK31_40_068_A3000,
        .title      = "Kickstart 3.1",
        .revision   = "Rev 40.068",
        .released   = { 1993, 12 },
        .model      = RomModel::A3000,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_KICK31_40_068_A4000,
        .title      = "Kickstart 3.1",
        .revision   = "Rev 40.068",
        .released   = { 1993, 12 },
        .model      = RomModel::A4000,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_KICK31_40_069_A1200,
        .title      = "Kickstart 3.1",
        .revision   = "Rev 40.069 Beta",
        .released   = { 1993, 12 },
        .model      = RomModel::A1200,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_KICK31_40_070_A4000T,
        .title      = "Kickstart 3.1",
        .revision   = "Rev 40.070",
        .released   = { 1994, 2 },
        .model      = RomModel::A4000T,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_KICK35_40_071_A4000,
        .title      = "Fake Kickstart 3.5",
        .revision   = "Rev 40.071",
        .released   = { 0, 0 },
        .model      = RomModel::A4000,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::AMIGA_KICKSTART,
        .patched    = true
    },{
        .crc        = CRC32_CDTV_EXT_ROM_1_0,
        .title      = "CDTV Extended ROM",
        .revision   = "Rev 1.0",
        .released   = { 1991, 3 },
        .model      = RomModel::CDTV,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::AMIGA_EXTROM
    },{
        .crc        = CRC32_CDTV_EXT_ROM_2_3,
        .title      = "CDTV Extended ROM",
        .revision   = "Rev 2.3",
        .released   = { 1992, 0 },
        .model      = RomModel::CDTV,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::AMIGA_EXTROM
    },{
        .crc        = CRC32_CDTV_EXT_ROM_2_7,
        .title      = "CDTV Extended ROM",
        .revision   = "Rev 2.7",
        .released   = { 1992, 0 },
        .model      = RomModel::CDTV,
        .vendor     = RomVendor::COMMODORE,
        .type       = RomType::AMIGA_EXTROM
    },{
        .crc        = CRC32_HYP314_46_143_A500,
        .title      = "Kickstart 3.1.4 (Hyperion)",
        .revision   = "Rev 46.143",
        .released   = { 2018, 9 },
        .model      = RomModel::A500 | RomModel::A600 | RomModel::A1000,
        .vendor     = RomVendor::HYPERION,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_HYP314_46_143_A1200,
        .title      = "Kickstart 3.1.4 (Hyperion)",
        .revision   = "Rev 46.143",
        .released   = { 2018, 9 },
        .model      = RomModel::A1200,
        .vendor     = RomVendor::HYPERION,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_HYP314_46_143_A2000,
        .title      = "Kickstart 3.1.4 (Hyperion)",
        .revision   = "Rev 46.143",
        .released   = { 2018, 9 },
        .model      = RomModel::A2000,
        .vendor     = RomVendor::HYPERION,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_HYP314_46_143_A3000,
        .title      = "Kickstart 3.1.4 (Hyperion)",
        .revision   = "Rev 46.143",
        .released   = { 2018, 9 },
        .model      = RomModel::A3000,
        .vendor     = RomVendor::HYPERION,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_HYP314_46_143_A4000,
        .title      = "Kickstart 3.1.4 (Hyperion)",
        .revision   = "Rev 46.143",
        .released   = { 2018, 9 },
        .model      = RomModel::A4000,
        .vendor     = RomVendor::HYPERION,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_HYP314_46_143_A4000T,
        .title      = "Kickstart 3.1.4 (Hyperion)",
        .revision   = "Rev 46.143",
        .released   = { 2021, 5 },
        .model      = RomModel::A4000T,
        .vendor     = RomVendor::HYPERION,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_HYP320_47_96_A500,
        .title      = "Kickstart 3.2 (Hyperion)",
        .revision   = "Rev 47.96",
        .released   = { 2021, 5 },
        .model      = RomModel::A500 | RomModel::A600 | RomModel::A1000 | RomModel::A2000 | RomModel::CDTV,
        .vendor     = RomVendor::HYPERION,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_HYP320_47_96_A1200,
        .title      = "Kickstart 3.2 (Hyperion)",
        .revision   = "Rev 47.96",
        .released   = { 2021, 5 },
        .model      = RomModel::A1200,
        .vendor     = RomVendor::HYPERION,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_HYP320_47_96_A3000,
        .title      = "Kickstart 3.2 (Hyperion)",
        .revision   = "Rev 47.96",
        .released   = { 2021, 5 },
        .model      = RomModel::A3000,
        .vendor     = RomVendor::HYPERION,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_HYP320_47_96_A4000,
        .title      = "Kickstart 3.2 (Hyperion)",
        .revision   = "Rev 47.96",
        .released   = { 2021, 5 },
        .model      = RomModel::A4000,
        .vendor     = RomVendor::HYPERION,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_HYP320_47_96_A4000T,
        .title      = "Kickstart 3.2 (Hyperion)",
        .revision   = "Rev 47.96",
        .released   = { 2021, 5 },
        .model      = RomModel::A4000T,
        .vendor     = RomVendor::HYPERION,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_HYP321_47_102_A500,
        .title      = "Kickstart 3.2.1 (Hyperion)",
        .revision   = "Rev 47.102",
        .released   = { 2021, 12 },
        .model      = RomModel::A500 | RomModel::A600 | RomModel::A1000 | RomModel::A2000 | RomModel::CDTV,
        .vendor     = RomVendor::HYPERION,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_HYP321_47_102_A1200,
        .title      = "Kickstart 3.2.1 (Hyperion)",
        .revision   = "Rev 47.102",
        .released   = { 2021, 12 },
        .model      = RomModel::A1200,
        .vendor     = RomVendor::HYPERION,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_HYP321_47_102_A3000,
        .title      = "Kickstart 3.2.1 (Hyperion)",
        .revision   = "Rev 47.102",
        .released   = { 2021, 12 },
        .model      = RomModel::A3000,
        .vendor     = RomVendor::HYPERION,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_HYP321_47_102_A4000,
        .title      = "Kickstart 3.2.1 (Hyperion)",
        .revision   = "Rev 47.102",
        .released   = { 2021, 12 },
        .model      = RomModel::A4000,
        .vendor     = RomVendor::HYPERION,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_HYP321_47_102_A4000T,
        .title      = "Kickstart 3.2.1 (Hyperion)",
        .revision   = "Rev 47.102",
        .released   = { 2021, 12 },
        .model      = RomModel::A4000T,
        .vendor     = RomVendor::HYPERION,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_HYP322_47_111_A500,
        .title      = "Kickstart 3.2.2 (Hyperion)",
        .revision   = "Rev 47.111",
        .released   = { 2023, 3 },
        .model      = RomModel::A500 | RomModel::A600 | RomModel::A1000 | RomModel::A2000 | RomModel::CDTV,
        .vendor     = RomVendor::HYPERION,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_HYP322_47_111_A1200,
        .title      = "Kickstart 3.2.2 (Hyperion)",
        .revision   = "Rev 47.111",
        .released   = { 2023, 3 },
        .model      = RomModel::A1200,
        .vendor     = RomVendor::HYPERION,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_HYP322_47_111_A3000,
        .title      = "Kickstart 3.2.2 (Hyperion)",
        .revision   = "Rev 47.111",
        .released   = { 2023, 3 },
        .model      = RomModel::A3000,
        .vendor     = RomVendor::HYPERION,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_HYP322_47_111_A4000,
        .title      = "Kickstart 3.2.2 (Hyperion)",
        .revision   = "Rev 47.111",
        .released   = { 2023, 3 },
        .model      = RomModel::A4000,
        .vendor     = RomVendor::HYPERION,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_HYP322_47_111_A4000T,
        .title      = "Kickstart 3.2.2 (Hyperion)",
        .revision   = "Rev 47.111",
        .released   = { 2023, 3 },
        .model      = RomModel::A4000T,
        .vendor     = RomVendor::HYPERION,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_HYP323_47_115_A500,
        .title      = "Kickstart 3.2.3 (Hyperion)",
        .revision   = "Rev 47.115",
        .released   = { 2025, 4 },
        .model      = RomModel::A500 | RomModel::A600 | RomModel::A1000 | RomModel::A2000 | RomModel::CDTV,
        .vendor     = RomVendor::HYPERION,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_HYP323_47_115_A1200,
        .title      = "Kickstart 3.2.3 (Hyperion)",
        .revision   = "Rev 47.115",
        .released   = { 2025, 4 },
        .model      = RomModel::A1200,
        .vendor     = RomVendor::HYPERION,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_HYP323_47_115_A3000,
        .title      = "Kickstart 3.2.3 (Hyperion)",
        .revision   = "Rev 47.115",
        .released   = { 2025, 4 },
        .model      = RomModel::A3000,
        .vendor     = RomVendor::HYPERION,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_HYP323_47_115_A4000,
        .title      = "Kickstart 3.2.3 (Hyperion)",
        .revision   = "Rev 47.115",
        .released   = { 2025, 4 },
        .model      = RomModel::A4000,
        .vendor     = RomVendor::HYPERION,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_HYP323_47_115_A4000T,
        .title      = "Kickstart 3.2.3 (Hyperion)",
        .revision   = "Rev 47.115",
        .released   = { 2025, 4 },
        .model      = RomModel::A4000T,
        .vendor     = RomVendor::HYPERION,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_AROS_54705,
        .title      = "AROS Kickstart replacement",
        .revision   = "SVN 54705 (UAE version)",
        .released   = { 2017, 5 },
        .model      = 0,
        .vendor     = RomVendor::AROS,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_AROS_54705_EXT,
        .title      = "AROS Kickstart extension",
        .revision   = "SVN 54705 (UAE version)",
        .released   = { 2017, 5 },
        .model      = 0,
        .vendor     = RomVendor::AROS,
        .type       = RomType::AMIGA_EXTROM
    },{
        .crc        = CRC32_AROS_55696,
        .title      = "AROS Kickstart replacement",
        .revision   = "SVN 55696 (SAE version)",
        .released   = { 2019, 2 },
        .model      = 0,
        .vendor     = RomVendor::AROS,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_AROS_55696_EXT,
        .title      = "AROS Kickstart extension",
        .revision   = "SVN 55696 (SAE version)",
        .released   = { 2019, 2 },
        .model      = 0,
        .vendor     = RomVendor::AROS,
        .type       = RomType::AMIGA_EXTROM
    },{
        .crc        = CRC32_AROS_1ED13DE6E3,
        .title      = "AROS Kickstart replacement",
        .revision   = "Version 1ed13de6e3",
        .released   = { 2021, 9 },
        .model      = 0,
        .vendor     = RomVendor::AROS,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_AROS_1ED13DE6E3_EXT,
        .title      = "AROS Kickstart extension",
        .revision   = "Version 1ed13de6e3",
        .released   = { 2021, 9 },
        .model      = 0,
        .vendor     = RomVendor::AROS,
        .type       = RomType::AMIGA_EXTROM
    },{
        .crc        = CRC32_AROS_20250219,
        .title      = "AROS Kickstart replacement",
        .revision   = "Version 20250219",
        .released   = { 2025, 2 },
        .model      = 0,
        .vendor     = RomVendor::AROS,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_AROS_20250219_EXT,
        .title      = "AROS Kickstart extension",
        .revision   = "Version 20250219",
        .released   = { 2025, 2 },
        .model      = 0,
        .vendor     = RomVendor::AROS,
        .type       = RomType::AMIGA_EXTROM
    },{
        .crc        = CRC32_AROS_20260820,
        .title      = "AROS Kickstart replacement",
        .revision   = "Version 20260820",
        .released   = { 2026, 8 },
        .model      = 0,
        .vendor     = RomVendor::AROS,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_AROS_20260820_EXT,
        .title      = "AROS Kickstart extension",
        .revision   = "Version 20260820",
        .released   = { 2026, 8 },
        .model      = 0,
        .vendor     = RomVendor::AROS,
        .type       = RomType::AMIGA_EXTROM
    },{
        .crc        = CRC32_EMUTOS13,
        .title      = "EmuTOS Kickstart replacement",
        .revision   = "Version 1.3",
        .released   = { 2024, 3 },
        .model      = 0,
        .vendor     = RomVendor::EMUTOS,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_EMUTOS14,
        .title      = "EmuTOS Kickstart replacement",
        .revision   = "Version 1.4",
        .released   = { 2025, 6 },
        .model      = 0,
        .vendor     = RomVendor::EMUTOS,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_DIAG11,
        .title      = "Amiga DiagROM",
        .revision   = "Version 1.1",
        .released   = { 2018, 10 },
        .model      = 0,
        .vendor     = RomVendor::DIAG,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_DIAG12,
        .title      = "Amiga DiagROM",
        .revision   = "Version 1.2",
        .released   = { 2019, 8 },
        .model      = 0,
        .vendor     = RomVendor::DIAG,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_DIAG121,
        .title      = "Amiga DiagROM",
        .revision   = "Version 1.2.1",
        .released   = { 2020, 7 },
        .model      = 0,
        .vendor     = RomVendor::DIAG,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_DIAG13,
        .title      = "Amiga DiagROM",
        .revision   = "Version 1.3",
        .released   = { 2023, 4 },
        .model      = 0,
        .vendor     = RomVendor::DIAG,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_DIAG20,
        .title      = "Amiga DiagROM",
        .revision   = "Version 2.0",
        .released   = { 2026, 3 },
        .model      = 0,
        .vendor     = RomVendor::DIAG,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_CPUBLTRO_F8_0_3_2,
        .title      = "OCS CPUBLTRO",
        .revision   = "Version 0.3.2 (512 KB)",
        .released   = { 2024, 11 },
        .model      = 0,
        .vendor     = RomVendor::DEMO,
        .type       = RomType::AMIGA_KICKSTART
    },{
        .crc        = CRC32_CPUBLTRO_FC_0_3_2,
        .title      = "OCS CPUBLTRO",
        .revision   = "Version 0.3.2 (256 KB)",
        .released   = { 2024, 11 },
        .model      = 0,
        .vendor     = RomVendor::DEMO,
        .type       = RomType::AMIGA_KICKSTART
    }
};

string
RomDateToString(RomDate date)
{
    static const char *names[] = {
        "", "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    };

    if (date.year == 0) return "";
    if (date.month == 0 || date.month > 12) return std::to_string(date.year);

    return string(names[date.month]) + " " + std::to_string(date.year);
}

string
RomModelToString(u32 model)
{
    if (model == 0) return "";
    if (model == RomModel::GENERIC_C64) return "Any C64";
    if (model == RomModel::GENERIC_VC1541) return "Any VC1541";
    if (model == RomModel::GENERIC_AMIGA) return "Amiga";

    static const std::pair<u32, const char *> names[] = {
        { RomModel::C64,      "C64"     }, { RomModel::C64II,    "C64C"    },
        { RomModel::SX64,     "SX64"    }, { RomModel::PET64,    "PET64"   },
        { RomModel::VC1541,   "VC1541"  }, { RomModel::VC1541C,  "1541C"   },
        { RomModel::VC1541II, "1541-II" },
        { RomModel::A500,     "A500"    }, { RomModel::A600,     "A600"    },
        { RomModel::A600HD,   "A600HD"  }, { RomModel::A1000,    "A1000"   },
        { RomModel::A1200,    "A1200"   }, { RomModel::A2000,    "A2000"   },
        { RomModel::A3000,    "A3000"   }, { RomModel::A4000,    "A4000"   },
        { RomModel::A4000T,   "A4000T"  }, { RomModel::CD32,     "CD32"    },
        { RomModel::CDTV,     "CDTV"    },
    };

    string result;
    for (auto &[bit, name] : names) {

        if (!(model & bit)) continue;
        if (!result.empty()) result += ", ";
        result += name;
    }

    return result;
}

RomManager::RomManager()
{
    /* Index the static table by both checksums. An entry carries exactly one of
     * them -- the other is zero -- so skipping zero keys keeps the two indices
     * disjoint. Without that guard, looking up an empty Rom slot (checksum 0)
     * would match the entries of the other machine.
     */
    for (const auto &traits : roms) {

        if (traits.crc) crc32Info[traits.crc] = traits;
        if (traits.fnv) fnv64Info[traits.fnv] = traits;
    }
}

RomManager &
RomManager::shared()
{
    static RomManager instance;
    return instance;
}


//
// Querying the database
//

std::optional<RomTraits>
RomManager::resolveCRC32(u32 crc) const
{
    if (auto it = crc32Info.find(crc); it != crc32Info.end()) return it->second;
    return std::nullopt;
}

std::optional<RomTraits>
RomManager::resolveFNV64(u64 fnv) const
{
    if (auto it = fnv64Info.find(fnv); it != fnv64Info.end()) return it->second;
    return std::nullopt;
}

std::vector<RomTraits>
RomManager::getRoms(const std::function<bool(const RomTraits &)> &filter) const
{
    std::vector<RomTraits> result;

    for (const auto &traits : roms) {
        if (filter(traits)) result.push_back(traits);
    }

    return result;
}

std::optional<RomTraits>
RomManager::resolve(const fs::path &path) const
{
    try {

        utl::Buffer<u8> buffer(path);
        if (buffer.size == 0) return std::nullopt;

        if (auto traits = resolveCRC32(buffer.crc32())) return traits;
        return resolveFNV64(buffer.fnv64());

    } catch (...) {

        // Unreadable files are simply not Roms as far as this class cares
        return std::nullopt;
    }
}


//
// Locating real Rom files
//

std::optional<fs::path>
RomManager::getRom(const RomTraits &traits) const
{
    if (auto path = getRomCRC32(traits.crc)) return path;
    return getRomFNV64(traits.fnv);
}

std::optional<fs::path>
RomManager::getRomCRC32(u32 crc) const
{
    if (auto it = crc32Path.find(crc); it != crc32Path.end()) return it->second;
    return std::nullopt;
}

std::optional<fs::path>
RomManager::getRomFNV64(u64 fnv) const
{
    if (auto it = fnv64Path.find(fnv); it != fnv64Path.end()) return it->second;
    return std::nullopt;
}


//
// Managing the folder list
//

void
RomManager::clearFolderList()
{
    folders.clear();
}

void
RomManager::addFolder(const fs::path &path)
{
    /* Normalize first, so that the duplicate check is not defeated by a
     * trailing separator or a path spelled relative to the working directory.
     */
    std::error_code ec;
    auto folder = fs::weakly_canonical(path, ec);
    if (ec) folder = path;

    if (std::find(folders.begin(), folders.end(), folder) == folders.end()) {
        folders.push_back(folder);
    }
}

void
RomManager::clearScanResults()
{
    crc32Path.clear();
    fnv64Path.clear();
}

isize
RomManager::scanFolders()
{
    // Roms are small; anything larger is not worth hashing
    constexpr auto maxRomSize = 8 * 1024 * 1024;

    clearScanResults();

    for (const auto &folder : folders) {

        std::error_code ec;
        auto opts = fs::directory_options::skip_permission_denied;
        fs::recursive_directory_iterator it(folder, opts, ec), end;

        // A folder that has gone away is skipped, not an error
        for (; !ec && it != end; it.increment(ec)) {

            /* Errors below use a separate code, so that a single unreadable
             * entry cannot be mistaken for a failure of the walk itself.
             */
            std::error_code fec;

            if (!it->is_regular_file(fec) || fec) continue;

            auto size = it->file_size(fec);
            if (fec || size == 0 || size > maxRomSize) continue;

            u32 crc;
            u64 fnv;

            try {

                utl::Buffer<u8> buffer(it->path());
                crc = buffer.crc32();
                fnv = buffer.fnv64();

            } catch (...) { continue; }

            /* emplace() keeps the entry already present, so the first file
             * found for a checksum wins and the folder list acts as a
             * precedence order.
             */
            if (crc32Info.contains(crc)) crc32Path.emplace(crc, it->path());
            if (fnv64Info.contains(fnv)) fnv64Path.emplace(fnv, it->path());
        }
    }

    return isize(crc32Path.size() + fnv64Path.size());
}

}
