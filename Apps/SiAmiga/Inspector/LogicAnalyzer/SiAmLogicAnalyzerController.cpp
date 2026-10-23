// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "SiAmLogicAnalyzerController.h"
#include "SiAmController.h"

#include <iterator>

using namespace vamiga;

// Mirrors Inspector.presets (BusPanel.swift), separators marked by a null
// name.
const SiAmLogicAnalyzerController::Preset SiAmLogicAnalyzerController::presets[] = {

    { "None",     Probe::NONE,   false, 0 },
    { "Memory",   Probe::MEMORY, false, 0 },
    { nullptr,    Probe::NONE,   false, 0 },
    { "DMACONR",  Probe::MEMORY, true,  0xDFF002 },
    { "VPOSR",    Probe::MEMORY, true,  0xDFF004 },
    { "VHPOSR",   Probe::MEMORY, true,  0xDFF006 },
    { "DSKDATR",  Probe::MEMORY, true,  0xDFF008 },
    { "JOY0DAT",  Probe::MEMORY, true,  0xDFF00A },
    { "JOY1DAT",  Probe::MEMORY, true,  0xDFF00C },
    { "CLXDAT",   Probe::MEMORY, true,  0xDFF00E },
    { "ADKCONR",  Probe::MEMORY, true,  0xDFF010 },
    { "POT0DAT",  Probe::MEMORY, true,  0xDFF012 },
    { "POT1DAT",  Probe::MEMORY, true,  0xDFF014 },
    { "POTGOR",   Probe::MEMORY, true,  0xDFF016 },
    { "SERDATR",  Probe::MEMORY, true,  0xDFF018 },
    { "DSKBYTR",  Probe::MEMORY, true,  0xDFF01A },
    { "INTENAR",  Probe::MEMORY, true,  0xDFF01C },
    { "INTREQR",  Probe::MEMORY, true,  0xDFF01E },
    { "DENISEID", Probe::MEMORY, true,  0xDFF07C },
    { nullptr,    Probe::NONE,   false, 0 },
    { "IPL",      Probe::IPL,    false, 0 },
};

// Derived from the table above, never stated alongside it. Constant-
// initialised: std::size() of a complete array is a constant expression,
// so there is no static-initialisation order to worry about.
const int SiAmLogicAnalyzerController::numPresets = std::size(presets);

SiAmLogicAnalyzerController::SiAmLogicAnalyzerController(SiAmController *parent)
    : SiAmInspectorController(parent)
{

}

QVariantList
SiAmLogicAnalyzerController::presetModel() const
{
    QVariantList list;

    for (int i = 0; i < numPresets; i++) {

        QVariantMap entry;
        entry["separator"] = presets[i].name == nullptr;
        entry["name"] = presets[i].name ? QString(presets[i].name) : QString();

        // Everything but the IPL signal is probed through an address
        entry["hasAddress"] = presets[i].probe != Probe::IPL;
        list.append(entry);
    }
    return list;
}

void
SiAmLogicAnalyzerController::selectPreset(int channel, int index)
{
    if (channel < 0 || channel > 3 || index < 0 || index >= numPresets) return;

    auto &core = SiAmController::core();
    const auto &preset = presets[index];
    auto probeOpt = Opt(int(Opt::LA_PROBE0) + channel);
    auto addrOpt = Opt(int(Opt::LA_ADDR0) + channel);

    try {

        core.setAsync(probeOpt, (i64)preset.probe);
        if (preset.hasAddr) core.setAsync(addrOpt, (i64)preset.addr);

    } catch (...) { }
}

int
SiAmLogicAnalyzerController::presetIndex(int channel) const
{
    if (channel < 0 || channel > 3) return 0;

    auto &core = SiAmController::core();
    auto probeOpt = Opt(int(Opt::LA_PROBE0) + channel);
    auto addrOpt = Opt(int(Opt::LA_ADDR0) + channel);

    Probe probe = Probe::NONE;
    u32 addr = 0;

    try {

        probe = Probe(core.get(probeOpt));
        addr = (u32)core.get(addrOpt);

    } catch (...) { }

    int memory = 0;

    for (int i = 0; i < numPresets; i++) {

        const auto &preset = presets[i];
        if (!preset.name) continue;

        // The preset for an arbitrary memory location is the fallback
        if (preset.probe == Probe::MEMORY && !preset.hasAddr) memory = i;

        if (probe == Probe::MEMORY) {
            if (preset.probe == Probe::MEMORY && preset.hasAddr && preset.addr == addr) return i;
        } else {
            if (preset.probe == probe) return i;
        }
    }

    return probe == Probe::MEMORY ? memory : 0;
}

QString
SiAmLogicAnalyzerController::probeAddress(int channel) const
{
    if (channel < 0 || channel > 3) return QString();

    auto &core = SiAmController::core();
    auto probeOpt = Opt(int(Opt::LA_PROBE0) + channel);
    auto addrOpt = Opt(int(Opt::LA_ADDR0) + channel);

    try {

        if (Probe(core.get(probeOpt)) != Probe::MEMORY) return QString();
        return QString("%1").arg((unsigned)core.get(addrOpt), 6, 16, QChar('0')).toUpper();

    } catch (...) { }

    return QString();
}

bool
SiAmLogicAnalyzerController::selectAddress(int channel, const QString &hex)
{
    if (channel < 0 || channel > 3) return false;

    bool ok = false;
    unsigned addr = hex.toUInt(&ok, 16);
    if (!ok) return false;

    auto &core = SiAmController::core();
    auto probeOpt = Opt(int(Opt::LA_PROBE0) + channel);
    auto addrOpt = Opt(int(Opt::LA_ADDR0) + channel);

    try {

        core.setAsync(probeOpt, (i64)Probe::MEMORY);
        core.setAsync(addrOpt, (i64)addr);

    } catch (...) { return false; }

    return true;
}

QString
SiAmLogicAnalyzerController::probeLabel(int channel) const
{
    if (channel < 0 || channel > 3) return QString();

    auto &core = SiAmController::core();
    auto probeOpt = Opt(int(Opt::LA_PROBE0) + channel);
    auto addrOpt = Opt(int(Opt::LA_ADDR0) + channel);

    Probe probe = Probe::NONE;
    i64 addr = 0;

    try {

        probe = Probe(core.get(probeOpt));
        addr = core.get(addrOpt);

    } catch (...) { }

    switch (probe) {

        case Probe::MEMORY: return QString("%1").arg((unsigned)addr, 6, 16, QChar('0')).toUpper();
        case Probe::IPL:    return QStringLiteral("IPL");
        default:            return QObject::tr("Connect...");
    }
}
