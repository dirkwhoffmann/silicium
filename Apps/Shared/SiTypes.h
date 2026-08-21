// -----------------------------------------------------------------------------
// This file is part of Silicium
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#pragma once

#include "utl/abilities/Reflectable.h"

//
// Expose custom types
//

using utl::i8;
using utl::i16;
using utl::i32;
using utl::i64;
using utl::isize;

using utl::u8;
using utl::u16;
using utl::u32;
using utl::u64;
using utl::usize;


//
// Enumerations
//

enum class VMState : long { HIBERNATED, THAWED, OFF, PAUSED, RUNNING, HALTED };

struct VMStateEnum : utl::Reflectable<VMStateEnum, VMState> {

    static constexpr long minVal = 0;
    static constexpr long maxVal = long(VMState::HALTED);

    static const char *_key(VMState value)
    {
        switch (value) {

            case VMState::HIBERNATED: return "HIBERNATED";
            case VMState::THAWED:     return "THAWED";
            case VMState::OFF:        return "OFF";
            case VMState::PAUSED:     return "PAUSED";
            case VMState::RUNNING:    return "RUNNING";
            case VMState::HALTED:     return "HALTED";
        }
        return "???";
    }
};