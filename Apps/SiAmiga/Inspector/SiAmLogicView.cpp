// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "SiAmLogicView.h"
#include "SiAmController.h"
#include "VAmiga.h"

#include <QPainter>
#include <QPainterPath>
#include <QQuickWindow>
#include <QFontDatabase>
#include <QFontMetricsF>
#include <climits>

using namespace vamiga;

static constexpr int NoValue = INT_MIN;

SiAmLogicView::SiAmLogicView(QQuickItem *parent)
    : QQuickPaintedItem(parent)
{
    for (auto &row : m_data) row.fill(NoValue);
    m_hpos.fill(-1);
    m_vpos.fill(-1);
}

int
SiAmLogicView::columnAt(qreal x) const
{
    if (m_columns <= 0 || width() <= 0) return -1;

    const int column = int(x / (width() / m_columns));

    return column >= 0 && column < m_columns && m_hpos[column] >= 0 ? column : -1;
}

int
SiAmLogicView::vposAt(qreal x) const
{
    const int column = columnAt(x);
    return column < 0 ? -1 : m_vpos[column];
}

int
SiAmLogicView::hposAt(qreal x) const
{
    const int column = columnAt(x);
    return column < 0 ? -1 : m_hpos[column];
}

void
SiAmLogicView::setHex(bool value) { if (m_hex != value) { m_hex = value; emit optionsChanged(); update(); } }

void
SiAmLogicView::setSymbolic(bool value) { if (m_symbolic != value) { m_symbolic = value; emit optionsChanged(); update(); } }

void
SiAmLogicView::setTextColor(const QColor &value) { if (m_textColor != value) { m_textColor = value; emit optionsChanged(); update(); } }

QVariantList
SiAmLogicView::rowColors() const
{
    QVariantList list;
    for (const auto &color : m_rowColors) list.append(color);
    return list;
}

void
SiAmLogicView::setRowColors(const QVariantList &value)
{
    std::array<QColor, numSignals> colors {};

    // Extra entries are ignored and missing ones stay invalid, so a caller
    // can hand over a short list and tint only the rows it cares about
    for (int i = 0; i < numSignals && i < value.size(); i++) {
        colors[i] = value[i].value<QColor>();
    }

    if (colors == m_rowColors) return;

    m_rowColors = colors;
    emit optionsChanged();
    update();
}

QColor
SiAmLogicView::inkFor(int channel) const
{
    const QColor &background = m_rowColors[channel];

    if (!background.isValid()) return m_textColor;

    /* lightnessF() rather than a fixed dark: a caller is free to tint a row
     * with something dark, and the ink has to follow it rather than assume
     * the pastels this was built for. The two shades are near-black and
     * near-white instead of pure, which is what keeps the antialiased
     * diagonals from looking harsh against the tint.
     */
    return background.lightnessF() > 0.5 ? QColor(0x1E, 0x1E, 0x1E) : QColor(0xEC, 0xEC, 0xEC);
}

void
SiAmLogicView::setHairlineColor(const QColor &value) { if (m_hairlineColor != value) { m_hairlineColor = value; emit optionsChanged(); update(); } }

void
SiAmLogicView::itemChange(ItemChange change, const ItemChangeData &value)
{
    if (change == ItemSceneChange) {

        disconnectFromWindow();
        if (value.window) connectToWindow(value.window);
    }

    QQuickPaintedItem::itemChange(change, value);
}

void
SiAmLogicView::connectToWindow(QQuickWindow *win)
{
    // Re-sample the current scanline and repaint once per rendered frame,
    // exactly like SiC64DmaView's texture grab -- naturally idle while the
    // Bus inspector window is hidden, since a hidden window emits no frames.
    m_frameConnection = connect(win, &QQuickWindow::frameSwapped, this, [this]() {
        cacheData();
        update();
    });
}

void
SiAmLogicView::disconnectFromWindow()
{
    if (m_frameConnection) {

        disconnect(m_frameConnection);
        m_frameConnection = QMetaObject::Connection();
    }
}

void
SiAmLogicView::cacheData()
{
    auto &core = SiAmController::core();

    /* Re-sample only when the recording has actually moved on.
     *
     * Two API calls answer that: how many cycles are held, and which cycle
     * the newest of them is. While the machine runs they change constantly;
     * while it is paused they change only when the user steps, which is
     * precisely when the view must update. Returning before the arrays are
     * cleared is what leaves the previous picture on screen in between.
     */
    isize count = 0;
    int newestVpos = -1, newestHpos = -1;

    try {

        count = core.agnus.logicAnalyzer.getTraceCount();

        if (count > 0) {

            const auto newest = core.agnus.logicAnalyzer.getTrace(count - 1);
            newestVpos = int(newest.vpos);
            newestHpos = int(newest.hpos);
        }

    } catch (...) { return; }

    if (count == m_lastCount && newestVpos == m_lastVpos && newestHpos == m_lastHpos) return;

    m_lastCount = count;
    m_lastVpos = newestVpos;
    m_lastHpos = newestHpos;

    /* Nothing is drawn unless a probe is attached.
     *
     * The bus rows would otherwise keep filling -- Agnus produces bus data
     * whether or not anyone probes anything -- and a panel showing traffic
     * on channels the user never connected reads as a fault rather than as
     * a feature.
     */
    bool probed = false;
    try {
        for (int i = 0; i < 4 && !probed; i++) {
            probed = core.get(Opt(int(Opt::LA_PROBE0) + i)) != i64(Probe::NONE);
        }
    } catch (...) { }

    for (int i = 0; i < segments; i++) {

        m_labels[i].clear();
        m_colors[i] = QColor();
        m_symbols[i].clear();
        m_hpos[i] = -1;
        m_vpos[i] = -1;
    }
    for (auto &row : m_data) row.fill(NoValue);
    m_columns = 0;

    if (!probed) return;

    /* The whole ring, oldest cycle leftmost.
     *
     * Not the current scanline: the window spans every cycle the core still
     * holds, so it runs straight through line and frame boundaries. Each
     * column is labelled from its own entry rather than from its index,
     * which is what lets it do that without the labels going wrong.
     */
    if (count > segments) count = segments;
    if (count <= 0) return;

    // Owner-tint colors, decoded from the packed XRAY_DMA_COLORx options
    // the same way SiAmConfigController::dmaColor() does (r<<24|g<<16|b<<8
    // -- see Core/Components/Denise/Colors.h's RgbColor(u32) constructor).
    auto ownerColor = [&core](Opt opt) -> QColor {
        u32 v = 0;
        try { v = (u32)core.get(opt); } catch (...) { }
        return QColor((v >> 24) & 0xFF, (v >> 16) & 0xFF, (v >> 8) & 0xFF);
    };

    const QColor colCopper = ownerColor(Opt::XRAY_COLOR0);
    const QColor colBlitter = ownerColor(Opt::XRAY_COLOR1);
    const QColor colDisk = ownerColor(Opt::XRAY_COLOR2);
    const QColor colAudio = ownerColor(Opt::XRAY_COLOR3);
    const QColor colSprites = ownerColor(Opt::XRAY_COLOR4);
    const QColor colBitplanes = ownerColor(Opt::XRAY_COLOR5);
    const QColor colCPU = ownerColor(Opt::XRAY_COLOR6);
    const QColor colRefresh = ownerColor(Opt::XRAY_COLOR7);

    for (isize i = 0; i < count; i++) {

        LogicAnalyzerTrace trace;
        try { trace = core.agnus.logicAnalyzer.getTrace(i); } catch (...) { break; }

        const int col = int(i);

        m_hpos[col] = int(trace.hpos);
        m_vpos[col] = int(trace.vpos);
        m_columns = col + 1;

        QString label;
        QColor color;

        switch (trace.busOwner) {

            case BusOwner::CPU:     label = "CPU";  color = colCPU; break;
            case BusOwner::REFRESH: label = "REF";  color = colRefresh; break;
            case BusOwner::DISK:    label = "DSK";  color = colDisk; break;
            case BusOwner::AUD0:    label = "AUD0"; color = colAudio; break;
            case BusOwner::AUD1:    label = "AUD1"; color = colAudio; break;
            case BusOwner::AUD2:    label = "AUD2"; color = colAudio; break;
            case BusOwner::AUD3:    label = "AUD3"; color = colAudio; break;
            case BusOwner::BPL1:    label = "BPL1"; color = colBitplanes; break;
            case BusOwner::BPL2:    label = "BPL2"; color = colBitplanes; break;
            case BusOwner::BPL3:    label = "BPL3"; color = colBitplanes; break;
            case BusOwner::BPL4:    label = "BPL4"; color = colBitplanes; break;
            case BusOwner::BPL5:    label = "BPL5"; color = colBitplanes; break;
            case BusOwner::BPL6:    label = "BPL6"; color = colBitplanes; break;
            case BusOwner::SPRITE0: label = "SPR0"; color = colSprites; break;
            case BusOwner::SPRITE1: label = "SPR1"; color = colSprites; break;
            case BusOwner::SPRITE2: label = "SPR2"; color = colSprites; break;
            case BusOwner::SPRITE3: label = "SPR3"; color = colSprites; break;
            case BusOwner::SPRITE4: label = "SPR4"; color = colSprites; break;
            case BusOwner::SPRITE5: label = "SPR5"; color = colSprites; break;
            case BusOwner::SPRITE6: label = "SPR6"; color = colSprites; break;
            case BusOwner::SPRITE7: label = "SPR7"; color = colSprites; break;
            case BusOwner::COPPER:  label = "COP";  color = colCopper; break;
            case BusOwner::BLITTER: label = "BLT";  color = colBlitter; break;
            case BusOwner::BLOCKED: label = "BLK";  color = QColor(Qt::red); break;

            default:
                // Unowned: the address and data lines hold nothing of theirs
                break;
        }

        if (!label.isEmpty()) {

            m_labels[col] = label;
            m_colors[col] = color;

            m_data[0][col] = (int)trace.addrBus;
            m_data[1][col] = (int)trace.dataBus;
        }

        for (int c = 2; c < numSignals; c++) {

            const isize value = trace.channel[c - 2];
            m_data[c][col] = value >= 0 ? (int)value : NoValue;
        }

        if (m_symbolic && m_data[0][col] != NoValue) {
            m_symbols[col] = symbolize((unsigned)m_data[0][col]);
        }
    }
}

QString
SiAmLogicView::symbolize(unsigned addr) const
{
    auto &core = SiAmController::core();

    MemSrc src = MemSrc::NONE;
    try { src = core.mem.debugger.getMemSrc(Accessor::CPU, addr); } catch (...) { return {}; }

    switch (src) {

        case MemSrc::NONE:              return "-";
        case MemSrc::CHIP:
        case MemSrc::CHIP_MIRROR:       return "CHIP";
        case MemSrc::SLOW:
        case MemSrc::SLOW_MIRROR:       return "SLOW";
        case MemSrc::FAST:              return "FAST";
        case MemSrc::CIA:
        case MemSrc::CIA_MIRROR:        return "CIA";
        case MemSrc::RTC:               return "RTC";
        case MemSrc::AUTOCONF:          return "ACONF";
        case MemSrc::ZOR:               return "ZORRO";
        case MemSrc::ROM:
        case MemSrc::ROM_MIRROR:        return "ROM";
        case MemSrc::WOM:               return "WOM";
        case MemSrc::EXT:               return "ROM";

        case MemSrc::CUSTOM:
        case MemSrc::CUSTOM_MIRROR:

            // The one source that names the individual address rather than
            // the region it falls in -- DMACON, BPLCON0, and so on
            try { return QString::fromLatin1(core.mem.debugger.regName(addr)); } catch (...) { }
            return {};
    }

    return {};
}

QString
SiAmLogicView::formatValue(int value, int bits) const
{
    if (m_hex) {

        int digits = (bits + 3) / 4;
        return QString("%1").arg((unsigned)value, digits, 16, QChar('0')).toUpper();

    } else {

        return QString::number(value);
    }
}

void
SiAmLogicView::setupValueFont()
{
    /* Monospaced, like LogicView.swift's own `mono`. Not only for looks:
     * every cell in a row is the same width, so a fixed advance makes the
     * fitted size a function of the string's length alone -- see
     * fittedFontSize(), and drawSignal()'s per-row table built on it.
     */
    m_valueFont = QFontDatabase::systemFont(QFontDatabase::FixedFont);
    m_valueFont.setStyleHint(QFont::Monospace);
    m_valueFont.setPointSizeF(refFontSize);

    const QFontMetricsF fm(m_valueFont);

    /* The widest glyph we might draw, not a representative one.
     *
     * On macOS the request above resolves to Menlo and every character
     * below has the same advance, so the maximum simply is that advance.
     * Elsewhere a fixed-pitch request can fall back to a proportional face
     * -- measured, that makes sizing by length underestimate a string by up
     * to a third, and the value spills out of its cell. Taking the widest
     * glyph errs the other way: the text comes out slightly small, which is
     * the harmless direction to be wrong in.
     */
    static const QString alphabet = QStringLiteral("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ-");

    m_charAdvance = 0.0;
    for (const QChar c : alphabet) m_charAdvance = qMax(m_charAdvance, fm.horizontalAdvance(c));

    m_lineHeight = fm.height();
}

qreal
SiAmLogicView::fittedFontSize(int length, const QRectF &cell) const
{
    if (length <= 0 || m_charAdvance <= 0.0 || m_lineHeight <= 0.0) return 0.0;

    const qreal usableWidth = cell.width() - 2 * textPadding;
    if (usableWidth <= 0.0) return 0.0;

    // Both measurements scale linearly with point size, so the size that
    // just fits is a ratio against the reference rather than a search
    const qreal byWidth = refFontSize * usableWidth / (length * m_charAdvance);
    const qreal byHeight = refFontSize * cell.height() / m_lineHeight;

    const qreal size = qMin(qMin(byWidth, byHeight), maxFontSize);

    // Below the floor the cell is left empty rather than shrunk further
    return size >= minFontSize ? size : 0.0;
}

void
SiAmLogicView::paint(QPainter *painter)
{
    qreal w = width();
    qreal h = height();
    if (w <= 0 || h <= 0) return;

    /* Off by default, and deliberately.
     *
     * Almost everything here is axis-aligned -- 228 vertical hairlines, the
     * flat top and bottom of each hexagon, the mid-line of an empty cell --
     * and antialiasing those spreads a one-pixel line across two columns of
     * half-grey instead of drawing it. Only the hexagon's diagonal notches
     * gain from it, so drawDataSegment() turns it on just for those.
     */
    painter->setRenderHint(QPainter::Antialiasing, false);
    setupValueFont();

    // Nothing recorded yet -- the grid would be meaningless and dx infinite
    if (m_columns <= 0) return;

    qreal headerHeight = h / (numSignals + 1);
    qreal dx = w / m_columns;
    qreal dy = (h - headerHeight) / numSignals;

    // Under everything else: the tints are a backdrop, not an overlay
    drawRowBackgrounds(painter, w, headerHeight, dy);

    drawHairlines(painter, w, h, dx);
    drawLabels(painter, w, headerHeight, dx);
    for (int c = 0; c < numSignals; c++) drawSignal(painter, c, w, headerHeight, dx, dy);
}

void
SiAmLogicView::drawRowBackgrounds(QPainter *p, qreal w, qreal headerHeight, qreal dy) const
{
    for (int c = 0; c < numSignals; c++) {

        const QColor &color = m_rowColors[c];
        if (!color.isValid()) continue;

        /* The full row height, not the inset the signal is drawn in: the
         * bands are meant to read as one continuous stripe per row, the way
         * a track lane does, so they meet with no gap between them.
         */
        p->fillRect(QRectF(0, headerHeight + c * dy, w, dy), color);
    }
}

void
SiAmLogicView::drawHairlines(QPainter *p, qreal w, qreal h, qreal dx) const
{
    Q_UNUSED(w)

    QPen pen(m_hairlineColor);
    pen.setWidthF(0.5);
    p->setPen(pen);

    for (int i = 1; i < m_columns; i++) {

        qreal x = i * dx;
        p->drawLine(QPointF(x, 0), QPointF(x, h));
    }
}

void
SiAmLogicView::drawLabels(QPainter *p, qreal w, qreal headerHeight, qreal dx) const
{
    Q_UNUSED(w)

    QFont font = p->font();
    p->setFont(font);
    QFontMetricsF fm(font);

    for (int i = 0; i < m_columns; i++) {

        qreal x = i * dx;

        /* The DMA cycle number, upper half of the header row.
         *
         * Taken from the column's own entry, not from its index: the window
         * spans several scanlines, so the numbering restarts partway along
         * and the two stopped agreeing once the view began showing the whole
         * ring rather than a single line.
         */
        if (m_hpos[i] < 0) continue;

        QRectF numRect(x, 0, dx, 0.5 * headerHeight);
        QString numText = m_hex ? QString("%1").arg((unsigned)m_hpos[i], 2, 16, QChar('0')).toUpper()
                                 : QString::number(m_hpos[i]);
        p->setPen(m_textColor);
        if (fm.horizontalAdvance(numText) <= numRect.width()) {
            p->drawText(numRect, Qt::AlignCenter, numText);
        }

        if (!m_labels[i].isEmpty()) {

            // Small color bar, then the owner label, lower half of the
            // header row (immediately above the Address Bus row).
            QRectF barRect(x, 0.5 * headerHeight - 2, dx, 4);
            p->fillRect(barRect, m_colors[i]);

            QRectF labelRect(x, 0.5 * headerHeight, dx, 0.5 * headerHeight);
            if (fm.horizontalAdvance(m_labels[i]) <= labelRect.width()) {
                p->setPen(m_textColor);
                p->drawText(labelRect, Qt::AlignCenter, m_labels[i]);
            }
        }
    }
}

void
SiAmLogicView::drawSignal(QPainter *p, int channel, qreal w, qreal headerHeight, qreal dx, qreal dy) const
{
    Q_UNUSED(w)

    const int bits = bitWidth[channel];
    const QColor ink = inkFor(channel);
    const qreal rowY = headerHeight + channel * dy;
    const qreal margin = qMax(0.0, (dy - 24.0) / 2.0);
    const QRectF cell(0, 0, dx, dy - 2 * margin);

    /* Every cell in this row is the same size, and a string is sized from
     * its length alone (see setupValueFont), so there are only as many
     * answers as there are lengths. They are worked out once here and
     * looked up per cell, which keeps the inner loop free of both the
     * arithmetic and any font measurement.
     *
     * Index 0 stays 0: an empty string has nothing to draw.
     */
    std::array<qreal, maxLabelLength + 1> sizeFor {};
    for (int n = 1; n <= maxLabelLength; n++) sizeFor[n] = fittedFontSize(n, cell);

    // Only reapplied when it actually changes -- in hex every value in a row
    // is the same length, so this is usually set once for the whole row
    qreal appliedSize = 0.0;

    for (int i = 0; i < m_columns; i++) {

        QRectF r(i * dx, rowY + margin, dx, cell.height());

        int prev = i > 0 ? m_data[channel][i - 1] : NoValue;
        int curr = m_data[channel][i];
        int next = i + 1 < m_columns ? m_data[channel][i + 1] : NoValue;

        drawDataSegment(p, r, prev, curr, next,
                         i > 0 && prev != NoValue, curr != NoValue, i + 1 < m_columns && next != NoValue,
                         ink);

        if (curr == NoValue) continue;

        /* In symbolic mode the address bus names its target instead of
         * showing the number. Only when the lookup produced something:
         * an address in no mapped region keeps its hex value, which is
         * Swift's `if let symbolic` fallthrough.
         */
        const bool named = channel == 0 && m_symbolic && !m_symbols[i].isEmpty();
        const QString label = named ? m_symbols[i] : formatValue(curr, bits);

        const int length = int(qMin<qsizetype>(label.size(), maxLabelLength));
        const qreal size = sizeFor[length];

        // Too small to read at any size we are willing to use: leave it empty
        if (size <= 0.0) continue;

        if (size != appliedSize) {

            QFont font = m_valueFont;
            font.setPointSizeF(size);
            p->setFont(font);
            appliedSize = size;
        }

        p->setPen(ink);
        p->drawText(r, Qt::AlignCenter, label);
    }
}

void
SiAmLogicView::drawDataSegment(QPainter *p, const QRectF &r, int prev, int curr, int next,
                                bool prevValid, bool currValid, bool nextValid, const QColor &ink) const
{
    QPen pen(ink);
    pen.setWidthF(1.5);
    p->setPen(pen);

    qreal x1 = r.left(), y1 = r.top(), x2 = r.right(), y2 = r.bottom();

    if (!currValid) {

        // Horizontal: nothing to smooth, and smoothing would only blur it
        p->drawLine(QPointF(x1, r.center().y()), QPointF(x2, r.center().y()));
        return;
    }

    // Open hexagon: flat top/bottom edges with a diagonal notch at either
    // end, collapsed to a mid-height point where the neighboring cell holds
    // the same value -- so a run of unchanged values visually merges into
    // one continuous band. See LogicView.drawDataSegment's own diagram.
    qreal m = 0.1 * r.width();
    bool sameAsPrev = prevValid && prev == curr;
    bool sameAsNext = nextValid && next == curr;

    QPointF p1(x1, sameAsPrev ? y1 : r.center().y());
    QPointF p2(x1 + m, y1);
    QPointF p3(x2 - m, y1);
    QPointF p4(x2, sameAsNext ? y1 : r.center().y());
    QPointF p5(x2, sameAsNext ? y2 : r.center().y());
    QPointF p6(x2 - m, y2);
    QPointF p7(x1 + m, y2);
    QPointF p8(x1, sameAsPrev ? y2 : r.center().y());

    QPainterPath top;
    top.moveTo(p1); top.lineTo(p2); top.lineTo(p3); top.lineTo(p4);
    QPainterPath bottom;
    bottom.moveTo(p5); bottom.lineTo(p6); bottom.lineTo(p7); bottom.lineTo(p8);

    /* The notches at either end are the only diagonals in the view, and
     * without smoothing they are what reads as a staircase. CoreGraphics
     * antialiases them by default, which is why vAmiga's look cleaner --
     * not, as it appears, because it renders at a higher resolution: a
     * QQuickPaintedItem already paints into a device scaled by the window's
     * pixel ratio, so both are drawing at 2x on a 2x display.
     */
    p->setRenderHint(QPainter::Antialiasing, true);
    p->drawPath(top);
    p->drawPath(bottom);
    p->setRenderHint(QPainter::Antialiasing, false);
}
