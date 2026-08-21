// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "SiC64DmaView.h"
#include "C64Controller.h"
#include "VirtualC64.h"

#include <QQuickWindow>
#include <QSGSimpleTextureNode>

SiC64DmaView::SiC64DmaView(QQuickItem *parent)
    : QQuickItem(parent)
{
    setFlag(ItemHasContents, true);
}

void
SiC64DmaView::itemChange(ItemChange change, const ItemChangeData &value)
{
    if (change == ItemSceneChange) {

        disconnectFromWindow();
        if (value.window) connectToWindow(value.window);
    }

    QQuickItem::itemChange(change, value);
}

void
SiC64DmaView::connectToWindow(QQuickWindow *win)
{
    // Grab a fresh DMA texture and repaint once per rendered frame, exactly
    // like SiC64Renderer. Because a hidden window emits no frames, this loop
    // is naturally idle while the Bus inspector is closed.
    m_frameConnection = connect(win, &QQuickWindow::frameSwapped, this, [this]() {
        grab();
        update();
    });
}

void
SiC64DmaView::disconnectFromWindow()
{
    if (m_frameConnection) {

        disconnect(m_frameConnection);
        m_frameConnection = QMetaObject::Connection();
    }
}

void
SiC64DmaView::grab()
{
    auto &videoPort = C64Controller::core().videoPort;

    isize nr = 0, w = 0, h = 0;

    videoPort.lockTexture();
    const u32 *tex = videoPort.getDmaTexture(&nr, &w, &h);

    if (tex && w > 0 && h > 0) {

        buffer.assign(tex, tex + (w * h));
        width = int(w);
        height = int(h);
    }
    videoPort.unlockTexture();
}

QSGNode *
SiC64DmaView::updatePaintNode(QSGNode *node, UpdatePaintNodeData *)
{
    if (buffer.empty() || width <= 0 || height <= 0) {
        delete node;
        return nullptr;
    }

    auto *textureNode = static_cast<QSGSimpleTextureNode *>(node);
    if (!textureNode) {
        textureNode = new QSGSimpleTextureNode();
        textureNode->setOwnsTexture(true);
    }

    // Wrap the private copy in a QImage (no copy) and hand it to the scene
    // graph, which copies it into a GPU texture.
    QImage img(reinterpret_cast<const uchar *>(buffer.data()),
               int(width), int(height), QImage::Format_ARGB32);

    textureNode->setTexture(window()->createTextureFromImage(img));
    textureNode->setRect(boundingRect());
    textureNode->setFiltering(QSGTexture::Linear);

    return textureNode;
}
