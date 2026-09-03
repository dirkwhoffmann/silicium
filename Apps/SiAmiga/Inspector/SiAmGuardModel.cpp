// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "SiAmGuardModel.h"

SiAmGuardModel::SiAmGuardModel(QObject *parent)
    : QAbstractListModel(parent)
{

}

int
SiAmGuardModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_rows.size();
}

QVariant
SiAmGuardModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_rows.size()) return {};

    auto &row = m_rows.at(index.row());

    switch (role) {

        case AddrRole:    return row.addr;
        case EnabledRole: return row.enabled;
        default:          return {};
    }
}

QHash<int, QByteArray>
SiAmGuardModel::roleNames() const
{
    return {
        { AddrRole, "addr" },
        { EnabledRole, "enabled" }
    };
}

void
SiAmGuardModel::setRows(const QVector<Row> &rows)
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
SiAmGuardModel::addrAt(int row) const
{
    if (row < 0 || row >= m_rows.size()) return 0;
    return m_rows.at(row).rawAddr;
}
