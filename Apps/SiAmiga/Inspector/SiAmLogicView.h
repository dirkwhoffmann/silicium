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
#include <QFont>
#include <QString>
#include <QVariantList>
#include <array>
#include <vector>

//
// Port of vAmiga's own GUI/Inspector/LogicView.swift: the Logic Analyzer's
// DMA-cycle timing-diagram grid (256 samples wide, six signal rows -- Address
// Bus, Data Bus, and the four user-selectable probe channels).
//
// A column is one entry of the core's logic-analyzer ring buffer, not a fixed
// horizontal position: the view shows the most recent 'segments' samples, the
// newest in the rightmost column, and a window that long spans more than one
// rasterline. Each column therefore carries the hpos it was recorded at
// (m_positions), which is what the header row prints.
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
    Q_PROPERTY(QVariantList rowColors READ rowColors WRITE setRowColors NOTIFY optionsChanged)
    Q_PROPERTY(QColor hairlineColor READ hairlineColor WRITE setHairlineColor NOTIFY optionsChanged)

    static constexpr int segments = 256;
    static constexpr int numSignals = 6;

    // Bit width of each signal, for hex-digit-count/decimal-width purposes.
    // [ addr bus, data bus, probe0, probe1, probe2, probe3 ]
    static constexpr int bitWidth[numSignals] = { 24, 16, 16, 16, 16, 16 };

    // Recorded data for the displayed sample window, re-sampled once per
    // rendered frame by cacheData(). INT_MIN marks "no value" (Swift's
    // data[c][i] == nil), e.g. a column the trace does not reach back far
    // enough to fill, or a probe channel that reported no sample.
    std::array<std::array<int, segments>, numSignals> m_data {};

    // The hpos each column's sample was recorded at, for the header row.
    // INT_MIN marks a column with no sample behind it.
    std::array<int, segments> m_positions {};

    // Owning bus-cycle label/color for each column (only the first two
    // signal rows -- Address/Data Bus -- key off these; the empty string /
    // invalid QColor mean "unowned", matching Swift's nil).
    std::array<QString, segments> m_labels {};
    std::array<QColor, segments> m_colors {};

    /* What the address bus is pointing at, per cycle, for symbolic mode.
     *
     * Resolved in cacheData() rather than while drawing, which is where
     * LogicView.swift does it: naming an address is a core lookup, and the
     * paint path runs over every column. Sampling it with
     * the rest of the frame's data keeps paint() free of core calls. Empty
     * means "not resolved" -- the cell then falls back to its hex value,
     * matching Swift's `if let symbolic`.
     */
    std::array<QString, segments> m_symbols {};

    bool m_hex = true;
    bool m_symbolic = false;

    /* Background tint per signal row, in row order -- Address Bus, Data
     * Bus, then the four probe channels. An invalid entry, or a row past
     * the end of the list, keeps the view's own background: the list is a
     * preference, not a requirement, so a caller may colour some rows and
     * leave the rest alone.
     */
    std::array<QColor, numSignals> m_rowColors {};

    /* Sizing for the value text.
     *
     * The font shrinks until a value fits its cell, and the cell is left
     * empty once even minFontSize would not -- below that the text is not
     * readable anyway, and a row of clipped stubs reads as noise rather
     * than as data. maxFontSize is vAmiga's own 10pt mono: a cell is at
     * most 24px tall, so without a cap the height alone would allow ~20pt.
     */
    static constexpr qreal refFontSize = 100.0;
    static constexpr qreal maxFontSize = 10.0;
    static constexpr qreal minFontSize = 6.0;
    static constexpr qreal textPadding = 1.0;

    /* Longest value string the size table covers. A 24-bit hex value is 6
     * digits and a decimal one 8; the register names symbolic mode draws
     * are the long case. Anything longer is sized as if it were this long,
     * so it overflows its cell slightly rather than being mis-sized.
     */
    static constexpr int maxLabelLength = 12;

    /* The value font, measured once per paint() at refFontSize.
     *
     * It is monospaced, so a string's width is exactly its length times
     * charAdvance. That turns "which size fits this cell" into a division
     * instead of a QFontMetrics call -- worth having when the alternative
     * is measuring every cell in each of 6 rows on every frame.
     */
    QFont m_valueFont;
    qreal m_charAdvance = 0.0;
    qreal m_lineHeight = 0.0;
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
    QVariantList rowColors() const;
    void setRowColors(const QVariantList &value);
    QColor hairlineColor() const { return m_hairlineColor; }
    void setHairlineColor(const QColor &value);

  protected:

    void itemChange(ItemChange change, const ItemChangeData &value) override;

  private:

    void connectToWindow(class QQuickWindow *win);
    void disconnectFromWindow();

    // Re-samples the most recent 'segments' entries of the core's logic
    // analyzer ring buffer -- bus owner, address/data bus and the four probe
    // values all come out of the sample itself (see LogicView.cacheData()'s
    // owner->label/color switch, reproduced here) -- plus the DMA Debugger's
    // channel colors (read straight from the packed XRAY_DMA_COLORx option,
    // decoded the same way SiAmConfigController::dmaColor() does).
    void cacheData();

    /* The colour to draw a row's signal and values in.
     *
     * Derived from that row's background rather than configured next to it:
     * the two have to agree or the row is unreadable, and a second property
     * would only be a way for them to disagree. A tinted row is light, so
     * it takes dark ink; an untinted one keeps textColor, which is set from
     * the palette and already contrasts with the view's own background.
     */
    QColor inkFor(int channel) const;

    // Names what sits at the given address, for symbolic mode. Port of
    // vAmiga's ProxyExtensions.swift symbolize(addr:).
    QString symbolize(unsigned addr) const;

    // Measures the value font, which paint() does once per frame
    void setupValueFont();

    /* Returns the point size at which a string of the given length fits a
     * cell, or 0 when no size down to minFontSize does.
     */
    qreal fittedFontSize(int length, const QRectF &cell) const;

    void drawHairlines(QPainter *p, qreal w, qreal h, qreal dx) const;
    void drawLabels(QPainter *p, qreal w, qreal headerHeight, qreal dx) const;
    void drawRowBackgrounds(QPainter *p, qreal w, qreal headerHeight, qreal dy) const;
    void drawSignal(QPainter *p, int channel, qreal w, qreal headerHeight, qreal dx, qreal dy) const;
    void drawDataSegment(QPainter *p, const QRectF &r, int prev, int curr, int next, bool prevValid, bool currValid, bool nextValid, const QColor &ink) const;
    QString formatValue(int value, int bits) const;

  signals:

    void optionsChanged();
};
