// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "SiAmMemoryController.h"
#include "SiAmController.h"

using namespace vamiga;

SiAmMemoryController::SiAmMemoryController(SiAmController *parent)
    : SiAmInspectorController(parent), m_rowModel(this)
{
    // No MEM_HEATMAP-style option to toggle here -- see the class comment.
}

QColor
SiAmMemoryController::colorForType(MemSrc type)
{
    // Mirrors vAmiga's own GUI/Inspector/MemoryPanel.swift's MemColors.
    // Mirror variants share their base type's color -- the Swift version
    // only tells them apart via a diagonal hatch pattern baked into a
    // raster image, which this QML-native strip (a plain colored Rectangle
    // per bank, like SiC64MemoryPanel's) doesn't attempt to reproduce.
    switch (type) {

        case MemSrc::CHIP:
        case MemSrc::CHIP_MIRROR:    return QColor(0x80, 0xFF, 0x00);
        case MemSrc::SLOW:
        case MemSrc::SLOW_MIRROR:    return QColor(0x66, 0xCC, 0x00);
        case MemSrc::FAST:           return QColor(0x4C, 0x99, 0x00);
        case MemSrc::ROM:
        case MemSrc::ROM_MIRROR:     return QColor(0xFF, 0x00, 0x00);
        case MemSrc::WOM:            return QColor(0xCC, 0x00, 0x00);
        case MemSrc::EXT:            return QColor(0x99, 0x00, 0x00);
        case MemSrc::CIA:
        case MemSrc::CIA_MIRROR:     return QColor(0x66, 0xB2, 0xFF);
        case MemSrc::RTC:            return QColor(0xB2, 0x66, 0xFF);
        case MemSrc::CUSTOM:
        case MemSrc::CUSTOM_MIRROR:  return QColor(0xFF, 0xFF, 0x66);
        case MemSrc::AUTOCONF:
        case MemSrc::ZOR:            return QColor(0xFF, 0x66, 0xB2);
        default:                     return QColor(0x80, 0x80, 0x80); // Unmapped
    }
}

void
SiAmMemoryController::updateBankTypes(const MemInfo &info)
{
    const MemSrc *src = m_source == 0 ? info.cpuMemSrc : info.agnusMemSrc;

    for (int i = 0; i < 256; i++) m_bankTypes[i] = src[i];
}

void
SiAmMemoryController::rebuildBanks()
{
    QVariantList banks;

    for (int i = 0; i < 256; i++) {

        QVariantMap bank;
        bank["nr"] = i;
        bank["name"] = QString(MemSrcEnum::help(m_bankTypes[i]));
        bank["color"] = colorForType(m_bankTypes[i]);
        bank["mapped"] = m_bankTypes[i] != MemSrc::NONE;
        bank["type"] = int(m_bankTypes[i]);
        banks.append(bank);
    }

    m_banks = banks;
}

void
SiAmMemoryController::rebuildRows()
{
    auto &debugger = SiAmController::core().mem.debugger;
    Accessor acc = m_source == 0 ? Accessor::CPU : Accessor::AGNUS;
    u32 base = u32(m_displayedBank) << 16;

    // 64 KB per bank, 16 bytes per row
    QVector<SiAmMemDumpModel::Row> rows;
    rows.reserve(4096);

    for (int row = 0; row < 4096; row++) {

        u32 addr = base + u32(row) * 16;

        SiAmMemDumpModel::Row r;
        r.addr = formatNumber(addr, 6);
        // Always hex -- the core's dump formatters have no decimal mode
        // (see the class comment).
        r.hex = QString::fromStdString(debugger.hexDump(acc, addr, 16, 1));
        r.ascii = QString::fromStdString(debugger.ascDump(acc, addr, 16));
        rows.append(r);
    }

    m_rowModel.setRows(rows);
}

void
SiAmMemoryController::refreshData()
{
    // Read the memory info from the shared info controller rather than
    // sampling the core directly; requestUpdate() coalesces the sampling
    // across all open inspectors. The dump bytes below are read separately
    // (rebuildRows), as they aren't part of the cached info struct.
    auto *infoController = parent->getInfoController();
    infoController->requestUpdate(SiAmInfoController::MEMORY, 0.25);
    auto &info = infoController->memInfo();
    auto &config = infoController->memConfig();

    m_chipKB = config.chipSize / 1024;
    m_fastKB = config.fastSize / 1024;
    m_slowKB = config.slowSize / 1024;
    m_romKB  = config.romSize / 1024;
    m_womKB  = config.womSize / 1024;
    m_extKB  = config.extSize / 1024;

    updateBankTypes(info);
    rebuildBanks();
    rebuildRows();

    emit memChanged();
}

void
SiAmMemoryController::setSource(int value)
{
    if (m_source != value) {

        m_source = value;
        refresh();
    }
}

void
SiAmMemoryController::setDisplayedBank(int value)
{
    value = qBound(0, value, 255);

    if (m_displayedBank != value) {

        m_displayedBank = value;
        refresh();
    }
}

void
SiAmMemoryController::jumpToAddress(int addr)
{
    if (addr < 0 || addr > 0xFFFFFF) return;

    setDisplayedBank(addr >> 16);

    m_selectedRow = (addr & 0xFFFF) / 16;
    m_selectRevision++;
    emit selectionChanged();
}

void
SiAmMemoryController::jumpToType(int memSrc)
{
    auto target = MemSrc(memSrc);

    for (int i = 0; i < 256; i++) {

        if (m_bankTypes[i] == target) {

            setDisplayedBank(i);
            return;
        }
    }
}
