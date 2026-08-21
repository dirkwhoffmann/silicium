// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#pragma once

/* Keeps the host machine from going to sleep while an emulator is running.
 * Intended usage: call preventSleep() when an emulator instance enters the
 * RUNNING state, and allowSleep() when it enters the PAUSED or HALTED state
 * (or is powered off). Both functions are idempotent.
 */
class SleepGuard {

public:

    // Requests that the host stays awake. Does nothing if already active.
    static void preventSleep();

    // Withdraws a previous preventSleep() request. Does nothing if inactive.
    static void allowSleep();

private:

    static bool active;
};
