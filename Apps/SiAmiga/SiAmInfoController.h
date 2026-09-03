// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#pragma once

#include "Controller.h"
#include "VAmiga.h"
#include "utl/chrono/Time.h"

//
// Port of SiC64InfoController: the single, shared proxy to the emulator's
// info structs. Panels and the status bar read their data from here rather
// than querying the core individually -- see SiAmStatusbar.qml's own
// comment on the Timer-based polling hack it used before this existed, and
// which requestUpdate()/infoChanged() below are meant to replace.
//
// Freshness is demand-driven and coalesced exactly as in the C64 version:
// requestUpdate() asks for data no older than a given interval, and only
// re-samples a component whose own cached copy has actually aged past it,
// so several open inspectors (or a statusbar tick) never trigger redundant
// core queries. refresh() -- called from SiAmController::update() once
// message dispatch marks something dirty -- forces an immediate sample of
// everything.
//
// Component coverage mirrors C64's shape (CPU + machine status + per-drive
// state get real Q_PROPERTYs; the rest are cached structs only, for a
// future panel's C++ side to read via the accessors below) rather than its
// exact subsystem list -- the Amiga's chipset doesn't map onto
// CPU/CIA/SID/VIC/MEM/DRIVE/DATASETTE/CARTRIDGE at all. What's here instead:
// CPU, CIA (both chips), AGNUS, DENISE, PAULA, MEMORY, DRIVE (df0..df3),
// HD (hd0..hd3), AMIGA (the frame/vpos/hpos beam position, C64Info's
// counterpart). No DATASETTE or CARTRIDGE component -- an Amiga has
// neither -- and no server-state properties yet, since vAmiga's
// RemoteServers haven't been ported to Silicium (see the RemoteServers
// port plan) the way C64's have.
//

class SiAmController;

class SiAmInfoController : public Controller {

    Q_OBJECT

    SiAmController *parent = nullptr;

    // Cached copies of the emulator's info structs. CIA (both chips) and
    // the four floppy/hard drives are indexed; panels pick the one their
    // selector points at.
    vamiga::CPUInfo m_cpuInfo = { };
    vamiga::CIAInfo m_ciaInfo[2] = { };
    vamiga::CIAMetrics m_ciaMetrics[2] = { };
    vamiga::AgnusInfo m_agnusInfo = { };
    vamiga::DeniseInfo m_deniseInfo = { };
    vamiga::PaulaInfo m_paulaInfo = { };
    vamiga::StateMachineInfo m_audioInfo[4] = { };
    vamiga::DiskControllerInfo m_diskControllerInfo = { };
    vamiga::MemInfo m_memInfo = { };
    vamiga::MemConfig m_memConfig = { };
    vamiga::FloppyDriveInfo m_driveInfo[4] = { };
    vamiga::HardDriveInfo m_hdInfo[4] = { };
    vamiga::AmigaInfo m_amigaInfo = { };
    vamiga::CopperInfo m_copperInfo = { };
    vamiga::BlitterInfo m_blitterInfo = { };

    // Number of samplable components (see the Component flags below).
    static constexpr int NumComponents = 11;

    // Per-component wall-clock time of the last sample. Indexed by the bit
    // position of the Component flags below, so each subsystem is throttled
    // independently -- one panel's grab never resets another's timer.
    utl::Time m_lastUpdate[NumComponents] = { };

  public:

    explicit SiAmInfoController(SiAmController *parent = nullptr);

    // Which emulator subsystems to sample. Bit flags so a caller can request
    // several at once.
    enum Component {

        CPU    = 1 << 0,
        CIA    = 1 << 1,
        AGNUS  = 1 << 2,
        DENISE = 1 << 3,
        PAULA  = 1 << 4,
        MEMORY = 1 << 5,
        DRIVE  = 1 << 6,
        HD     = 1 << 7,
        AMIGA  = 1 << 8,
        COPPER = 1 << 9,
        BLITTER = 1 << 10,
        ALL    = CPU | CIA | AGNUS | DENISE | PAULA | MEMORY | DRIVE | HD | AMIGA | COPPER | BLITTER
    };

    // Asks for the given 'components' to be no older than 'interval'
    // seconds. Each requested component is re-sampled only if its own copy
    // has aged past the interval -- see the class comment.
    void requestUpdate(int components, double interval);

    // Immediately re-samples every subsystem (event-driven; called on
    // info-dirty).
    void refresh();

    // Cached info accessors, for other controllers'/panels' C++ side.
    const vamiga::CPUInfo &cpuInfo() const { return m_cpuInfo; }
    const vamiga::CIAInfo &ciaInfo(int nr) const { return m_ciaInfo[nr]; }
    const vamiga::CIAMetrics &ciaMetrics(int nr) const { return m_ciaMetrics[nr]; }
    const vamiga::AgnusInfo &agnusInfo() const { return m_agnusInfo; }
    const vamiga::DeniseInfo &deniseInfo() const { return m_deniseInfo; }
    const vamiga::PaulaInfo &paulaInfo() const { return m_paulaInfo; }
    const vamiga::StateMachineInfo &audioInfo(int nr) const { return m_audioInfo[nr]; }
    const vamiga::DiskControllerInfo &diskControllerInfo() const { return m_diskControllerInfo; }
    const vamiga::MemInfo &memInfo() const { return m_memInfo; }
    const vamiga::MemConfig &memConfig() const { return m_memConfig; }
    const vamiga::FloppyDriveInfo &driveInfo(int nr) const { return m_driveInfo[nr]; }
    const vamiga::HardDriveInfo &hdInfo(int nr) const { return m_hdInfo[nr]; }
    const vamiga::AmigaInfo &amigaInfo() const { return m_amigaInfo; }
    const vamiga::CopperInfo &copperInfo() const { return m_copperInfo; }
    const vamiga::BlitterInfo &blitterInfo() const { return m_blitterInfo; }

    //
    // CPU (68000)
    //

    Q_PROPERTY(int pc READ pc NOTIFY infoChanged)
    Q_PROPERTY(int sr READ sr NOTIFY infoChanged)
    Q_PROPERTY(int ipl READ ipl NOTIFY infoChanged)
    Q_PROPERTY(bool halt READ halt NOTIFY infoChanged)

    Q_PROPERTY(bool flagX READ flagX NOTIFY infoChanged)
    Q_PROPERTY(bool flagN READ flagN NOTIFY infoChanged)
    Q_PROPERTY(bool flagZ READ flagZ NOTIFY infoChanged)
    Q_PROPERTY(bool flagV READ flagV NOTIFY infoChanged)
    Q_PROPERTY(bool flagC READ flagC NOTIFY infoChanged)

    // Data/address register file. Q_INVOKABLE rather than 16 named
    // properties (d0..d7/a0..a7) -- a panel iterates these, it doesn't bind
    // one QML Text per register the way the CPU flags above are bound.
    Q_INVOKABLE int dReg(int n) const { return (int)m_cpuInfo.d[n]; }
    Q_INVOKABLE int aReg(int n) const { return (int)m_cpuInfo.a[n]; }

    //
    // Machine status
    //

    Q_PROPERTY(bool tracking READ tracking NOTIFY infoChanged)
    Q_PROPERTY(bool mute READ mute NOTIFY infoChanged)
    Q_PROPERTY(bool warping READ warping NOTIFY infoChanged)

    //
    // Drives (df0..df3)
    //

    Q_PROPERTY(int track0 READ track0 NOTIFY infoChanged)
    Q_PROPERTY(bool spinning0 READ spinning0 NOTIFY infoChanged)
    Q_PROPERTY(bool writing0 READ writing0 NOTIFY infoChanged)
    Q_PROPERTY(bool hasDisk0 READ hasDisk0 NOTIFY infoChanged)
    Q_PROPERTY(bool hasModifiedDisk0 READ hasModifiedDisk0 NOTIFY infoChanged)
    Q_PROPERTY(bool hasProtectedDisk0 READ hasProtectedDisk0 NOTIFY infoChanged)

    Q_PROPERTY(int track1 READ track1 NOTIFY infoChanged)
    Q_PROPERTY(bool spinning1 READ spinning1 NOTIFY infoChanged)
    Q_PROPERTY(bool writing1 READ writing1 NOTIFY infoChanged)
    Q_PROPERTY(bool hasDisk1 READ hasDisk1 NOTIFY infoChanged)
    Q_PROPERTY(bool hasModifiedDisk1 READ hasModifiedDisk1 NOTIFY infoChanged)
    Q_PROPERTY(bool hasProtectedDisk1 READ hasProtectedDisk1 NOTIFY infoChanged)

    Q_PROPERTY(int track2 READ track2 NOTIFY infoChanged)
    Q_PROPERTY(bool spinning2 READ spinning2 NOTIFY infoChanged)
    Q_PROPERTY(bool writing2 READ writing2 NOTIFY infoChanged)
    Q_PROPERTY(bool hasDisk2 READ hasDisk2 NOTIFY infoChanged)
    Q_PROPERTY(bool hasModifiedDisk2 READ hasModifiedDisk2 NOTIFY infoChanged)
    Q_PROPERTY(bool hasProtectedDisk2 READ hasProtectedDisk2 NOTIFY infoChanged)

    Q_PROPERTY(int track3 READ track3 NOTIFY infoChanged)
    Q_PROPERTY(bool spinning3 READ spinning3 NOTIFY infoChanged)
    Q_PROPERTY(bool writing3 READ writing3 NOTIFY infoChanged)
    Q_PROPERTY(bool hasDisk3 READ hasDisk3 NOTIFY infoChanged)
    Q_PROPERTY(bool hasModifiedDisk3 READ hasModifiedDisk3 NOTIFY infoChanged)
    Q_PROPERTY(bool hasProtectedDisk3 READ hasProtectedDisk3 NOTIFY infoChanged)

  private:

    // Samples the given single component's structs from the core (no signal).
    void grab(Component component);

    // CPU registers -- raw ints so consumers can format them per the shared
    // display setting, matching SiC64InfoController's own CPU accessors.
    int pc() const { return (int)m_cpuInfo.pc0; }
    int sr() const { return m_cpuInfo.sr; }
    int ipl() const { return m_cpuInfo.ipl; }
    bool halt() const { return m_cpuInfo.halt; }

    // Status flags, decoded from the 68000 status register's low byte
    // (the condition code register): X N Z V C, bit 4 down to bit 0.
    bool flagX() const { return m_cpuInfo.sr & 0x10; }
    bool flagN() const { return m_cpuInfo.sr & 0x08; }
    bool flagZ() const { return m_cpuInfo.sr & 0x04; }
    bool flagV() const { return m_cpuInfo.sr & 0x02; }
    bool flagC() const { return m_cpuInfo.sr & 0x01; }

    // Machine status. These read live core state, so they aren't inline.
    // All change on info-dirty events, which drive infoChanged.
    bool tracking() const;
    bool mute() const;
    bool warping() const;

    // Drive 0..3 state, read from the cached FloppyDriveInfo. 'track'
    // combines cylinder and head the same way SiAmController::driveTrack()
    // already does.
    int track0() const { return (int)m_driveInfo[0].head.track(); }
    bool spinning0() const { return m_driveInfo[0].motor; }
    bool writing0() const { return m_driveInfo[0].writing; }
    bool hasDisk0() const { return m_driveInfo[0].hasDisk; }
    bool hasModifiedDisk0() const { return m_driveInfo[0].hasModifiedDisk; }
    bool hasProtectedDisk0() const { return m_driveInfo[0].hasProtectedDisk; }

    int track1() const { return (int)m_driveInfo[1].head.track(); }
    bool spinning1() const { return m_driveInfo[1].motor; }
    bool writing1() const { return m_driveInfo[1].writing; }
    bool hasDisk1() const { return m_driveInfo[1].hasDisk; }
    bool hasModifiedDisk1() const { return m_driveInfo[1].hasModifiedDisk; }
    bool hasProtectedDisk1() const { return m_driveInfo[1].hasProtectedDisk; }

    int track2() const { return (int)m_driveInfo[2].head.track(); }
    bool spinning2() const { return m_driveInfo[2].motor; }
    bool writing2() const { return m_driveInfo[2].writing; }
    bool hasDisk2() const { return m_driveInfo[2].hasDisk; }
    bool hasModifiedDisk2() const { return m_driveInfo[2].hasModifiedDisk; }
    bool hasProtectedDisk2() const { return m_driveInfo[2].hasProtectedDisk; }

    int track3() const { return (int)m_driveInfo[3].head.track(); }
    bool spinning3() const { return m_driveInfo[3].motor; }
    bool writing3() const { return m_driveInfo[3].writing; }
    bool hasDisk3() const { return m_driveInfo[3].hasDisk; }
    bool hasModifiedDisk3() const { return m_driveInfo[3].hasModifiedDisk; }
    bool hasProtectedDisk3() const { return m_driveInfo[3].hasProtectedDisk; }

  signals:

    void infoChanged();
};
