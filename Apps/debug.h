// -----------------------------------------------------------------------------
// This file is part of Silicium
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#pragma once

#include "utl/abilities/Loggable.h"

namespace utl::debug {

//
// Debug settings
//

// Default channels
constexpr long NULLDEV    = 0;
constexpr long STDERR     = 1;

// File systems
constexpr long FS_DEBUG   = 0;

// Image files
constexpr long ADF_DEBUG  = 0;
constexpr long HDF_DEBUG  = 0;
constexpr long DMS_DEBUG  = 0;
constexpr long IMG_DEBUG  = 0;

} // namespace utl::debug

//
// Forced error conditions
//

namespace utl::force {

constexpr long HDR_TOO_LARGE        = 0;
constexpr long HDR_UNSUPPORTED_C    = 0;
constexpr long HDR_UNSUPPORTED_H    = 0;
constexpr long HDR_UNSUPPORTED_S    = 0;
constexpr long HDR_UNSUPPORTED_B    = 0;
constexpr long HDR_UNKNOWN_GEOMETRY = 0;
constexpr long HDR_MODIFIED         = 0;
constexpr long FS_WRONG_BSIZE       = 0;
constexpr long FS_WRONG_CAPACITY    = 0;
constexpr long FS_WRONG_DOS_TYPE    = 0;
constexpr long DMS_CANT_CREATE      = 0;

} // namespace utl::force

//
// Logging channels
//

/* For each debug setting, the emulator registers a corresponding log channel
 * with the Loggable interface. Log channels initialized with a debug level
 * of 0 are disabled by default.
 *
 * In debug builds, log channels can be enabled, disabled, or reconfigured
 * dynamically via the Loggable interface. In release builds, the initial
 * configuration is fixed and cannot be modified, allowing the compiler
 * to apply performance optimization.
 */

namespace utl::channel {

// Default channels (always disabled / enabled)
extern long NULLDEV;
extern long STDERR;

// File systems
extern long FS_DEBUG;

// Images
extern long ADF_DEBUG;
extern long HDF_DEBUG;
extern long DMS_DEBUG;
extern long IMG_DEBUG;

} // namespace utl::channel


//
// Main logging macro
//

#if NDEBUG

    #define logMsg(key, level, format, ...)                                                                            \
        do {                                                                                                           \
            if constexpr (debug::key)                                                                                  \
                log(channel::key, level, std::source_location::current(), format __VA_OPT__(, ) __VA_ARGS__);          \
        } while (0)

#else

    #define logMsg(key, level, format, ...)                                                                            \
        do {                                                                                                           \
            log(channel::key, level, std::source_location::current(), format __VA_OPT__(, ) __VA_ARGS__);              \
        } while (0)

#endif


//
// Wrappers for all syslog levels
//

#define logemergency(format, ...)       logMsg(STDERR, LogLevel::LOG_EMERG, format __VA_OPT__(, ) __VA_ARGS__)
#define logalert(format, ...)           logMsg(STDERR, LogLevel::LOG_ALERT, format __VA_OPT__(, ) __VA_ARGS__)
#define logcritical(format, ...)        logMsg(STDERR, LogLevel::LOG_CRIT, format __VA_OPT__(, ) __VA_ARGS__)
#define logerror(format, ...)           logMsg(STDERR, LogLevel::LOG_ERR, format __VA_OPT__(, ) __VA_ARGS__)
#define logwarn(format, ...)            logMsg(STDERR, LogLevel::LOG_WARNING, format __VA_OPT__(, ) __VA_ARGS__)
#define lognotice(channel, format, ...) logMsg(channel, LogLevel::LOG_NOTICE, format __VA_OPT__(, ) __VA_ARGS__)
#define loginfo(channel, format, ...)   logMsg(channel, LogLevel::LOG_INFO, format __VA_OPT__(, ) __VA_ARGS__)
#define logdebug(channel, format, ...)  logMsg(channel, LogLevel::LOG_DEBUG, format __VA_OPT__(, ) __VA_ARGS__)


//
// Convenience wrappers
//

#define xfiles(format, ...) logMsg(XFILES, LogLevel::LOG_INFO, format __VA_OPT__(, ) __VA_ARGS__)
