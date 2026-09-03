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
#include <QFontMetricsF>
#include <climits>

using namespace vamiga;

static constexpr int NoValue = INT_MIN;

SiAmLogicView::SiAmLogicView(QQuickItem *parent)
    : QQuickPaintedItem(parent)
{
    for (auto &row : m_data) row.fill(NoValue);
}

void
SiAmLogicView::setHex(bool value) { if (m_hex != value) { m_hex = value; emit optionsChanged(); update(); } }

void
SiAmLogicView::setSymbolic(bool value) { if (m_symbolic != value) { m_symbolic = value; emit optionsChanged(); update(); } }

void
SiAmLogicView::setTextColor(const QColor &value) { if (m_textColor != value) { m_textColor = value; emit optionsChanged(); update(); } }

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

    long hpos = 0;
    try { hpos = core.amiga.getInfo().hpos; } catch (...) { return; }
    if (hpos < 0) hpos = 0;
    if (hpos > segments) hpos = segments;

    for (int i = 0; i < segments; i++) { m_labels[i].clear(); m_colors[i] = QColor(); }
    for (auto &row : m_data) row.fill(NoValue);

    LogicAnalyzerInfo laInfo {};
    try { laInfo = core.agnus.logicAnalyzer.getInfo(); } catch (...) { return; }
    if (!laInfo.busOwner || !laInfo.addrBus || !laInfo.dataBus) return;

    // Owner-tint colors, decoded from the packed DMA_DEBUG_COLORx options
    // the same way SiAmConfigController::dmaColor() does (r<<24|g<<16|b<<8
    // -- see Core/Components/Denise/Colors.h's RgbColor(u32) constructor).
    auto ownerColor = [&core](Opt opt) -> QColor {
        u32 v = 0;
        try { v = (u32)core.get(opt); } catch (...) { }
        return QColor((v >> 24) & 0xFF, (v >> 16) & 0xFF, (v >> 8) & 0xFF);
    };

    const QColor colCopper = ownerColor(Opt::DMA_DEBUG_COLOR0);
    const QColor colBlitter = ownerColor(Opt::DMA_DEBUG_COLOR1);
    const QColor colDisk = ownerColor(Opt::DMA_DEBUG_COLOR2);
    const QColor colAudio = ownerColor(Opt::DMA_DEBUG_COLOR3);
    const QColor colSprites = ownerColor(Opt::DMA_DEBUG_COLOR4);
    const QColor colBitplanes = ownerColor(Opt::DMA_DEBUG_COLOR5);
    const QColor colCPU = ownerColor(Opt::DMA_DEBUG_COLOR6);
    const QColor colRefresh = ownerColor(Opt::DMA_DEBUG_COLOR7);

    for (long i = 0; i < hpos; i++) {

        BusOwner owner = laInfo.busOwner[i];
        QString label;
        QColor color;

        switch (owner) {

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
            default: continue; // NONE, BPL7, BPL8 -- unlabeled, matching Swift
        }

        m_labels[i] = label;
        m_colors[i] = color;

        m_data[0][i] = (int)laInfo.addrBus[i];
        m_data[1][i] = (int)laInfo.dataBus[i];
    }

    for (int c = 2; c < numSignals; c++) {

        const isize *values = laInfo.channel[c - 2];
        if (!values) continue;

        for (long i = 0; i < hpos; i++) {

            isize value = values[i];
            m_data[c][i] = value >= 0 ? (int)value : NoValue;
        }
    }
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
SiAmLogicView::paint(QPainter *painter)
{
    qreal w = width();
    qreal h = height();
    if (w <= 0 || h <= 0) return;

    painter->setRenderHint(QPainter::Antialiasing, false);

    qreal headerHeight = h / (numSignals + 1);
    qreal dx = w / segments;
    qreal dy = (h - headerHeight) / numSignals;

    drawHairlines(painter, w, h, dx);
    drawLabels(painter, w, headerHeight, dx);
    for (int c = 0; c < numSignals; c++) drawSignal(painter, c, w, headerHeight, dx, dy);
}

void
SiAmLogicView::drawHairlines(QPainter *p, qreal w, qreal h, qreal dx) const
{
    Q_UNUSED(w)

    QPen pen(m_hairlineColor);
    pen.setWidthF(0.5);
    p->setPen(pen);

    for (int i = 1; i < segments; i++) {

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

    for (int i = 0; i < segments; i++) {

        qreal x = i * dx;

        // Cycle number, upper half of the header row.
        QRectF numRect(x, 0, dx, 0.5 * headerHeight);
        QString numText = m_hex ? QString("%1").arg((unsigned)i, 2, 16, QChar('0')).toUpper()
                                 : QString::number(i);
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
    int bits = bitWidth[channel];
    qreal rowY = headerHeight + channel * dy;
    qreal margin = qMax(0.0, (dy - 24.0) / 2.0);

    QFontMetricsF fm(p->font());

    for (int i = 0; i < segments; i++) {

        QRectF r(i * dx, rowY + margin, dx, dy - 2 * margin);

        int prev = i > 0 ? m_data[channel][i - 1] : NoValue;
        int curr = m_data[channel][i];
        int next = i + 1 < segments ? m_data[channel][i + 1] : NoValue;

        drawDataSegment(p, r, prev, curr, next,
                         i > 0 && prev != NoValue, curr != NoValue, i + 1 < segments && next != NoValue);

        if (curr != NoValue) {

            QString label = formatValue(curr, bits);
            p->setPen(m_textColor);

            if (fm.horizontalAdvance(label) <= r.width()) {

                p->drawText(r, Qt::AlignCenter, label);

            } else {

                p->save();
                p->setClipRect(r);
                p->drawText(QRectF(r.left(), r.top(), fm.horizontalAdvance(label) + 4, r.height()),
                             Qt::AlignVCenter | Qt::AlignLeft, label);
                p->restore();
            }
        }
    }
    Q_UNUSED(w)
}

void
SiAmLogicView::drawDataSegment(QPainter *p, const QRectF &r, int prev, int curr, int next,
                                bool prevValid, bool currValid, bool nextValid) const
{
    QPen pen(m_textColor);
    pen.setWidthF(1.5);
    p->setPen(pen);

    qreal x1 = r.left(), y1 = r.top(), x2 = r.right(), y2 = r.bottom();

    if (!currValid) {

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

    p->drawPath(top);
    p->drawPath(bottom);
}
