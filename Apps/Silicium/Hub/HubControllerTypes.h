// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#pragma once

#include "SiTypes.h"
#include "utl/types/UUID.h"

class QProcess;

// A running emulator helper process (SiC64 or SiAmiga) and the state it last
// reported of itself. The emulators have no controller on the Hub side yet,
// so the Hub tracks their state from "vmState" JSON-RPC notifications sent
// over the process's stdout -- see createProcess() and processRpcPacket().
// Temporary until the emulators get a proper controller wrapping the
// process + JSON-RPC link.
struct VMProcess {

    QProcess *process = nullptr;
    utl::UUID vUUID;
    VMState state = VMState::HIBERNATED;
};
