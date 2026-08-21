// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "SiC64SIDController.h"
#include "C64Controller.h"

using namespace vc64;

SiC64SIDController::SiC64SIDController(C64Controller *parent)
    : SiC64InspectorController(parent)
{

}

void
SiC64SIDController::refreshData()
{
    // Read the SID info and audio stats from the shared info controller
    // rather than sampling the core directly; requestUpdate() coalesces the
    // sampling across all open inspectors.
    auto *infoController = parent->getInfoController();
    infoController->requestUpdate(SiC64InfoController::SID | SiC64InfoController::AUDIO, 0.25);

    auto &info = infoController->sidInfo(m_selectedSID);
    auto &stats = infoController->audioStats();

    QVariantList voices;

    for (int i = 0; i < 3; i++) {

        const auto &v = info.voice[i];

        QVariantMap voice;
        voice["frequency"]   = v.frequency;
        voice["pulseWidth"]  = v.pulseWidth;
        voice["attackRate"]  = v.attackRate;
        voice["decayRate"]   = v.decayRate;
        voice["sustainRate"] = v.sustainRate;
        voice["releaseRate"] = v.releaseRate;

        // Waveform bits (see SIDPanel.swift): 0x10 triangle, 0x20 sawtooth,
        // 0x40 pulse, 0x80 noise. Pulse width only matters for the pulse
        // waveform.
        voice["wavTriangle"] = bool(v.waveform & 0x10);
        voice["wavSawtooth"] = bool(v.waveform & 0x20);
        voice["wavPulse"]    = bool(v.waveform & 0x40);
        voice["wavNoise"]    = bool(v.waveform & 0x80);
        voice["hasPulse"]    = bool(v.waveform & 0x40);

        voice["gate"] = v.gateBit;
        voice["test"] = v.testBit;
        voice["sync"] = v.hardSync;
        voice["ring"] = v.ringMod;

        voices.append(voice);
    }

    m_voices = voices;

    m_volume = info.volume;
    m_potX   = info.potX;
    m_potY   = info.potY;

    m_filterCutoff    = info.filterCutoff;
    m_filterResonance = info.filterResonance;
    m_filterType = info.filterType;
    m_filter1 = info.filterEnableBits & 0x01;
    m_filter2 = info.filterEnableBits & 0x02;
    m_filter3 = info.filterEnableBits & 0x04;

    m_audioFill = int(stats.fillLevel * 100);
    m_audioFillText = QString("%1 %").arg(m_audioFill);
    m_underflows = QString::number(stats.bufferUnderflows);
    m_overflows  = QString::number(stats.bufferOverflows);

    emit sidChanged();
}

void
SiC64SIDController::setSelectedSID(int value)
{
    value = qBound(0, value, 3);

    if (m_selectedSID != value) {

        m_selectedSID = value;
        refresh();
    }
}

void
SiC64SIDController::setWaveformSource(int value)
{
    if (m_waveformSource != value) {

        m_waveformSource = value;
        emit sidChanged();
    }
}
