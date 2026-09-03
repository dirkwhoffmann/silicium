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
#include <QString>
#include <array>
#include <vector>

//
// Port of vAmiga's own GUI/Inspector/LogicView.swift: the Logic Analyzer's
// DMA-cycle timing-diagram grid (228 cycles wide, six signal rows -- Address
// Bus, Data Bus, and the four user-selectable probe channels).
//
// Shaped like SiC64DmaView (self-drives off its window's frameSwapped signal
// while on screen, so it's naturally idle whenever the Bus inspector is
// closed, and needs no controller wiring beyond the static core() accessor)
// but QQuickPaintedItem/QPainter rather than QQuickItem/QSGNode -- this
// draws vectors and text (hairlines, per-cycle owner labels, the
// bus-value "hexagon" shapes), not a texture blit, so there's no scene-graph
// node to build.
//
// Coordinates are native Qt (origin top-left, y grows down), which happens
// to lay the rows out in the same visual order as Swift's flipped-AppKit
// math (cycle numbers, then owner labels, then Address Bus/Data Bus/probe
// rows top-to-bottom) without needing any of Swift's bounds.maxY flipping.
//
class SiAmLogicView : public QQuickPaintedItem {

    Q_OBJECT

    Q_PROPERTY(bool hex READ hex WRITE setHex NOTIFY optionsChanged)
    Q_PROPERTY(bool symbolic READ symbolic WRITE setSymbolic NOTIFY optionsChanged)
    Q_PROPERTY(QColor textColor READ textColor WRITE setTextColor NOTIFY optionsChanged)
    Q_PROPERTY(QColor hairlineColor READ hairlineColor WRITE setHairlineColor NOTIFY optionsChanged)

    static constexpr int segments = 228;
    static constexpr int numSignals = 6;

    // Bit width of each signal, for hex-digit-count/decimal-width purposes.
    // [ addr bus, data bus, probe0, probe1, probe2, probe3 ]
    static constexpr int bitWidth[numSignals] = { 24, 16, 16, 16, 16, 16 };

    // Recorded data for the current scanline, re-sampled once per rendered
    // frame by cacheData(). INT_MIN marks "no value" (Swift's data[c][i] ==
    // nil), e.g. a cycle not yet reached this line, or a probe channel that
    // reported no sample.
    std::array<std::array<int, segments>, numSignals> m_data {};

    // Owning bus-cycle label/color for each of the 228 cycles (only the
    // first two signal rows -- Address/Data Bus -- key off these; the empty
    // string / invalid QColor mean "unowned", matching Swift's nil).
    std::array<QString, segments> m_labels {};
    std::array<QColor, segments> m_colors {};

    bool m_hex = true;
    bool m_symbolic = false;
    QColor m_textColor = QColor(Qt::black);
    QColor m_hairlineColor = QColor(Qt::gray);

    QMetaObject::Connection m_frameConnection;

  public:

    explicit SiAmLogicView(QQuickItem *parent = nullptr);

    void paint(QPainter *painter) override;

    bool hex() const { return m_hex; }
    void setHex(bool value);
    bool symbolic() const { return m_symbolic; }
    void setSymbolic(bool value);
    QColor textColor() const { return m_textColor; }
    void setTextColor(const QColor &value);
    QColor hairlineColor() const { return m_hairlineColor; }
    void setHairlineColor(const QColor &value);

  protected:

    void itemChange(ItemChange change, const ItemChangeData &value) override;

  private:

    void connectToWindow(class QQuickWindow *win);
    void disconnectFromWindow();

    // Re-samples the current scanline's bus-owner/address/data/probe data
    // from the core (see LogicView.cacheData()'s owner->label/color switch,
    // reproduced here) and the DMA Debugger's channel colors (read straight
    // from the packed DMA_DEBUG_COLORx option, decoded the same way
    // SiAmConfigController::dmaColor() does).
    void cacheData();

    void drawHairlines(QPainter *p, qreal w, qreal h, qreal dx) const;
    void drawLabels(QPainter *p, qreal w, qreal headerHeight, qreal dx) const;
    void drawSignal(QPainter *p, int channel, qreal w, qreal headerHeight, qreal dx, qreal dy) const;
    void drawDataSegment(QPainter *p, const QRectF &r, int prev, int curr, int next, bool prevValid, bool currValid, bool nextValid) const;
    QString formatValue(int value, int bits) const;

  signals:

    void optionsChanged();
};
