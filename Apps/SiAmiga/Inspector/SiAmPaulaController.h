// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#pragma once

#include "SiAmInspectorController.h"

//
// Paula inspector controller -- port of vAmiga's own GUI/Inspector/
// PaulaPanel.swift (there is no C64 counterpart; Paula bundles the
// Amiga's interrupt controller, floppy disk controller and the four audio
// DMA state machines, none of which map onto anything the C64 core has).
// Exposes:
//
//   - The interrupt controller: INTENA/INTREQ, decoded bit by bit (see
//     intenaBit()/intreqBit()/intBitLabel()).
//   - The disk controller: selected drive, DMA state, DSKLEN/DSKBYTR/
//     ADKCON decoded into their individual flags, the sync word, and the
//     FIFO buffer -- straight off DiskControllerInfo, which sits behind
//     PaulaAPI::diskController in the core (core().paula.diskController),
//     matching the Swift reference's own emu.diskController even though
//     that reads as a separate subsystem there.
//   - Audio: AUDxLEN/AUDxPER/AUDxVOL/AUDxDAT per channel (see
//     audioLen()/audioPer()/audioVol()/audioDat()), plus each channel's
//     DMA state-machine display state (see displayState()) -- a small
//     animation-like value derived from the channel's real hardware state
//     across successive refreshes, not read directly off it. That
//     transition table (0 -> 1 or 2 depending on whether DMA is active,
//     1 -> 5, 5 -> 2, 2 -> 3, 3 -> back to 2 or 0) is copied verbatim from
//     the Swift reference's assignImage(), which drives which of five
//     template images (state0Template.pdf .. state5Template.pdf, in
//     Resources/Assets.xcassets/Audio) a state-machine diagram button
//     shows; SiAmPaulaPanel.qml draws the same five-node diagram inline
//     with QtQuick.Shapes instead of five bitmap assets, but the state
//     numbering and transition logic driving which node lights up is
//     identical.
//
// Unlike SiAmBlitterController, numeric fields here DO follow the shared
// hex/decimal display setting (see SiAmInspectorController's hex/padded)
// the way SiAmCIAController/SiAmCopperController's do -- nothing on this
// panel has Blitter's "must read as a raw bit pattern" argument for a
// fixed base.
//
// The shared active flag, tick throttle and beam-position readout come
// from SiAmInspectorController.
//

class SiAmController;

class SiAmPaulaController : public SiAmInspectorController {

    Q_OBJECT

    // Interrupt controller
    int m_intena = 0, m_intreq = 0;

    // Disk controller
    int m_selectedDrive = 0;
    QString m_dcStateText;
    int m_dsklen = 0, m_dskbytr = 0, m_dsksync = 0, m_adkcon = 0;
    int m_fifoCount = 0;
    int m_fifo[6] = {};

    // Audio: AUDxLEN/AUDxPER/AUDxVOL/AUDxDAT per channel (0..3)
    int m_audLen[4] = {}, m_audPer[4] = {}, m_audVol[4] = {}, m_audDat[4] = {};

    // Per-channel DMA state-machine display state (0, 1, 2, 3 or 5 -- see
    // the class comment). Persists across refreshes; only refreshData()
    // advances it.
    int m_displayState[4] = {};

  public:

    explicit SiAmPaulaController(SiAmController *parent = nullptr);

    Q_PROPERTY(int intena READ intena NOTIFY paulaChanged)
    Q_PROPERTY(int intreq READ intreq NOTIFY paulaChanged)

    // Bit 'n' (0..14) of INTENA/INTREQ, and that bit's hardware name
    // (TBE=0, DSKBLK=1, SOFT=2, PORTS=3, COPER=4, VERTB=5, BLIT=6,
    // AUD0=7, AUD1=8, AUD2=9, AUD3=10, RBF=11, DSKSYN=12, EXTER=13,
    // INTEN=14 -- the master-enable bit, meaningful only in INTENA).
    Q_INVOKABLE bool intenaBit(int n) const { return n >= 0 && n < 15 && (m_intena & (1 << n)); }
    Q_INVOKABLE bool intreqBit(int n) const { return n >= 0 && n < 15 && (m_intreq & (1 << n)); }
    Q_INVOKABLE QString intBitLabel(int n) const;

    Q_PROPERTY(int selectedDrive READ selectedDrive NOTIFY paulaChanged)
    Q_PROPERTY(QString dcStateText READ dcStateText NOTIFY paulaChanged)

    Q_PROPERTY(int dsklen READ dsklen NOTIFY paulaChanged)
    Q_PROPERTY(bool dmaen READ dmaen NOTIFY paulaChanged)
    Q_PROPERTY(bool write READ write NOTIFY paulaChanged)

    Q_PROPERTY(int dskbytr READ dskbytr NOTIFY paulaChanged)
    Q_PROPERTY(bool byteready READ byteready NOTIFY paulaChanged)
    Q_PROPERTY(bool dmaon READ dmaon NOTIFY paulaChanged)
    Q_PROPERTY(bool diskwrite READ diskwrite NOTIFY paulaChanged)
    Q_PROPERTY(bool wordequal READ wordequal NOTIFY paulaChanged)

    Q_PROPERTY(int adkconHi READ adkconHi NOTIFY paulaChanged)
    Q_PROPERTY(bool precomp1 READ precomp1 NOTIFY paulaChanged)
    Q_PROPERTY(bool precomp0 READ precomp0 NOTIFY paulaChanged)
    Q_PROPERTY(bool mfmprec READ mfmprec NOTIFY paulaChanged)
    Q_PROPERTY(bool uartbrk READ uartbrk NOTIFY paulaChanged)
    Q_PROPERTY(bool wordsync READ wordsync NOTIFY paulaChanged)
    Q_PROPERTY(bool msbsync READ msbsync NOTIFY paulaChanged)
    Q_PROPERTY(bool fast READ fast NOTIFY paulaChanged)

    Q_PROPERTY(int dsksync READ dsksync NOTIFY paulaChanged)
    Q_PROPERTY(bool dsksyncWarning READ dsksyncWarning NOTIFY paulaChanged)

    // FIFO byte 'i' (0..5), formatted, or "" once i reaches fifoCount --
    // mirrors the Swift reference's cascading-fallthrough show/clear logic.
    Q_PROPERTY(int fifoCount READ fifoCount NOTIFY paulaChanged)
    Q_INVOKABLE QString fifoAt(int i) const;

    // Audio channel 'ch' (0..3) registers.
    Q_INVOKABLE int audioLen(int ch) const { return ch >= 0 && ch < 4 ? m_audLen[ch] : 0; }
    Q_INVOKABLE int audioPer(int ch) const { return ch >= 0 && ch < 4 ? m_audPer[ch] : 0; }
    Q_INVOKABLE int audioVol(int ch) const { return ch >= 0 && ch < 4 ? m_audVol[ch] : 0; }
    Q_INVOKABLE int audioDat(int ch) const { return ch >= 0 && ch < 4 ? m_audDat[ch] : 0; }

    // Audio channel 'ch''s DMA state-machine display state -- see the
    // class comment.
    Q_INVOKABLE int displayState(int ch) const { return ch >= 0 && ch < 4 ? m_displayState[ch] : 0; }

  protected:

    void refreshData() override;

  private:

    int intena() const { return m_intena; }
    int intreq() const { return m_intreq; }

    int selectedDrive() const { return m_selectedDrive; }
    QString dcStateText() const { return m_dcStateText; }

    int dsklen() const { return m_dsklen; }
    bool dmaen() const { return m_dsklen & 0x8000; }
    bool write() const { return m_dsklen & 0x4000; }

    int dskbytr() const { return m_dskbytr; }
    bool byteready() const { return m_dskbytr & 0x8000; }
    bool dmaon() const { return m_dskbytr & 0x4000; }
    bool diskwrite() const { return m_dskbytr & 0x2000; }
    bool wordequal() const { return m_dskbytr & 0x1000; }

    int adkconHi() const { return (m_adkcon >> 8) & 0xFF; }
    bool precomp1() const { return m_adkcon & 0x4000; }
    bool precomp0() const { return m_adkcon & 0x2000; }
    bool mfmprec() const { return m_adkcon & 0x1000; }
    bool uartbrk() const { return m_adkcon & 0x0800; }
    bool wordsync() const { return m_adkcon & 0x0400; }
    bool msbsync() const { return m_adkcon & 0x0200; }
    bool fast() const { return m_adkcon & 0x0100; }

    int dsksync() const { return m_dsksync; }
    bool dsksyncWarning() const { return m_dsksync != 0x4489; }

    int fifoCount() const { return m_fifoCount; }

  signals:

    void paulaChanged();
};
