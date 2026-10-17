// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "SiAmInstructionModel.h"

SiAmInstructionModel::SiAmInstructionModel(QObject *parent)
    : QAbstractListModel(parent)
{

}

int
SiAmInstructionModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_rows.size();
}

QVariant
SiAmInstructionModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_rows.size()) return {};

    auto &row = m_rows.at(index.row());

    switch (role) {

        case AddrValueRole: return row.addrValue;
        case AddrRole:      return row.addr;
        case BytesRole:     return row.bytes;
        case InstrRole:     return row.instr;
        case BreakpointRole: return row.breakpoint;
        case IsPCRole:      return row.isPC;
        default:            return {};
    }
}

QHash<int, QByteArray>
SiAmInstructionModel::roleNames() const
{
    return {
        { AddrValueRole, "addrValue" },
        { AddrRole, "addr" },
        { BytesRole, "bytes" },
        { InstrRole, "instr" },
        { BreakpointRole, "breakpoint" },
        { IsPCRole, "isPC" }
    };
}

void
SiAmInstructionModel::setRows(const QVector<Row> &rows)
{
    if (rows.size() != m_rows.size()) {

        beginResetModel();
        m_rows = rows;
        endResetModel();
        return;
    }

    m_rows = rows;

    if (!m_rows.isEmpty()) {
        emit dataChanged(index(0), index(m_rows.size() - 1));
    }
}
