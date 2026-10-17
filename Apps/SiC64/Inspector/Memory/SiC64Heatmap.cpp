// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "SiC64Heatmap.h"
#include "C64Controller.h"
#include "VirtualC64.h"

#include <QQuickWindow>
#include <QSGSimpleTextureNode>

SiC64Heatmap::SiC64Heatmap(QQuickItem *parent)
    : QQuickItem(parent), buffer(Width * Height)
{
    setFlag(ItemHasContents, true);
}

void
SiC64Heatmap::itemChange(ItemChange change, const ItemChangeData &value)
{
    if (change == ItemSceneChange) {

        disconnectFromWindow();
        if (value.window) connectToWindow(value.window);
    }

    QQuickItem::itemChange(change, value);
}

void
SiC64Heatmap::connectToWindow(QQuickWindow *win)
{
    m_frameConnection = connect(win, &QQuickWindow::frameSwapped, this, [this]() {
        grab();
        update();
    });
}

void
SiC64Heatmap::disconnectFromWindow()
{
    if (m_frameConnection) {

        disconnect(m_frameConnection);
        m_frameConnection = QMetaObject::Connection();
    }
}

void
SiC64Heatmap::grab()
{
    C64Controller::core().mem.drawHeatmap(buffer.data(), Width, Height);
}

QSGNode *
SiC64Heatmap::updatePaintNode(QSGNode *node, UpdatePaintNodeData *)
{
    auto *textureNode = static_cast<QSGSimpleTextureNode *>(node);
    if (!textureNode) {
        textureNode = new QSGSimpleTextureNode();
        textureNode->setOwnsTexture(true);
    }

    QImage img(reinterpret_cast<const uchar *>(buffer.data()),
               Width, Height, QImage::Format_RGBA8888);


    textureNode->setTexture(window()->createTextureFromImage(img));
    textureNode->setRect(boundingRect());
    textureNode->setFiltering(QSGTexture::Linear);

    return textureNode;
}
