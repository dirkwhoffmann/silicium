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
// Agnus inspector controller -- port of vAmiga's own GUI/Inspector/
// AgnusPanel.swift. Exposes the beam position, DMACON/BPLCON0/FMODE and the
// DMA timing registers, the four modulo pairs, and every DMA channel's
// pointer register plus its "is this channel actually granted a bus cycle
// right now" enable flag -- field for field off AgnusInfo, the same way the
// Swift reference's refreshAgnus() reads agnusInfo.
//
// Three departures from the Swift reference, none of which had an AgnusInfo
// field to read before this controller:
//
//  - FMODE (the AGA bitplane/sprite DMA fetch-mode register) is new -- the
//    Swift reference predates AGA support having its own settled UI and
//    never grew a field for it. See AgnusInfo::fmode.
//  - DIWHIGH (the ECS/AGA extended display-window register, supplying the
//    extra high bits DIWSTRT/DIWSTOP alone can't reach) is new too. See
//    AgnusInfo::diwhigh, read from Sequencer::diwhigh the same way
//    diwstrt/diwstop already are.
//  - Bitplane DMA covers all eight AGA bitplane pointers/enables (bplPt(6)
//    and bplPt(7), i.e. BPL7PT/BPL8PT), not just the six OCS/ECS ones the
//    Swift reference has fields for. AgnusInfo::bplpt was already sized 8,
//    but Agnus::cacheInfo() only ever filled the first 6 -- fixed alongside
//    this controller.
//
// Per-channel "enabled" flags are computed the same way the Swift reference
// does: DMAEN (DMACON bit 9) gates every category, and each category bit
// then gates that category's channels. Bitplane channels are further gated
// by the number of bitplanes in use (DeniseInfo::bpu, which already accounts
// for AGA's extra BPU bit -- see Denise::bpu()); sprite channels all share
// a single SPREN-derived flag, since the hardware doesn't grant them
// individually.
//
// Pointer/enable arrays (bitplanes, audio, blitter, sprites) are exposed via
// Q_INVOKABLE accessors rather than named properties per channel, the same
// way SiAmBlitterController's minterm rows and SiAmInfoController's CPU
// register file are.
//

class SiAmController;

class SiAmAgnusController : public SiAmInspectorController {

    Q_OBJECT

    // Beam position
    int m_vpos = 0, m_hpos = 0;

    // DMA control / display timing
    int m_dmacon = 0, m_bplcon0 = 0, m_fmode = 0;
    int m_ddfstrt = 0, m_ddfstop = 0, m_diwstrt = 0, m_diwstop = 0, m_diwhigh = 0;

    // Modulos
    int m_bltamod = 0, m_bltbmod = 0, m_bltcmod = 0, m_bltdmod = 0;
    int m_bpl1mod = 0, m_bpl2mod = 0;

    // Copper / Disk
    int m_coppc = 0, m_dskpt = 0;
    bool m_copEnabled = false, m_dskEnabled = false;

    // Blitter DMA
    bool m_bltPri = false, m_bls = false;

    // Bitplane / Audio / Blitter / Sprite channels
    int m_bplPt[8] = {};
    bool m_bplEnabled[8] = {};
    int m_audPt[4] = {}, m_audLc[4] = {};
    bool m_audEnabled[4] = {};
    int m_bltPt[4] = {};
    bool m_bltEnabled[4] = {};
    int m_sprPt[8] = {};
    bool m_sprEnabled = false;

  public:

    explicit SiAmAgnusController(SiAmController *parent = nullptr);

    Q_PROPERTY(int vpos READ vpos NOTIFY agnusChanged)
    Q_PROPERTY(int hpos READ hpos NOTIFY agnusChanged)

    Q_PROPERTY(int dmacon READ dmacon NOTIFY agnusChanged)
    Q_PROPERTY(int bplcon0 READ bplcon0 NOTIFY agnusChanged)
    Q_PROPERTY(int fmode READ fmode NOTIFY agnusChanged)
    Q_PROPERTY(int ddfstrt READ ddfstrt NOTIFY agnusChanged)
    Q_PROPERTY(int ddfstop READ ddfstop NOTIFY agnusChanged)
    Q_PROPERTY(int diwstrt READ diwstrt NOTIFY agnusChanged)
    Q_PROPERTY(int diwstop READ diwstop NOTIFY agnusChanged)
    Q_PROPERTY(int diwhigh READ diwhigh NOTIFY agnusChanged)

    Q_PROPERTY(int bltamod READ bltamod NOTIFY agnusChanged)
    Q_PROPERTY(int bltbmod READ bltbmod NOTIFY agnusChanged)
    Q_PROPERTY(int bltcmod READ bltcmod NOTIFY agnusChanged)
    Q_PROPERTY(int bltdmod READ bltdmod NOTIFY agnusChanged)
    Q_PROPERTY(int bpl1mod READ bpl1mod NOTIFY agnusChanged)
    Q_PROPERTY(int bpl2mod READ bpl2mod NOTIFY agnusChanged)

    Q_PROPERTY(int coppc READ coppc NOTIFY agnusChanged)
    Q_PROPERTY(bool copEnabled READ copEnabled NOTIFY agnusChanged)
    Q_PROPERTY(int dskpt READ dskpt NOTIFY agnusChanged)
    Q_PROPERTY(bool dskEnabled READ dskEnabled NOTIFY agnusChanged)

    Q_PROPERTY(bool bltPri READ bltPri NOTIFY agnusChanged)
    Q_PROPERTY(bool bls READ bls NOTIFY agnusChanged)

    Q_PROPERTY(bool sprEnabled READ sprEnabled NOTIFY agnusChanged)

    // Bitplane channel n (0..7 == BPL1PT..BPL8PT)
    Q_INVOKABLE int bplPt(int n) const { return n >= 0 && n < 8 ? m_bplPt[n] : 0; }
    Q_INVOKABLE bool bplEnabled(int n) const { return n >= 0 && n < 8 && m_bplEnabled[n]; }

    // Audio channel n (0..3)
    Q_INVOKABLE int audPt(int n) const { return n >= 0 && n < 4 ? m_audPt[n] : 0; }
    Q_INVOKABLE int audLc(int n) const { return n >= 0 && n < 4 ? m_audLc[n] : 0; }
    Q_INVOKABLE bool audEnabled(int n) const { return n >= 0 && n < 4 && m_audEnabled[n]; }

    // Blitter channel n (0..3 == A..D)
    Q_INVOKABLE int bltPt(int n) const { return n >= 0 && n < 4 ? m_bltPt[n] : 0; }
    Q_INVOKABLE bool bltEnabled(int n) const { return n >= 0 && n < 4 && m_bltEnabled[n]; }

    // Sprite channel n (0..7); all share sprEnabled (see the class comment)
    Q_INVOKABLE int sprPt(int n) const { return n >= 0 && n < 8 ? m_sprPt[n] : 0; }

  protected:

    void refreshData() override;

  private:

    int vpos() const { return m_vpos; }
    int hpos() const { return m_hpos; }

    int dmacon() const { return m_dmacon; }
    int bplcon0() const { return m_bplcon0; }
    int fmode() const { return m_fmode; }
    int ddfstrt() const { return m_ddfstrt; }
    int ddfstop() const { return m_ddfstop; }
    int diwstrt() const { return m_diwstrt; }
    int diwstop() const { return m_diwstop; }
    int diwhigh() const { return m_diwhigh; }

    int bltamod() const { return m_bltamod; }
    int bltbmod() const { return m_bltbmod; }
    int bltcmod() const { return m_bltcmod; }
    int bltdmod() const { return m_bltdmod; }
    int bpl1mod() const { return m_bpl1mod; }
    int bpl2mod() const { return m_bpl2mod; }

    int coppc() const { return m_coppc; }
    bool copEnabled() const { return m_copEnabled; }
    int dskpt() const { return m_dskpt; }
    bool dskEnabled() const { return m_dskEnabled; }

    bool bltPri() const { return m_bltPri; }
    bool bls() const { return m_bls; }

    bool sprEnabled() const { return m_sprEnabled; }

  signals:

    void agnusChanged();
};
