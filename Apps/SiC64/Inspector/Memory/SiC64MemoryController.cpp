// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "SiC64MemoryController.h"
#include "C64Controller.h"
#include "SiC64ConfigController.h"

using namespace vc64;

SiC64MemoryController::SiC64MemoryController(C64Controller *parent)
    : SiC64InspectorController(parent), m_rowModel(this)
{
    // The heatmap sub-view is only populated while the MEM_HEATMAP config
    // option is on. Mirror the old Swift-based emulator, which enabled it
    // while the Memory inspector was open.
    connect(this, &SiC64InspectorController::activeChanged, this, [this]() {
        this->parent->getConfigController()->setMemHeatmap(isActive());
    });
}

QString
SiC64MemoryController::nameForType(MemType type)
{
    switch (type) {

        case MemType::NONE:   return "Unmapped";
        case MemType::RAM:    return "RAM";
        case MemType::PP:     return "PPort + RAM";
        case MemType::BASIC:  return "Basic ROM";
        case MemType::CHAR:   return "Character ROM";
        case MemType::KERNAL: return "Kernal ROM";
        case MemType::IO:     return "IO";
        case MemType::CRTLO:  return "Cartridge LO";
        case MemType::CRTHI:  return "Cartridge HI";
        default:              return "???";
    }
}

QColor
SiC64MemoryController::colorForType(MemType type)
{
    // Mirrors the old Swift-based emulator's MemColors.
    switch (type) {

        case MemType::RAM:    return QColor(0x99, 0xFF, 0x99);
        case MemType::PP:     return QColor(0x33, 0xAA, 0x33);
        case MemType::BASIC:  return QColor(0xFF, 0x99, 0x99);
        case MemType::CHAR:   return QColor(0xFF, 0xFF, 0x99);
        case MemType::KERNAL: return QColor(0x99, 0xCC, 0xFF);
        case MemType::IO:     return QColor(0x99, 0xFF, 0xFF);
        case MemType::CRTLO:  return QColor(0xCC, 0x99, 0xFF);
        case MemType::CRTHI:  return QColor(0xFF, 0x99, 0xFF);
        default:              return QColor(0x80, 0x80, 0x80); // Unmapped
    }
}

void
SiC64MemoryController::updateBankTypes(const MemInfo &info)
{
    switch (m_source) {

        case 0: // CPU-visible bank
            for (int i = 0; i < 16; i++) m_bankTypes[i] = info.peekSrc[i];
            break;

        case 1: // VIC-visible bank
            for (int i = 0; i < 16; i++) m_bankTypes[i] = info.vicPeekSrc[i];
            break;

        case 2: // RAM
            for (int i = 0; i < 16; i++) m_bankTypes[i] = MemType::RAM;
            break;

        case 3: // ROM
            for (int i = 0; i < 16; i++) m_bankTypes[i] = MemType::NONE;
            m_bankTypes[0xA] = MemType::BASIC;
            m_bankTypes[0xB] = MemType::BASIC;
            m_bankTypes[0xD] = MemType::CHAR;
            m_bankTypes[0xE] = MemType::KERNAL;
            m_bankTypes[0xF] = MemType::KERNAL;
            break;

        case 4: // IO
            for (int i = 0; i < 16; i++) m_bankTypes[i] = MemType::NONE;
            m_bankTypes[0xD] = MemType::IO;
            break;
    }
}

void
SiC64MemoryController::rebuildBanks()
{
    QVariantList banks;

    for (int i = 0; i < 16; i++) {

        QVariantMap bank;
        bank["nr"] = i;
        bank["name"] = nameForType(m_bankTypes[i]);
        bank["color"] = colorForType(m_bankTypes[i]);
        bank["mapped"] = m_bankTypes[i] != MemType::NONE;
        bank["type"] = int(m_bankTypes[i]);
        banks.append(bank);
    }

    m_banks = banks;
}

void
SiC64MemoryController::rebuildRows()
{
    auto &mem = C64Controller::core().mem;
    bool hex = parent->isHex();
    MemType src = m_bankTypes[m_displayedBank];
    int base = m_displayedBank * 0x1000;

    QVector<SiC64MemDumpModel::Row> rows;
    rows.reserve(256);

    for (int row = 0; row < 256; row++) {

        u16 addr = u16(base + row * 16);

        SiC64MemDumpModel::Row r;
        r.addr = formatNumber(addr, 4);
        r.hex = QString::fromStdString(mem.memdump(addr, 16, hex, 1, src));
        r.ascii = QString::fromStdString(mem.txtdump(addr, 16, src));
        rows.append(r);
    }

    m_rowModel.setRows(rows);
}

void
SiC64MemoryController::refreshData()
{
    // Read the memory info from the shared info controller rather than
    // sampling the core directly; requestUpdate() coalesces the sampling
    // across all open inspectors. The dump bytes below are read separately
    // (rebuildRows), as they aren't part of the cached info struct.
    auto *infoController = parent->getInfoController();
    infoController->requestUpdate(SiC64InfoController::MEM, 0.25);
    auto &info = infoController->memInfo();

    m_exrom  = info.exrom;
    m_game   = info.game;
    m_charen = info.charen;
    m_hiram  = info.hiram;
    m_loram  = info.loram;

    updateBankTypes(info);
    rebuildBanks();
    rebuildRows();

    emit memChanged();
}

void
SiC64MemoryController::setSource(int value)
{
    if (m_source != value) {

        m_source = value;
        refresh();
    }
}

void
SiC64MemoryController::setDisplayedBank(int value)
{
    value = qBound(0, value, 15);

    if (m_displayedBank != value) {

        m_displayedBank = value;
        refresh();
    }
}

void
SiC64MemoryController::jumpToAddress(int addr)
{
    if (addr < 0 || addr > 0xFFFF) return;

    setDisplayedBank(addr >> 12);

    m_selectedRow = (addr & 0xFFF) / 16;
    m_selectRevision++;
    emit selectionChanged();
}

void
SiC64MemoryController::jumpToType(int memType)
{
    auto target = MemType(memType);

    for (int i = 0; i < 16; i++) {

        if (m_bankTypes[i] == target ||
            (target == MemType::RAM && m_bankTypes[i] == MemType::PP)) {

            setDisplayedBank(i);
            return;
        }
    }
}
