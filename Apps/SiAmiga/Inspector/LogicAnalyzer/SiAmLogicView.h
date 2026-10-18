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
#include <QVariantMap>
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

    // The number of samples (columns) the view shows
    Q_PROPERTY(int segmentCount READ segmentCount CONSTANT)
    Q_PROPERTY(bool hex READ hex WRITE setHex NOTIFY optionsChanged)
    Q_PROPERTY(bool padded READ padded WRITE setPadded NOTIFY optionsChanged)
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

    // Where each column's sample was recorded, for the header row (hpos)
    // and the hover tooltip (all three). INT_MIN in m_positions marks a
    // column with no sample behind it, and the other two are then unset.
    std::array<int, segments> m_positions {};
    std::array<int, segments> m_lines {};
    std::array<qint64, segments> m_frames {};

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
    bool m_padded = false;
    bool m_symbolic = false;

    /* Background tint per signal row, in row order -- Address Bus, Data
     * Bus, then the four probe channels. An invalid entry, or a row past
     * the end of the list, keeps the view's own background: the list is a
     * preference, not a requirement, so a caller may colour some rows and
     * leave the rest alone.
     */
    std::array<QColor, numSignals> m_rowColors {};

    /* The value text is drawn in one small, fixed size. A value that does
     * not fit its cell is elided ("...") rather than shrunk, so the text
     * looks the same at every zoom level.
     */
    static constexpr qreal fontSize = 9.0;
    static constexpr qreal textPadding = 2.0;

    // Indicates for each row whether it has a signal to show. The address
    // and data bus always do; a probe channel only if one is selected.
    std::array<bool, numSignals> m_active {};

    QFont m_valueFont;
    qreal m_lineHeight = 0.0;
    QColor m_textColor = QColor(Qt::black);
    QColor m_hairlineColor = QColor(Qt::gray);

  public:

    explicit SiAmLogicView(QQuickItem *parent = nullptr);

    void paint(QPainter *painter) override;

    /* Describes the sample drawn at the given point, for the hover tooltip:
     * { frame, vpos, hpos }, or an empty map where the column carries no
     * sample or x falls outside the view.
     *
     * When y falls on a signal row that has a value there, the map also
     * carries 'value' -- that one cell, already formatted per the panel's
     * hex/padded setting. Rows without a value at this column, and the
     * header row, leave the key out rather than reporting a placeholder.
     */
    int segmentCount() const { return segments; }

    Q_INVOKABLE QVariantMap sampleAt(qreal x, qreal y) const;

    // Reads the trace again and repaints. Called when the controller says
    // that the trace may have changed.
    Q_INVOKABLE void refresh();

    bool hex() const { return m_hex; }
    void setHex(bool value);
    bool padded() const { return m_padded; }
    void setPadded(bool value);
    bool symbolic() const { return m_symbolic; }
    void setSymbolic(bool value);
    QColor textColor() const { return m_textColor; }
    void setTextColor(const QColor &value);
    QVariantList rowColors() const;
    void setRowColors(const QVariantList &value);
    QColor hairlineColor() const { return m_hairlineColor; }
    void setHairlineColor(const QColor &value);

  protected:


  private:


    // Re-samples the most recent 'segments' entries of the core's logic
    // analyzer ring buffer -- bus owner, address/data bus and the four probe
    // values all come out of the sample itself (see LogicView.cacheData()'s
    // owner->label/color switch, reproduced here) -- plus the DMA Debugger's
    // channel colors (read straight from the packed XRAY_COLORx option,
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

    // Sets up the value font, which paint() does once per frame
    void setupValueFont();

    // Draws a text centered in a cell, elided if it does not fit
    void drawElided(QPainter *p, const QRectF &cell, const QString &text) const;

    void drawHairlines(QPainter *p, qreal w, qreal h, qreal dx) const;
    void drawLabels(QPainter *p, qreal w, qreal headerHeight, qreal dx) const;
    void drawRowBackgrounds(QPainter *p, qreal w, qreal headerHeight, qreal dy) const;
    void drawSignal(QPainter *p, int channel, qreal w, qreal headerHeight, qreal dx, qreal dy) const;
    void drawDataSegment(QPainter *p, const QRectF &r, int prev, int curr, int next, bool prevValid, bool currValid, bool nextValid, const QColor &ink) const;
    QString formatValue(int value, int bits) const;

  signals:

    void optionsChanged();
};
