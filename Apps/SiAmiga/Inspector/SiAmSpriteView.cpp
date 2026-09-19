// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "SiAmSpriteView.h"
#include "SiAmController.h"
#include "VAmiga.h"

#include <QPainter>
#include <QQuickWindow>

using namespace vamiga;

static QColor
decodeAmigaColor(u16 reg)
{
    int r4 = (reg >> 8) & 0xF;
    int g4 = (reg >> 4) & 0xF;
    int b4 = reg & 0xF;

    return QColor(r4 | (r4 << 4), g4 | (g4 << 4), b4 | (b4 << 4));
}

SiAmSpriteView::SiAmSpriteView(QQuickItem *parent)
    : QQuickPaintedItem(parent)
{
    // Explicit rather than relying on QQuickPaintedItem's own default
    // (already Qt::transparent) -- makes the "untouched area stays
    // see-through, not black" intent readable here instead of implicit.
    setFillColor(Qt::transparent);
}

void
SiAmSpriteView::setSpriteNr(int value)
{
    if (value < 0 || value > 7 || m_spriteNr == value) return;

    m_spriteNr = value;
    emit spriteNrChanged();
}

void
SiAmSpriteView::itemChange(ItemChange change, const ItemChangeData &value)
{
    if (change == ItemSceneChange) {

        disconnectFromWindow();
        if (value.window) connectToWindow(value.window);
    }

    QQuickPaintedItem::itemChange(change, value);
}

void
SiAmSpriteView::geometryChange(const QRectF &newGeometry, const QRectF &oldGeometry)
{
    QQuickPaintedItem::geometryChange(newGeometry, oldGeometry);

    // Cell size is derived from width (see cellSize()), so a width change
    // (the enclosing ScrollView's viewport resizing) changes the height
    // this item needs too.
    if (newGeometry.width() != oldGeometry.width()) updateImplicitSize();
}

void
SiAmSpriteView::connectToWindow(QQuickWindow *win)
{
    m_frameConnection = connect(win, &QQuickWindow::frameSwapped, this, [this]() {
        cacheData();
        update();
    });
}

void
SiAmSpriteView::disconnectFromWindow()
{
    if (m_frameConnection) {

        disconnect(m_frameConnection);
        m_frameConnection = QMetaObject::Connection();
    }
}

void
SiAmSpriteView::cacheData()
{
    m_rows.clear();

    DeniseInfo info {};
    try { info = SiAmController::core().denise.getInfo(); } catch (...) { return; }

    if (m_spriteNr < 0 || m_spriteNr >= 8) return;
    auto &sprite = info.sprite[m_spriteNr];

    // The pair-shared extra-color slice within SpriteInfo::colors[16] --
    // see the class comment. Sprites 0/1 -> colors[1..3], 2/3 -> [5..7],
    // 4/5 -> [9..11], 6/7 -> [13..15].
    int base = 1 + (m_spriteNr / 2) * 4;
    m_colors[1] = decodeAmigaColor(sprite.colors[base]);
    m_colors[2] = decodeAmigaColor(sprite.colors[base + 1]);
    m_colors[3] = decodeAmigaColor(sprite.colors[base + 2]);

    isize lines = sprite.height > 0 ? sprite.height - 1 : 0;
    if (!sprite.data || lines <= 0) return;

    m_rows.reserve((size_t)lines);

    for (isize i = 0; i < lines; i++) {

        u64 word = sprite.data[i];
        u16 dataA = u16(word & 0xFFFF);
        u16 dataB = u16((word >> 16) & 0xFFFF);

        std::array<int, columns> row {};
        for (int c = 0; c < columns; c++) {

            bool bitA = (dataA & (0x8000 >> c)) != 0;
            bool bitB = (dataB & (0x8000 >> c)) != 0;
            row[c] = (bitA ? 1 : 0) + (bitB ? 2 : 0);
        }
        m_rows.push_back(row);
    }

    updateImplicitSize();
}

qreal
SiAmSpriteView::cellSize() const
{
    qreal w = width();
    if (w <= 0) return 0;

    return (w - (columns - 1) * gapPx) / columns;
}

void
SiAmSpriteView::updateImplicitSize()
{
    qreal cell = cellSize();

    setImplicitHeight(m_rows.empty() || cell <= 0
        ? 0 : m_rows.size() * (cell + gapPx) - gapPx);
}

void
SiAmSpriteView::paint(QPainter *painter)
{
    // No sprite armed -- leave the item fully transparent (there's nothing
    // to draw, not a black square) rather than falling through to the
    // wrapping Rectangle's own black backdrop as if it were part of this
    // view's own content.
    if (m_rows.empty()) return;

    // Square cells sized to fit 'columns' across the available width, with
    // a gapPx-wide transparent seam between neighbours -- not stretched to
    // fill the item's height the way a single row used to be blown up to
    // the full box height. The loop below only ever visits m_rows.size()
    // rows, so a short sprite stays untouched -- transparent -- below its
    // own content instead of painted over. A sprite taller than the
    // enclosing ScrollView's viewport now scrolls instead of being clipped,
    // since this item's own height (see updateImplicitSize()) grows to fit
    // every row rather than being stretched/squeezed to match the viewport.
    qreal cell = cellSize();
    if (cell <= 0) return;

    painter->setRenderHint(QPainter::Antialiasing, false);
    painter->setBrush(Qt::NoBrush);
    painter->setPen(QPen(QColor(120, 120, 120), borderPx));

    for (size_t r = 0; r < m_rows.size(); r++) {

        qreal y = r * (cell + gapPx);

        for (int c = 0; c < columns; c++) {

            QRectF rect(c * (cell + gapPx), y, cell, cell);

            int idx = m_rows[r][c];
            if (idx != 0) painter->fillRect(rect, m_colors[idx]);

            painter->drawRect(rect);
        }
    }
}
