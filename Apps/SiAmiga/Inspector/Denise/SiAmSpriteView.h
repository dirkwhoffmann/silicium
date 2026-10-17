// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#pragma once

#include <QQuickPaintedItem>
#include <QColor>
#include <array>
#include <vector>

//
// Port of vAmiga's own GUI/Inspector/SpriteTableView.swift -- a pixel-level
// preview of the selected sprite's latched bitmap data (16 columns wide,
// one row per line the sprite was armed for). Shaped like SiAmLogicView:
// self-drives off its window's frameSwapped signal while on screen, reading
// straight off the core's DeniseInfo each frame rather than through the
// throttled SiAmInfoController cache, since the raw sprite data pointer
// (DeniseInfo::sprite[n].data) is only valid for the instant it was
// sampled -- a QQuickPaintedItem/QPainter grid rather than SiC64DmaView's
// texture blit, since this is a handful of colored cells, not a whole frame
// buffer.
//
// Each sprite row is a 64-bit word packing two 16-bit bitplanes (SPRxDATA in
// the low 16 bits, SPRxDATB in the next 16) -- see cacheData()'s bit
// extraction, ported from SpriteTableView.colorIndex(). The 2-bit index per
// column (0 = transparent, 1..3) is resolved against the color registers
// the selected sprite's *pair* shares (sprites 0/1 use registers 17..19,
// 2/3 use 21..23, 4/5 use 25..27, 6/7 use 29..31 -- DeniseInfo::sprite[n].
// colors[] already holds "the upper 16 color registers", so colors[1..3],
// [5..7], [9..11], [13..15] are the right slices for each pair, matching
// SpriteTableView's own spriteCol[1..3]/[5..7]/[9..11]/[13..15] indexing).
//
class SiAmSpriteView : public QQuickPaintedItem {

    Q_OBJECT

    Q_PROPERTY(int spriteNr READ spriteNr WRITE setSpriteNr NOTIFY spriteNrChanged)

    static constexpr int columns = 16;
    static constexpr qreal gapPx = 2.0;
    static constexpr qreal borderPx = 1.0;

    int m_spriteNr = 0;

    // Cached per-frame bitmap: one row per sprite line, each holding
    // 'columns' 2-bit color indices (0..3).
    std::vector<std::array<int, columns>> m_rows;
    QColor m_colors[4]; // index 0 unused (transparent)

    QMetaObject::Connection m_frameConnection;

  public:

    explicit SiAmSpriteView(QQuickItem *parent = nullptr);

    void paint(QPainter *painter) override;

    int spriteNr() const { return m_spriteNr; }
    void setSpriteNr(int value);

  protected:

    void itemChange(ItemChange change, const ItemChangeData &value) override;
    void geometryChange(const QRectF &newGeometry, const QRectF &oldGeometry) override;

  private:

    void connectToWindow(class QQuickWindow *win);
    void disconnectFromWindow();
    void cacheData();

    // Side length of one square cell for the current item width -- shared
    // by paint() and updateImplicitSize() so they never disagree.
    qreal cellSize() const;

    // The item's natural height is driven by content (m_rows.size() cells
    // stacked at cellSize() + gapPx each), not by whatever the enclosing
    // ScrollView's viewport happens to be -- that's what lets a sprite
    // taller than the viewport become scrollable instead of clipped.
    void updateImplicitSize();

  signals:

    void spriteNrChanged();
};
