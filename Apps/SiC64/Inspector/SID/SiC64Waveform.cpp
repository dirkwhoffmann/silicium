// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "SiC64Waveform.h"
#include "C64Controller.h"
#include "VirtualC64.h"

#include <QQuickWindow>
#include <QSGSimpleTextureNode>

SiC64Waveform::SiC64Waveform(QQuickItem *parent)
    : QQuickItem(parent)
{
    setFlag(ItemHasContents, true);
}

void
SiC64Waveform::setSid(int value)
{
    if (m_sid != value) {

        m_sid = value;
        emit sidChanged();
    }
}

void
SiC64Waveform::itemChange(ItemChange change, const ItemChangeData &value)
{
    if (change == ItemSceneChange) {

        disconnectFromWindow();
        if (value.window) connectToWindow(value.window);
    }

    QQuickItem::itemChange(change, value);
}

void
SiC64Waveform::connectToWindow(QQuickWindow *win)
{
    m_frameConnection = connect(win, &QQuickWindow::frameSwapped, this, [this]() {
        grab();
        update();
    });
}

void
SiC64Waveform::disconnectFromWindow()
{
    if (m_frameConnection) {

        disconnect(m_frameConnection);
        m_frameConnection = QMetaObject::Connection();
    }
}

void
SiC64Waveform::grab()
{
    qreal dpr = window() ? window()->effectiveDevicePixelRatio() : 1.0;
    int w = qRound(width() * dpr);
    int h = qRound(height() * dpr);

    if (w <= 0 || h <= 0) return;

    if (w != texW || h != texH) {
        texW = w;
        texH = h;
        buffer.assign(size_t(w) * h, 0);
    }

    // The gray drawing color, in the same ARGB32 layout the texture uses.
    const u32 color = 0xFF808080;

    maxAmp = C64Controller::core().sid.draw(buffer.data(), texW, texH, maxAmp, color, m_sid);
}

QSGNode *
SiC64Waveform::updatePaintNode(QSGNode *node, UpdatePaintNodeData *)
{
    if (buffer.empty() || texW <= 0 || texH <= 0) {
        delete node;
        return nullptr;
    }

    auto *textureNode = static_cast<QSGSimpleTextureNode *>(node);
    if (!textureNode) {
        textureNode = new QSGSimpleTextureNode();
        textureNode->setOwnsTexture(true);
    }

    QImage img(reinterpret_cast<const uchar *>(buffer.data()),
               texW, texH, QImage::Format_ARGB32);

    textureNode->setTexture(window()->createTextureFromImage(img));
    textureNode->setRect(boundingRect());
    textureNode->setFiltering(QSGTexture::Linear);

    return textureNode;
}
