// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "SiAmTraceModel.h"

SiAmTraceModel::SiAmTraceModel(QObject *parent)
    : QAbstractListModel(parent)
{

}

int
SiAmTraceModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_rows.size();
}

QVariant
SiAmTraceModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_rows.size()) return {};

    auto &row = m_rows.at(index.row());

    switch (role) {

        case AddrValueRole: return row.addrValue;
        case AddrRole:       return row.addr;
        case FlagsRole:      return row.flags;
        case InstrRole:      return row.instr;
        default:             return {};
    }
}

QHash<int, QByteArray>
SiAmTraceModel::roleNames() const
{
    return {
        { AddrValueRole, "addrValue" },
        { AddrRole, "addr" },
        { FlagsRole, "flags" },
        { InstrRole, "instr" }
    };
}

void
SiAmTraceModel::setRows(const QVector<Row> &rows)
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
