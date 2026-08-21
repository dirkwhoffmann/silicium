// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "SiC64EventTableModel.h"

SiC64EventTableModel::SiC64EventTableModel(QObject *parent)
    : QAbstractListModel(parent)
{

}

int
SiC64EventTableModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_rows.size();
}

QVariant
SiC64EventTableModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_rows.size()) return {};

    auto &row = m_rows.at(index.row());

    switch (role) {

        case SlotRole:    return row.slot;
        case EventRole:   return row.event;
        case PendingRole: return row.pending;
        case DueRole:     return row.due;
        case TriggerRole: return row.trigger;
        case FrameRole:   return row.frame;
        case VposRole:    return row.vpos;
        case HposRole:    return row.hpos;
        case RemarkRole:  return row.remark;
        default:          return {};
    }
}

QHash<int, QByteArray>
SiC64EventTableModel::roleNames() const
{
    return {
        { SlotRole, "slot" },
        { EventRole, "event" },
        { PendingRole, "pending" },
        { DueRole, "due" },
        { TriggerRole, "trigger" },
        { FrameRole, "frame" },
        { VposRole, "vpos" },
        { HposRole, "hpos" },
        { RemarkRole, "remark" }
    };
}

void
SiC64EventTableModel::setRows(const QVector<Row> &rows)
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
