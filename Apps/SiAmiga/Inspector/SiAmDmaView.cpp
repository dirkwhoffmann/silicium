// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "SiAmDmaView.h"
#include "SiAmController.h"
#include "Constants.h"
#include "VAmiga.h"

#include <QQuickWindow>
#include <QSGSimpleTextureNode>

static constexpr isize texWidth  = 2 * vamiga::HPIXELS;
static constexpr isize texHeight = vamiga::VPIXELS;

SiAmDmaView::SiAmDmaView(QQuickItem *parent)
    : QQuickItem(parent)
{
    setFlag(ItemHasContents, true);
}

void
SiAmDmaView::itemChange(ItemChange change, const ItemChangeData &value)
{
    if (change == ItemSceneChange) {

        disconnectFromWindow();
        if (value.window) connectToWindow(value.window);
    }

    QQuickItem::itemChange(change, value);
}

void
SiAmDmaView::connectToWindow(QQuickWindow *win)
{
    // Grab a fresh texture and repaint once per rendered frame, exactly like
    // SiAmRenderer. Because a hidden window emits no frames, this loop is
    // naturally idle while the Layers inspector is closed.
    m_frameConnection = connect(win, &QQuickWindow::frameSwapped, this, [this]() {
        grab();
        update();
    });
}

void
SiAmDmaView::disconnectFromWindow()
{
    if (m_frameConnection) {

        disconnect(m_frameConnection);
        m_frameConnection = QMetaObject::Connection();
    }
}

void
SiAmDmaView::grab()
{
    auto &core = SiAmController::core();

    core.videoPort.lockTexture();

    if (auto *tex = core.videoPort.getTexture()) {
        buffer.assign(tex, tex + (texWidth * texHeight));
    }

    core.videoPort.unlockTexture();
}

QSGNode *
SiAmDmaView::updatePaintNode(QSGNode *node, UpdatePaintNodeData *)
{
    if (buffer.empty()) {
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
               int(texWidth), int(texHeight), QImage::Format_ARGB32);

    textureNode->setTexture(window()->createTextureFromImage(img));
    textureNode->setRect(boundingRect());
    textureNode->setFiltering(QSGTexture::Linear);

    return textureNode;
}
