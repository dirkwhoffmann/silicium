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
#include "VirtualC64Types.h"
#include "utl/chrono/Time.h"
#include <QUrl>

//
// Stand-in for Silicium's C64InfoController. Acts as the single, shared proxy
// to the emulator's info structs: the inspectors read their data from here
// rather than querying C64Controller::core() individually.
//
// Freshness is demand-driven and coalesced. An inspector calls requestUpdate()
// while it's on screen to ask for data no older than a given interval; the
// controller itself decides when to actually sample the core, throttling so
// that several open inspectors don't each trigger a separate query. refresh()
// -- called by C64Controller::update() whenever process() marks the info
// state dirty -- forces an immediate, event-driven sample.
//

class C64Controller;

class SiC64InfoController : public Controller {

    Q_OBJECT

    C64Controller *parent = nullptr;

    // Cached copies of the emulator's info structs. CIA (both chips) and SID
    // (all four) are indexed; the panels pick the one their selector points
    // at. Stats live alongside the info they belong with.
    vc64::CPUInfo m_cpuInfo = { };
    vc64::CIAInfo m_ciaInfo[2] = { };
    vc64::CIAStats m_ciaStats[2] = { };
    vc64::SIDInfo m_sidInfo[4] = { };
    vc64::AudioPortStats m_audioStats = { };
    vc64::C64Info m_c64Info = { };
    vc64::VICIIInfo m_vicInfo = { };
    vc64::SpriteInfo m_spriteInfo[8] = { };
    uint32_t m_vicColor[16] = { };
    vc64::MemInfo m_memInfo = { };
    vc64::DriveInfo m_driveInfo[2] = { };
    vc64::DatasetteInfo m_datasetteInfo = { };
    vc64::CartridgeInfo m_cartridgeInfo = { };
    // Whether a cartridge is attached -- derived from the cartridge traits
    // (not part of CartridgeInfo), sampled alongside it.
    bool m_cartridgeAttached = false;

    // Number of samplable components (see the Component flags below).
    static constexpr int NumComponents = 10;

    // Per-component wall-clock time of the last sample. Indexed by the bit
    // position of the Component flags below, so each subsystem is throttled
    // independently -- one panel's grab never resets another's timer.
    utl::Time m_lastUpdate[NumComponents] = { };

  public:

    explicit SiC64InfoController(C64Controller *parent = nullptr);

    // Which emulator subsystems to sample. Bit flags so a caller can request
    // several at once (e.g. the SID panel wants SID | AUDIO).
    enum Component {

        CPU       = 1 << 0,
        CIA       = 1 << 1,
        SID       = 1 << 2,
        AUDIO     = 1 << 3,
        C64       = 1 << 4,
        VIC       = 1 << 5,
        MEM       = 1 << 6,
        DRIVE     = 1 << 7,
        DATASETTE = 1 << 8,
        CARTRIDGE = 1 << 9,
        ALL       = CPU | CIA | SID | AUDIO | C64 | VIC | MEM | DRIVE | DATASETTE | CARTRIDGE
    };

    // Asks for the given 'components' to be no older than 'interval' seconds.
    // Each requested component is re-sampled only if its own copy has aged
    // past the interval, so callers can invoke this freely (every frame, from
    // every open inspector) without causing redundant queries, and a panel
    // interested in one subsystem doesn't drag in the others. Reading the
    // accessors below afterwards returns the freshest data.
    void requestUpdate(int components, double interval);

    // Immediately re-samples every subsystem (event-driven; called on
    // info-dirty).
    void refresh();

    // Cached info accessors.
    const vc64::CPUInfo &cpuInfo() const { return m_cpuInfo; }
    const vc64::CIAInfo &ciaInfo(int nr) const { return m_ciaInfo[nr]; }
    const vc64::CIAStats &ciaStats(int nr) const { return m_ciaStats[nr]; }
    const vc64::SIDInfo &sidInfo(int nr) const { return m_sidInfo[nr]; }
    const vc64::AudioPortStats &audioStats() const { return m_audioStats; }
    const vc64::C64Info &c64Info() const { return m_c64Info; }
    const vc64::VICIIInfo &vicInfo() const { return m_vicInfo; }
    const vc64::SpriteInfo &spriteInfo(int nr) const { return m_spriteInfo[nr]; }
    uint32_t vicColor(int nr) const { return m_vicColor[nr]; }
    const vc64::MemInfo &memInfo() const { return m_memInfo; }
    const vc64::DriveInfo &driveInfo(int nr) const { return m_driveInfo[nr]; }
    const vc64::DatasetteInfo &datasetteInfo() const { return m_datasetteInfo; }
    const vc64::CartridgeInfo &cartridgeInfo() const { return m_cartridgeInfo; }

    //
    // CPU
    //

    Q_PROPERTY(int pc READ pc NOTIFY infoChanged)
    Q_PROPERTY(int sp READ sp NOTIFY infoChanged)
    Q_PROPERTY(int a READ a NOTIFY infoChanged)
    Q_PROPERTY(int x READ x NOTIFY infoChanged)
    Q_PROPERTY(int y READ y NOTIFY infoChanged)
    Q_PROPERTY(int portReg READ portReg NOTIFY infoChanged)
    Q_PROPERTY(int portDir READ portDir NOTIFY infoChanged)
    Q_PROPERTY(bool pcWarning READ pcWarning NOTIFY infoChanged)

    Q_PROPERTY(bool flagN READ flagN NOTIFY infoChanged)
    Q_PROPERTY(bool flagV READ flagV NOTIFY infoChanged)
    Q_PROPERTY(bool flagB READ flagB NOTIFY infoChanged)
    Q_PROPERTY(bool flagD READ flagD NOTIFY infoChanged)
    Q_PROPERTY(bool flagI READ flagI NOTIFY infoChanged)
    Q_PROPERTY(bool flagZ READ flagZ NOTIFY infoChanged)
    Q_PROPERTY(bool flagC READ flagC NOTIFY infoChanged)

    Q_PROPERTY(bool irq READ irq NOTIFY infoChanged)
    Q_PROPERTY(bool irqCIA READ irqCIA NOTIFY infoChanged)
    Q_PROPERTY(bool irqVIC READ irqVIC NOTIFY infoChanged)
    Q_PROPERTY(bool irqEXP READ irqEXP NOTIFY infoChanged)
    Q_PROPERTY(bool nmi READ nmi NOTIFY infoChanged)
    Q_PROPERTY(bool nmiCIA READ nmiCIA NOTIFY infoChanged)
    Q_PROPERTY(bool nmiKBD READ nmiKBD NOTIFY infoChanged)
    Q_PROPERTY(bool nmiEXP READ nmiEXP NOTIFY infoChanged)
    Q_PROPERTY(bool rdy READ rdy NOTIFY infoChanged)
    Q_PROPERTY(bool jammed READ jammed NOTIFY infoChanged)

    //
    // Machine status (shown as statusbar pictograms)
    //

    // Worst state across all remote servers (same SrvState encoding as the
    // per-server properties below), which colors the statusbar icon.
    Q_PROPERTY(int serverState READ serverState NOTIFY infoChanged)
    Q_PROPERTY(bool tracking READ tracking NOTIFY infoChanged)
    Q_PROPERTY(bool mute READ mute NOTIFY infoChanged)
    Q_PROPERTY(bool warping READ warping NOTIFY infoChanged)

    // Per-server connection state (SrvState: 0 = OFF, 1 = STARTING,
    // 2 = LISTENING, 3 = CONNECTED, 4 = STOPPING, 5 = INVALID).
    Q_PROPERTY(int rshServerState READ rshServerState NOTIFY infoChanged)
    Q_PROPERTY(int rpcServerState READ rpcServerState NOTIFY infoChanged)
    Q_PROPERTY(int dapServerState READ dapServerState NOTIFY infoChanged)
    Q_PROPERTY(int promServerState READ promServerState NOTIFY infoChanged)

    // Presentation helpers for a SrvState value (the encoding above). Single
    // source of truth for how a server state reads in the UI, so the
    // statusbar icon and the server config panel can't drift apart.
    Q_INVOKABLE QUrl serverStateLed(int state) const;
    Q_INVOKABLE QString serverStateIcon(int state) const;
    Q_INVOKABLE QString serverStateName(int state) const;

    //
    // Drives
    //

    Q_PROPERTY(int track8 READ track8 NOTIFY infoChanged)
    Q_PROPERTY(bool spinning8 READ spinning8 NOTIFY infoChanged)
    Q_PROPERTY(bool writing8 READ writing8 NOTIFY infoChanged)
    Q_PROPERTY(bool redLED8 READ redLED8 NOTIFY infoChanged)
    Q_PROPERTY(bool greenLED8 READ greenLED8 NOTIFY infoChanged)
    Q_PROPERTY(bool hasDisk8 READ hasDisk8 NOTIFY infoChanged)
    Q_PROPERTY(bool hasModifiedDisk8 READ hasModifiedDisk8 NOTIFY infoChanged)
    Q_PROPERTY(bool hasProtectedDisk8 READ hasProtectedDisk8 NOTIFY infoChanged)

    Q_PROPERTY(int track9 READ track9 NOTIFY infoChanged)
    Q_PROPERTY(bool spinning9 READ spinning9 NOTIFY infoChanged)
    Q_PROPERTY(bool writing9 READ writing9 NOTIFY infoChanged)
    Q_PROPERTY(bool redLED9 READ redLED9 NOTIFY infoChanged)
    Q_PROPERTY(bool greenLED9 READ greenLED9 NOTIFY infoChanged)
    Q_PROPERTY(bool hasDisk9 READ hasDisk9 NOTIFY infoChanged)
    Q_PROPERTY(bool hasModifiedDisk9 READ hasModifiedDisk9 NOTIFY infoChanged)
    Q_PROPERTY(bool hasProtectedDisk9 READ hasProtectedDisk9 NOTIFY infoChanged)

    //
    // Datasette
    //

    Q_PROPERTY(bool hasTape READ hasTape NOTIFY infoChanged)
    Q_PROPERTY(bool tapeSpinning READ tapeSpinning NOTIFY infoChanged)
    Q_PROPERTY(int tapeCounter READ tapeCounter NOTIFY infoChanged)

    //
    // Cartridge
    //

    Q_PROPERTY(bool hasCrt READ hasCrt NOTIFY infoChanged)

  private:

    // Samples the given single component's structs from the core (no signal).
    void grab(Component component);

    // CPU registers -- raw ints so consumers can format them per the shared
    // display setting.
    int pc() const { return m_cpuInfo.pc; }
    int sp() const { return m_cpuInfo.sp; }
    int a() const { return m_cpuInfo.a; }
    int x() const { return m_cpuInfo.x; }
    int y() const { return m_cpuInfo.y; }
    int portReg() const { return m_cpuInfo.processorPort; }
    int portDir() const { return m_cpuInfo.processorPortDir; }
    // The PC is mid-instruction (not at a fetch boundary) while the machine
    // is stopped -- needs core state, so this one isn't inline.
    bool pcWarning() const;

    // Status flags, decoded from the processor status register.
    bool flagN() const { return m_cpuInfo.sr & 0x80; }
    bool flagV() const { return m_cpuInfo.sr & 0x40; }
    bool flagB() const { return m_cpuInfo.sr & 0x10; }
    bool flagD() const { return m_cpuInfo.sr & 0x08; }
    bool flagI() const { return m_cpuInfo.sr & 0x04; }
    bool flagZ() const { return m_cpuInfo.sr & 0x02; }
    bool flagC() const { return m_cpuInfo.sr & 0x01; }

    // Interrupt lines, decoded from the IRQ / NMI source masks.
    bool irq() const { return m_cpuInfo.irq != 0; }
    bool irqCIA() const { return m_cpuInfo.irq & INTSRC_CIA; }
    bool irqVIC() const { return m_cpuInfo.irq & INTSRC_VIC; }
    bool irqEXP() const { return m_cpuInfo.irq & INTSRC_EXP; }
    bool nmi() const { return m_cpuInfo.nmi != 0; }
    bool nmiCIA() const { return m_cpuInfo.nmi & INTSRC_CIA; }
    bool nmiKBD() const { return m_cpuInfo.nmi & INTSRC_KBD; }
    bool nmiEXP() const { return m_cpuInfo.nmi & INTSRC_EXP; }
    bool rdy() const { return m_cpuInfo.rdy; }
    bool jammed() const { return m_cpuInfo.jammed; }

    // Machine status. These read live core state (remote servers, track mode,
    // volumes), so they aren't inline. All change on info-dirty events, which
    // drive infoChanged. (The halt indicator binds to 'jammed' above; the
    // Commodore key lives on SiC64KeyboardController, which is notified per
    // keystroke rather than on info-dirty.)
    int serverState() const;
    bool tracking() const;
    bool mute() const;
    bool warping() const;

    // Individual remote-server states, read from the cached RemoteManagerInfo.
    int rshServerState() const;
    int rpcServerState() const;
    int dapServerState() const;
    int promServerState() const;

    // Drive 8 / 9 state, read from the cached DriveInfo (index 0 = drive 8,
    // 1 = drive 9). 'track' is the current halftrack under the head.
    int track8() const { return int(m_driveInfo[0].halftrack); }
    bool spinning8() const { return m_driveInfo[0].spinning; }
    bool writing8() const { return m_driveInfo[0].writing; }
    bool redLED8() const { return m_driveInfo[0].redLED; }
    bool greenLED8() const { return m_driveInfo[0].greenLED; }
    bool hasDisk8() const { return m_driveInfo[0].hasDisk; }
    bool hasModifiedDisk8() const { return m_driveInfo[0].hasModifiedDisk; }
    bool hasProtectedDisk8() const { return m_driveInfo[0].hasProtectedDisk; }

    int track9() const { return int(m_driveInfo[1].halftrack); }
    bool spinning9() const { return m_driveInfo[1].spinning; }
    bool writing9() const { return m_driveInfo[1].writing; }
    bool redLED9() const { return m_driveInfo[1].redLED; }
    bool greenLED9() const { return m_driveInfo[1].greenLED; }
    bool hasDisk9() const { return m_driveInfo[1].hasDisk; }
    bool hasModifiedDisk9() const { return m_driveInfo[1].hasModifiedDisk; }
    bool hasProtectedDisk9() const { return m_driveInfo[1].hasProtectedDisk; }

    bool hasTape() const { return m_datasetteInfo.hasTape; }
    bool tapeSpinning() const { return m_datasetteInfo.motor; }
    int tapeCounter() const { return int(m_datasetteInfo.counter); }
    bool hasCrt() const { return m_cartridgeAttached; }

  signals:

    void infoChanged();
};
