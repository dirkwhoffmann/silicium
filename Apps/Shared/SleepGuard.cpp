// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "config.h"
#include "SleepGuard.h"
#include <QtGlobal>

bool SleepGuard::active = false;

#if defined(Q_OS_MACOS)

#include <IOKit/pwr_mgt/IOPMLib.h>

namespace {
IOPMAssertionID assertionID = kIOPMNullAssertionID;
}

void
SleepGuard::preventSleep()
{
    if (active) return;

    IOPMAssertionCreateWithName(
        kIOPMAssertionTypeNoIdleSleep,
        kIOPMAssertionLevelOn,
        CFSTR("Running an emulator"),
        &assertionID);

    active = true;
}

void
SleepGuard::allowSleep()
{
    if (!active) return;

    if (assertionID != kIOPMNullAssertionID) {
        IOPMAssertionRelease(assertionID);
        assertionID = kIOPMNullAssertionID;
    }

    active = false;
}

#elif defined(Q_OS_WIN)

#include <windows.h>

void
SleepGuard::preventSleep()
{
    if (active) return;

    SetThreadExecutionState(ES_CONTINUOUS | ES_SYSTEM_REQUIRED | ES_DISPLAY_REQUIRED);

    active = true;
}

void
SleepGuard::allowSleep()
{
    if (!active) return;

    SetThreadExecutionState(ES_CONTINUOUS);

    active = false;
}

#else

// No sleep-prevention API hooked up for this platform yet.
void SleepGuard::preventSleep() { active = true; }
void SleepGuard::allowSleep() { active = false; }

#endif
