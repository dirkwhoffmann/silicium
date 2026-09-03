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
#include "SiAmMemDumpModel.h"
#include "VAmiga.h"
#include <QVariantList>
#include <QColor>

//
// Memory inspector controller -- port of SiC64MemoryController. Exposes:
//
//   - banks: the 256 banks of the currently selected accessor (CPU-visible
//     or Agnus-visible), each with its mapped MemSrc, name and legend
//     color -- feeds both the bank list and the colored layout strip.
//   - rows:  a hex/ASCII dump of the displayed bank.
//   - the RAM/ROM/chip legend sizes (chipKB/fastKB/.../extKB), read from
//     the core's own MemConfig.
//
// Several real differences from the C64 version, all hardware-driven:
//
//  - vAmiga's memory map has no processor-port banking bits at all -- no
//    EXROM/GAME/CHAREN/HIRAM/LORAM, no RAM/ROM/IO "pure" source modes. The
//    only two things worth viewing memory *as* are what the CPU currently
//    sees and what Agnus (the chipset's own bus master) currently sees --
//    see MemInfo's cpuMemSrc[256]/agnusMemSrc[256] -- so 'source' is a
//    plain CPU/Agnus toggle instead of C64's five-way selector, and there
//    are no exrom/game/... properties at all.
//  - vAmiga addresses 16 MB (24-bit bus) in 256 banks of 64 KB each,
//    versus the C64's 16 banks of 4 KB -- banks/bankTypes/rebuildRows all
//    scale up accordingly (4096 dump rows per bank instead of 256).
//  - The core's own MemoryDebuggerAPI (core().mem.debugger) only ever
//    formats memory dumps in hex (hexDump()/ascDump()/memDump() -- no
//    decimal mode the way C64Controller::isHex() switches vc64's
//    mem.memdump()), so the dump grid always shows hex regardless of the
//    shared hex/decimal display setting; that setting still governs every
//    other numeric field on the panel (addresses, register-style values).
//  - There's no MEM_HEATMAP config option or equivalent in vAmiga's core,
//    so there is no heatmap sub-view or SiAmHeatmap counterpart to
//    SiC64Heatmap -- the constructor has nothing analogous to connect for
//    it either.
//  - Bank/legend names come straight from the core's own
//    MemSrcEnum::help(), rather than a hand-written name table -- it
//    already returns exactly the labels this panel wants ("Chip RAM",
//    "Chip RAM mirror", ...).
//

class SiAmController;

class SiAmMemoryController : public SiAmInspectorController {

    Q_OBJECT

    // 0 = CPU-visible, 1 = Agnus-visible
    int m_source = 0;

    // Displayed 64 KB bank (0 .. 255)
    int m_displayedBank = 0;

    // Row within the displayed bank to scroll to / highlight after a jump,
    // or -1. Bumped through m_selectRevision so QML notices repeat jumps to
    // the same row.
    int m_selectedRow = -1;
    int m_selectRevision = 0;

    // The mapped type of each of the 256 banks for the current source
    vamiga::MemSrc m_bankTypes[256] = {};

    QVariantList m_banks;
    SiAmMemDumpModel m_rowModel;

    // RAM/ROM legend sizes, in KB -- see the class comment for why only
    // these six (not CIA/RTC/Chipset/Zorro, which have no MemConfig size
    // field of their own) get one.
    int m_chipKB = 0, m_fastKB = 0, m_slowKB = 0;
    int m_romKB = 0, m_womKB = 0, m_extKB = 0;

  public:

    explicit SiAmMemoryController(SiAmController *parent = nullptr);

    Q_PROPERTY(int source READ source WRITE setSource NOTIFY memChanged)
    Q_PROPERTY(int displayedBank READ displayedBank WRITE setDisplayedBank NOTIFY memChanged)
    Q_PROPERTY(int selectedRow READ selectedRow NOTIFY selectionChanged)
    Q_PROPERTY(int selectRevision READ selectRevision NOTIFY selectionChanged)

    Q_PROPERTY(QVariantList banks READ banks NOTIFY memChanged)
    Q_PROPERTY(QObject* rows READ rows CONSTANT)

    Q_PROPERTY(int chipKB READ chipKB NOTIFY memChanged)
    Q_PROPERTY(int fastKB READ fastKB NOTIFY memChanged)
    Q_PROPERTY(int slowKB READ slowKB NOTIFY memChanged)
    Q_PROPERTY(int romKB READ romKB NOTIFY memChanged)
    Q_PROPERTY(int womKB READ womKB NOTIFY memChanged)
    Q_PROPERTY(int extKB READ extKB NOTIFY memChanged)

    int source() const { return m_source; }
    void setSource(int value);
    int displayedBank() const { return m_displayedBank; }
    void setDisplayedBank(int value);

    // Shows the bank containing 'addr' and selects the row holding it.
    Q_INVOKABLE void jumpToAddress(int addr);

    // Jumps to the first bank mapped to the given memory type (a
    // vamiga::MemSrc value).
    Q_INVOKABLE void jumpToType(int memSrc);

  protected:

    void refreshData() override;

  private:

    int selectedRow() const { return m_selectedRow; }
    int selectRevision() const { return m_selectRevision; }
    QVariantList banks() const { return m_banks; }
    QObject *rows() const { return const_cast<SiAmMemDumpModel *>(&m_rowModel); }

    int chipKB() const { return m_chipKB; }
    int fastKB() const { return m_fastKB; }
    int slowKB() const { return m_slowKB; }
    int romKB() const { return m_romKB; }
    int womKB() const { return m_womKB; }
    int extKB() const { return m_extKB; }

    // Recomputes m_bankTypes from the current source and MemInfo
    void updateBankTypes(const vamiga::MemInfo &info);

    // Rebuilds the bank list / layout-strip model and the hex dump
    void rebuildBanks();
    void rebuildRows();

    static QColor colorForType(vamiga::MemSrc type);

  signals:

    void memChanged();
    void selectionChanged();
};
