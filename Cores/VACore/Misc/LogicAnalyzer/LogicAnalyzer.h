// -----------------------------------------------------------------------------
// This file is part of vAmiga
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#pragma once

#include "LogicAnalyzerTypes.h"
#include "SubComponent.h"
#include "Constants.h"
#include "utl/wrappers.h"
#include "utl/storage/RingBuffer.h"

namespace vamiga {

class LogicAnalyzer final : public SubComponent {
    
    Descriptions descriptions = {{

        .type           = Class::LogicAnalyzer,
        .name           = "LogicAnalyzer",
        .description    = "Logic Analyzer",
        .shell          = "logicanalyzer"
    }};

    Options options = {

        Opt::LA_PROBE0,
        Opt::LA_PROBE1,
        Opt::LA_PROBE2,
        Opt::LA_PROBE3,
        Opt::LA_ADDR0,
        Opt::LA_ADDR1,
        Opt::LA_ADDR2,
        Opt::LA_ADDR3
    };

    // The current configuration
    LogicAnalyzerConfig config = {};

public:

    // Result of the latest inspection
    utl::Backed<LogicAnalyzerInfo> info;

public:

    // How many scanlines the ring spans
    static constexpr isize traceLines = 3;

    /* How many recorded cycles it holds.
     *
     * An entry is a single DMA cycle (64 bytes), so three lines is around
     * 43 KB -- the ring is allocated whether or not the analyzer is running,
     * and at that size it is not worth making conditional.
     */
    static constexpr isize traceHistory = traceLines * HPOS_CNT;

    /* RingBuffer distinguishes full from empty by leaving one slot unused,
     * so it holds capacity - 1 elements. Deriving the capacity here keeps
     * the number above meaning what it says.
     */
    static constexpr isize traceCapacity = traceHistory + 1;

private:

    /* Signal values for the line being recorded, indexed by DMA cycle.
     *
     * Still the place the probes write to, and still what cacheInfo() hands
     * out, so the existing per-line view is unaffected. It doubles as the
     * staging area for the ring: recordTrace() copies a cycle out of here
     * once that cycle is complete, which is what saves the ring from needing
     * a half-built entry of its own.
     */
    isize record[4][HPOS_CNT];

    // Recorded cycles, oldest first
    utl::RingBuffer<LogicAnalyzerTrace, traceCapacity> traces;
    
private:
    
    //
    // Constructing
    //
    
public:
    
    LogicAnalyzer(Amiga& ref);

    LogicAnalyzer& operator= (const LogicAnalyzer& other) {

        return *this;
    }


    //
    // Methods from CoreObject
    //
    
private:
    
    void _dump(Category category, std::ostream &os) const override;

    
    //
    // Methods from CoreComponent
    //
    
public:

    const Descriptions &getDescriptions() const override { return descriptions; }
    void _pause() override;

    
    //
    // Analyzing
    //

public:

    LogicAnalyzerInfo cacheInfo() const;

    
    //
    // Methods from Configurable
    //

public:

    const LogicAnalyzerConfig &getConfig() const { return config; }
    const Options &getOptions() const override { return options; }
    i64 getOption(Opt option) const override;
    void checkOption(Opt opt, i64 value) override;
    void setOption(Opt option, i64 value) override;

    
    //
    // Serializing
    //
    
    template <class T> void serialize(T& worker) { } SERIALIZERS(serialize);
    void _didReset(bool hard) override;

    
    //
    // Recording
    //
    
    
public:
        
    // Records data for all configured channels
    void recordSignals();
    
private:

    // Records all signal values belonging to the current DMA cycle
    void recordCurrent(isize hpos);

    // Records all signal values belonging to the previous DMA cycle
    void recordDelayed(isize hpos);

    // Files the DMA cycle that has just finished away in the ring
    void recordTrace();

    // Enable or disables the logic analyzer based on the current config
    void checkEnable();
    
    
    //
    // Accessing
    //
    
public:
    
    isize get(isize channel, isize nr) { return record[channel][nr]; }
    isize *get(isize channel) { return record[channel]; }

    // How many recorded cycles are available, oldest first
    isize getTraceCount() const { return traces.count(); }

    /* One of them, 0 being the oldest still held.
     *
     * Indices shift as recording continues, so a caller after a particular
     * cycle rather than a particular slot should match on the entry's own
     * vpos/hpos instead of remembering an index.
     */
    const LogicAnalyzerTrace &getTrace(isize i) const { return traces.current(i); }
};

}

