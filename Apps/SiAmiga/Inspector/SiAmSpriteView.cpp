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
}

void
SiAmSpriteView::paint(QPainter *painter)
{
    qreal w = width();
    qreal h = height();
    if (w <= 0 || h <= 0 || m_rows.empty()) return;

    qreal cw = w / columns;
    qreal ch = h / (qreal)m_rows.size();

    painter->setRenderHint(QPainter::Antialiasing, false);

    for (size_t r = 0; r < m_rows.size(); r++) {

        for (int c = 0; c < columns; c++) {

            int idx = m_rows[r][c];
            if (idx == 0) continue; // transparent

            QRectF cell(c * cw, r * ch, cw, ch);
            painter->fillRect(cell, m_colors[idx]);
        }
    }
}
