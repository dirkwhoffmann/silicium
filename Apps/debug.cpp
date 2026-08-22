// -----------------------------------------------------------------------------
// This file is part of Silicium
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#if 0

#include "config.h"

#define STR(x)  #x
#define XSTR(x) STR(x)

#define DEBUG_CHANNEL(name, description)                                                                               \
LogChannel name = ::utl::debug::name                                                                               \
? Loggable::subscribe(XSTR(name), std::optional<long>(7), description)                       \
: Loggable::subscribe(XSTR(name), std::optional<long>(std::nullopt), description);

namespace utl::channel {

    // Register the default channels

    DEBUG_CHANNEL(NULLDEV, "Message sink");
    DEBUG_CHANNEL(STDERR, "Standard error");

    // Register a logging channel for each debug flag

    // File systems
    DEBUG_CHANNEL(FS_DEBUG, "File System Classes (OFS / FFS)");

    // Image files
    DEBUG_CHANNEL(IMG_DEBUG, "Disk images");
    DEBUG_CHANNEL(ADF_DEBUG, "ADF, ADZ and extended ADF files");
    DEBUG_CHANNEL(HDF_DEBUG, "HDF and HDZ files");
    DEBUG_CHANNEL(DMS_DEBUG, "DMS files");

} // namespace utl::channel

#endif
