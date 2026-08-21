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
#include "SiC64MemDumpModel.h"
#include "VirtualC64.h"
#include <QVariantList>
#include <QColor>

//
// Memory inspector controller -- port of the old Swift-based emulator's
// Memory inspector (Inspector.swift's Memory tab / MemoryPanel.swift and the
// Bank/Mem table views). Exposes:
//
//   - banks: the 16 banks of the currently selected source (CPU-visible,
//     VIC-visible, RAM, ROM or IO), each with its mapped type, name and
//     legend color -- feeds both the bank list and the colored layout strip.
//   - rows:  a 256-row hex/ASCII dump of the displayed bank.
//   - the processor-port mode flags (EXROM/GAME/CHAREN/HIRAM/LORAM).
//
// Numeric output honours the shared format setting (C64Controller::format).
// The heatmap sub-view (SiC64Heatmap) needs the core's MEM_HEATMAP option,
// which is switched on only while this panel is active.
//
// The shared active flag, tick throttle and beam-position readout come from
// SiC64InspectorController.
//

class C64Controller;

class SiC64MemoryController : public SiC64InspectorController {

    Q_OBJECT

    // 0 = CPU-visible, 1 = VIC-visible, 2 = RAM, 3 = ROM, 4 = IO
    int m_source = 0;

    // Displayed 4 KB bank (0 .. 15)
    int m_displayedBank = 0;

    // Row within the displayed bank to scroll to / highlight after a jump,
    // or -1. Bumped through m_selectRevision so QML notices repeat jumps to
    // the same row.
    int m_selectedRow = -1;
    int m_selectRevision = 0;

    // The mapped type of each of the 16 banks for the current source
    vc64::MemType m_bankTypes[16] = {};

    QVariantList m_banks;
    SiC64MemDumpModel m_rowModel;

    bool m_exrom = false, m_game = false, m_charen = false;
    bool m_hiram = false, m_loram = false;

  public:

    explicit SiC64MemoryController(C64Controller *parent = nullptr);

    Q_PROPERTY(int source READ source WRITE setSource NOTIFY memChanged)
    Q_PROPERTY(int displayedBank READ displayedBank WRITE setDisplayedBank NOTIFY memChanged)
    Q_PROPERTY(int selectedRow READ selectedRow NOTIFY selectionChanged)
    Q_PROPERTY(int selectRevision READ selectRevision NOTIFY selectionChanged)

    Q_PROPERTY(QVariantList banks READ banks NOTIFY memChanged)
    Q_PROPERTY(QObject* rows READ rows CONSTANT)

    Q_PROPERTY(bool exrom READ exrom NOTIFY memChanged)
    Q_PROPERTY(bool game READ game NOTIFY memChanged)
    Q_PROPERTY(bool charen READ charen NOTIFY memChanged)
    Q_PROPERTY(bool hiram READ hiram NOTIFY memChanged)
    Q_PROPERTY(bool loram READ loram NOTIFY memChanged)

    int source() const { return m_source; }
    void setSource(int value);
    int displayedBank() const { return m_displayedBank; }
    void setDisplayedBank(int value);

    // Shows the bank containing 'addr' and selects the row holding it.
    Q_INVOKABLE void jumpToAddress(int addr);

    // Jumps to the first bank mapped to the given memory type (a vc64::MemType
    // value). The RAM legend button also accepts the processor-port bank.
    Q_INVOKABLE void jumpToType(int memType);

  protected:

    void refreshData() override;

  private:

    int selectedRow() const { return m_selectedRow; }
    int selectRevision() const { return m_selectRevision; }
    QVariantList banks() const { return m_banks; }
    QObject *rows() const { return const_cast<SiC64MemDumpModel *>(&m_rowModel); }
    bool exrom() const { return m_exrom; }
    bool game() const { return m_game; }
    bool charen() const { return m_charen; }
    bool hiram() const { return m_hiram; }
    bool loram() const { return m_loram; }

    // Recomputes m_bankTypes from the current source and MemInfo
    void updateBankTypes(const vc64::MemInfo &info);

    // Rebuilds the bank list / layout-strip model and the hex dump
    void rebuildBanks();
    void rebuildRows();

    static QString nameForType(vc64::MemType type);
    static QColor colorForType(vc64::MemType type);

  signals:

    void memChanged();
    void selectionChanged();
};
