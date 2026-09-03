// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "SiAmCopperListModel.h"

SiAmCopperListModel::SiAmCopperListModel(QObject *parent)
    : QAbstractListModel(parent)
{

}

int
SiAmCopperListModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_rows.size();
}

QVariant
SiAmCopperListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_rows.size()) return {};

    auto &row = m_rows.at(index.row());

    switch (role) {

        case AddrRole:       return row.addr;
        case InstrRole:      return row.instr;
        case BreakStateRole: return row.breakState;
        case CurrentRole:    return row.current;
        case ExtraRole:      return row.extra;
        case IllegalRole:    return row.illegal;
        default:             return {};
    }
}

QHash<int, QByteArray>
SiAmCopperListModel::roleNames() const
{
    return {
        { AddrRole, "addr" },
        { InstrRole, "instr" },
        { BreakStateRole, "breakState" },
        { CurrentRole, "current" },
        { ExtraRole, "extra" },
        { IllegalRole, "illegal" }
    };
}

void
SiAmCopperListModel::setRows(const QVector<Row> &rows)
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

quint32
SiAmCopperListModel::addrAt(int row) const
{
    if (row < 0 || row >= m_rows.size()) return 0;
    return m_rows.at(row).rawAddr;
}
