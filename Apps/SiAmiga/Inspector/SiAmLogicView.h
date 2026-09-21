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
    Q_PROPERTY(QVariantList rowColors READ rowColors WRITE setRowColors NOTIFY optionsChanged)

    /* What the pointer is currently over, for the tooltip in QML.
     *
     * The view draws itself, so there is no child item per cell for a
     * ToolTip to attach to. Instead the hovered cycle is published here and
     * the panel binds a SiToolTip to it -- hoverValid gates the tooltip's
     * visibility, hoverX/hoverY place it.
     */
    Q_PROPERTY(bool hoverValid READ hoverValid NOTIFY hoverChanged)
    Q_PROPERTY(int hoverVpos READ hoverVpos NOTIFY hoverChanged)
    Q_PROPERTY(int hoverHpos READ hoverHpos NOTIFY hoverChanged)
    Q_PROPERTY(qreal hoverX READ hoverX NOTIFY hoverChanged)
    Q_PROPERTY(qreal hoverY READ hoverY NOTIFY hoverChanged)
    Q_PROPERTY(QColor hairlineColor READ hairlineColor WRITE setHairlineColor NOTIFY optionsChanged)

    /* Columns the view can hold.
     *
     * One per recorded DMA cycle, so this has to match the core's ring --
     * LogicAnalyzer::traceLines * HPOS_CNT. It cannot be taken from there
     * directly (the app sees only the API, not the class), so the count is
     * checked against getTraceCapacity() at sampling time and clamped.
     */
    static constexpr int segments = 3 * 228;
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

    /* What the address bus is pointing at, per cycle, for symbolic mode.
     *
     * Resolved in cacheData() rather than while drawing, which is where
     * LogicView.swift does it: naming an address is a core lookup, and the
     * paint path runs over every one of the 228 cycles. Sampling it with
     * the rest of the frame's data keeps paint() free of core calls. Empty
     * means "not resolved" -- the cell then falls back to its hex value,
     * matching Swift's `if let symbolic`.
     */
    std::array<QString, segments> m_symbols {};

    /* Which DMA cycle each column holds.
     *
     * A column's index is its position in the ring, not its cycle number:
     * the window spans several scanlines, so hpos restarts partway along and
     * vpos changes with it. Both are carried per column -- hpos labels the
     * column, vpos answers the tooltip. -1 marks a column with no entry.
     */
    std::array<int, segments> m_hpos {};
    std::array<int, segments> m_vpos {};

    // Columns actually holding a recorded cycle, left-aligned
    int m_columns = 0;

    // Column the pointer is over, or -1
    int m_hoverColumn = -1;
    qreal m_hoverX = 0;
    qreal m_hoverY = 0;

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
     * is measuring 228 cells in each of 6 rows on every frame.
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

    bool hoverValid() const { return m_hoverColumn >= 0; }
    int hoverVpos() const { return hoverValid() ? m_vpos[m_hoverColumn] : -1; }
    int hoverHpos() const { return hoverValid() ? m_hpos[m_hoverColumn] : -1; }
    qreal hoverX() const { return m_hoverX; }
    qreal hoverY() const { return m_hoverY; }

  protected:

    void itemChange(ItemChange change, const ItemChangeData &value) override;
    void hoverMoveEvent(QHoverEvent *event) override;
    void hoverLeaveEvent(QHoverEvent *event) override;

  private:

    void connectToWindow(class QQuickWindow *win);
    void disconnectFromWindow();

    // Re-samples the current scanline's bus-owner/address/data/probe data
    // from the core (see LogicView.cacheData()'s owner->label/color switch,
    // reproduced here) and the DMA Debugger's channel colors (read straight
    // from the packed XRAY_DMA_COLORx option, decoded the same way
    // SiAmConfigController::dmaColor() does).
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
    void hoverChanged();
};
