// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#pragma once

#include <QAbstractListModel>
#include <QVector>

//
// List model backing one of SiAmCopperPanel's two disassembly tables. Port
// of the same setRows()-in-place pattern SiAmMemDumpModel/
// SiAmEventTableModel use, so a ListView bound to this never loses its
// scroll position on refresh -- see either of those for the rationale.
//
// One instance per Copper list (SiAmCopperController owns two), rather than
// a single model both lists share, since the two lists' contents are
// otherwise unrelated (different start/end address, independently
// selectable Binary/Symbolic format, independent extra-row count).
//

class SiAmCopperListModel : public QAbstractListModel {

    Q_OBJECT

  public:

    struct Row {

        quint32 rawAddr = 0;
        QString addr;
        QString instr;

        // 0 = no breakpoint, 1 = enabled, 2 = disabled -- mirrors
        // CopperTableView.BreakpointType in vAmiga's own GUI.
        int breakState = 0;

        // True for the instruction Copper's PC is currently sitting on.
        bool current = false;

        // True for a row beyond the natively detected list length (i.e.
        // one of extraRows) or a row whose instruction touches a register
        // it has no access to -- both rendered dimmed/highlighted rather
        // than plain, matching vAmiga's own willDisplayCell coloring.
        bool extra = false;
        bool illegal = false;
    };

    enum Role {

        AddrRole = Qt::UserRole + 1,
        InstrRole,
        BreakStateRole,
        CurrentRole,
        ExtraRole,
        IllegalRole
    };

    explicit SiAmCopperListModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    void setRows(const QVector<Row> &rows);

    // Address of each row, in the same order as the model -- used by
    // SiAmCopperController::toggleBreakpoint() to resolve a row index back
    // to a target address without the panel having to track it separately.
    quint32 addrAt(int row) const;

  private:

    QVector<Row> m_rows;
};
