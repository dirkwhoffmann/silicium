// -----------------------------------------------------------------------------
// This file is part of vAmiga
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#include "vaconfig.h"
#include "LogicAnalyzer.h"
#include "Amiga.h"

namespace vamiga {

LogicAnalyzer::LogicAnalyzer(Amiga& ref) : SubComponent(ref)
{
    info.bind([this] { return cacheInfo(); } );

    /* -1, not 0: a cycle nothing was probed on is not a cycle that read
     * zero, and both the view and the ring rely on the distinction. The
     * array was previously left uninitialised until the first probe change
     * wiped it, so a channel read before then held whatever was on the
     * stack.
     */
    for (isize i = 0; i < 4; i++) std::fill_n(record[i], HPOS_CNT, -1);
};

void
LogicAnalyzer::_pause()
{
    recordDelayed(agnus.pos.h);
}

void
LogicAnalyzer::_didReset(bool hard)
{
    // Recorded history describes a machine that no longer exists
    traces.clear();

    checkEnable();
}

void
LogicAnalyzer::_dump(Category category, std::ostream &os) const
{
    if (category == Category::Config) {
        
        dumpConfig(os);
    }
}

LogicAnalyzerInfo
LogicAnalyzer::cacheInfo() const
{
    LogicAnalyzerInfo info;

    info.busOwner = agnus.busOwner;
    info.addrBus = agnus.busAddr;
    info.dataBus = agnus.busData;

    for (isize i = 0; i < 4; i++) {
        info.channel[i] = record[i];
    }

    return info;
}

i64
LogicAnalyzer::getOption(Opt option) const
{
    switch (option) {
            
        case Opt::LA_PROBE0: return (i64)config.channel[0];
        case Opt::LA_PROBE1: return (i64)config.channel[1];
        case Opt::LA_PROBE2: return (i64)config.channel[2];
        case Opt::LA_PROBE3: return (i64)config.channel[3];
        case Opt::LA_ADDR0: return (i64)config.addr[0];
        case Opt::LA_ADDR1: return (i64)config.addr[1];
        case Opt::LA_ADDR2: return (i64)config.addr[2];
        case Opt::LA_ADDR3: return (i64)config.addr[3];

        default:
            fatalError;
    }
}

void
LogicAnalyzer::checkOption(Opt opt, i64 value)
{
    switch (opt) {

        case Opt::LA_PROBE0:
        case Opt::LA_PROBE1:
        case Opt::LA_PROBE2:
        case Opt::LA_PROBE3:

            if (!ProbeEnum::isValid(value)) {
                throw CoreError(CoreError::OPT_INV_ARG, ProbeEnum::keyList());
            }
            
        case Opt::LA_ADDR0:
        case Opt::LA_ADDR1:
        case Opt::LA_ADDR2:
        case Opt::LA_ADDR3:

            return;

        default:
            throw CoreError(CoreError::OPT_UNSUPPORTED);
    }
}

void
LogicAnalyzer::setOption(Opt option, i64 value)
{
    isize c = 0;
    bool invalidate = false;
    
    switch (option) {
            
        case Opt::LA_PROBE3: c++; [[fallthrough]];
        case Opt::LA_PROBE2: c++; [[fallthrough]];
        case Opt::LA_PROBE1: c++; [[fallthrough]];
        case Opt::LA_PROBE0:

            invalidate = config.channel[c] != (Probe)value;
            config.channel[c] = (Probe)value;
            break;
            
        case Opt::LA_ADDR3: c++; [[fallthrough]];
        case Opt::LA_ADDR2: c++; [[fallthrough]];
        case Opt::LA_ADDR1: c++; [[fallthrough]];
        case Opt::LA_ADDR0:
            
            invalidate = config.addr[c] != (u32)value && config.channel[c] == Probe::MEMORY;
            config.addr[c] = (u32)value;
            break;

        default:
            fatalError;
    }

    /* Wipe out prerecorded data if necessary.
     *
     * The ring goes with it. An entry is only meaningful next to the probe
     * configuration it was taken under and does not carry that
     * configuration, so keeping it across a probe change would leave a
     * reader mixing old and new readings with no way to tell them apart.
     */
    if (invalidate) {

        std::fill_n(record[c], HPOS_CNT, -1);
        traces.clear();
    }
 
    // Enable or disable the logic analyzer
    checkEnable();
}

void
LogicAnalyzer::setEnabled(bool value)
{
    if (enabled == value) return;

    enabled = value;
    checkEnable();
}

void
LogicAnalyzer::checkEnable()
{
    bool enable =
    enabled ||
    config.channel[0] != Probe::NONE ||
    config.channel[1] != Probe::NONE ||
    config.channel[2] != Probe::NONE ||
    config.channel[3] != Probe::NONE ;
    
    enable ? agnus.syncEvent |= EVFL::PROBE : agnus.syncEvent &= ~EVFL::PROBE;
}

void
LogicAnalyzer::recordSignals()
{
    // Only proceed if this is the main instance
    if (isRunAheadInstance()) { return; }

    /*
     This function records all requested signal values when the logic analyzer
     is active. The function is called inside the REG slot handler after all
     pending register changes have been performed. As a result, the logic
     analyzer sees the Amiga's internal state just as the CPU would see it when
     reading from memory. This is fine for memory probing, as the obtained
     values are the ones we want to see in the logic analyzer.
          
     However, when examining other signals, we need to pay special attention.
     E.g., when probing the CPU's IPL lines, the function getIPL() provides us
     with the IPL line the CPU has seen in the previous cycle. This is because
     the IPL line is updated by a Paula event, which triggers after this
     function has been called but before the CPU queries the signal. The code
     below copes with this situation by splitting the recording code into two
     separate functions. The first one probes all signals whose values belong
     to the current DMA cycle. The second function probes all signals that need
     to be recorded with the timestamp of the previous DMA cycle.

     The second function is also called when the emulator pauses to complement
     the missing signal values.
     */
    
    recordCurrent(agnus.pos.h);
    recordDelayed(agnus.pos.hPrev());

    recordTrace();
}

void
LogicAnalyzer::recordTrace()
{
    /* The cycle that has just finished, not the one now starting.
     *
     * Nothing about the current cycle is settled yet: SLOT_REG is serviced
     * ahead of the DMA slots, so no owner has claimed it, and getIPL()
     * reports what the CPU saw a cycle ago. One cycle back, all of it is
     * final -- and recordCurrent() wrote that cycle's probe values into
     * record[] on the previous call, so they are still there to be copied.
     */
    const isize hpos = agnus.pos.hPrev();

    /* Its line, which is not always the line the beam is on now.
     *
     * At h == 0 the beam has already left the line we are recording:
     * Beam::eol() resets h and advances v from inside the very REG event
     * that calls us, so pos.v names the new line while pos.hPrev() names the
     * old one's last cycle. vPrev() resolves that, and falls back to
     * vLatched at a frame boundary, where v has wrapped to 0 as well.
     */
    const isize vpos = agnus.pos.h ? agnus.pos.v : agnus.pos.vPrev();

    if (hpos < 0 || hpos >= HPOS_CNT) return;

    LogicAnalyzerTrace trace {};

    trace.vpos = vpos;
    trace.hpos = hpos;

    trace.busOwner = agnus.busOwner[hpos];
    trace.addrBus = agnus.busAddr[hpos];
    trace.dataBus = agnus.busData[hpos];

    for (isize i = 0; i < 4; i++) trace.channel[i] = record[i][hpos];

    /* put(), not write(): the ring is a sliding window over a signal that
     * runs for as long as the emulator does, so the oldest cycle is meant to
     * fall off the end rather than to stop the newest being recorded.
     */
    traces.put(trace);
}

void
LogicAnalyzer::recordCurrent(isize hpos)
{
    for (isize i = 0; i < 4; i++) {
        
        switch (config.channel[i]) {

            case Probe::MEMORY:
                
                record[i][hpos] = isize(mem.spypeek16<Accessor::CPU>(config.addr[i]));
                break;
                
            default:
                break;
        }
    }
}

void
LogicAnalyzer::recordDelayed(isize hpos)
{
    for (isize i = 0; i < 4; i++) {
        
        switch (config.channel[i]) {
                
            case Probe::IPL:

                record[i][hpos] = cpu.getIPL();
                break;

            default:
                break;
        }
    }
}

}
