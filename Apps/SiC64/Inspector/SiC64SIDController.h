// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#pragma once

#include "SiC64InspectorController.h"
#include <QVariantList>

//
// SID inspector controller -- port of the old Swift-based emulator's SID
// inspector (Inspector.swift's SID tab / SIDPanel.swift). Exposes the
// selected SID's three voices (waveform, frequency, pulse width, ADSR
// envelope and gate/test/sync/ring bits), the master volume, paddle
// potentiometers, the filter, and the host audio buffer statistics.
//
// Numeric fields honour the shared format setting (C64Controller::format).
// The live waveform visualization is drawn separately by SiC64Waveform.
//
// The shared active flag, tick throttle and beam-position readout come from
// SiC64InspectorController.
//

class C64Controller;

class SiC64SIDController : public SiC64InspectorController {

    Q_OBJECT

    int m_selectedSID = 0;

    // 0 = combined audio buffer, 1 = the selected SID's output (drives
    // SiC64Waveform's source)
    int m_waveformSource = 0;

    QVariantList m_voices;

    // Raw ints so the panel's SiNumberView can format them per the shared
    // display format.
    int m_volume = 0, m_potX = 0, m_potY = 0;

    int m_filterCutoff = 0, m_filterResonance = 0;
    int m_filterType = 0;
    bool m_filter1 = false, m_filter2 = false, m_filter3 = false;

    int m_audioFill = 0;
    QString m_audioFillText, m_underflows, m_overflows;

  public:

    explicit SiC64SIDController(C64Controller *parent = nullptr);

    Q_PROPERTY(int selectedSID READ selectedSID WRITE setSelectedSID NOTIFY sidChanged)
    Q_PROPERTY(int waveformSource READ waveformSource WRITE setWaveformSource NOTIFY sidChanged)

    Q_PROPERTY(QVariantList voices READ voices NOTIFY sidChanged)

    Q_PROPERTY(int volume READ volume NOTIFY sidChanged)
    Q_PROPERTY(int potX READ potX NOTIFY sidChanged)
    Q_PROPERTY(int potY READ potY NOTIFY sidChanged)

    Q_PROPERTY(int filterCutoff READ filterCutoff NOTIFY sidChanged)
    Q_PROPERTY(int filterResonance READ filterResonance NOTIFY sidChanged)
    Q_PROPERTY(bool filterLowPass READ filterLowPass NOTIFY sidChanged)
    Q_PROPERTY(bool filterBandPass READ filterBandPass NOTIFY sidChanged)
    Q_PROPERTY(bool filterHighPass READ filterHighPass NOTIFY sidChanged)
    Q_PROPERTY(bool filter1 READ filter1 NOTIFY sidChanged)
    Q_PROPERTY(bool filter2 READ filter2 NOTIFY sidChanged)
    Q_PROPERTY(bool filter3 READ filter3 NOTIFY sidChanged)

    Q_PROPERTY(int audioFill READ audioFill NOTIFY sidChanged)
    Q_PROPERTY(QString audioFillText READ audioFillText NOTIFY sidChanged)
    Q_PROPERTY(QString underflows READ underflows NOTIFY sidChanged)
    Q_PROPERTY(QString overflows READ overflows NOTIFY sidChanged)

    int selectedSID() const { return m_selectedSID; }
    void setSelectedSID(int value);
    int waveformSource() const { return m_waveformSource; }
    void setWaveformSource(int value);

  protected:

    void refreshData() override;

  private:

    QVariantList voices() const { return m_voices; }
    int volume() const { return m_volume; }
    int potX() const { return m_potX; }
    int potY() const { return m_potY; }
    int filterCutoff() const { return m_filterCutoff; }
    int filterResonance() const { return m_filterResonance; }
    bool filterLowPass() const { return m_filterType & 0x10; }
    bool filterBandPass() const { return m_filterType & 0x20; }
    bool filterHighPass() const { return m_filterType & 0x40; }
    bool filter1() const { return m_filter1; }
    bool filter2() const { return m_filter2; }
    bool filter3() const { return m_filter3; }
    int audioFill() const { return m_audioFill; }
    QString audioFillText() const { return m_audioFillText; }
    QString underflows() const { return m_underflows; }
    QString overflows() const { return m_overflows; }

  signals:

    void sidChanged();
};
