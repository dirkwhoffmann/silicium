// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "SiAmigaRenderer.h"
#include "Logger.h"
#include "Constants.h"
#include "VAmiga.h"

#include <QQuickWindow>
#include <QSGSimpleTextureNode>

// The core packs two GPU texels (one hires pixel's worth of super-hires
// color data) into every emulator-side Texel -- see FrameBufferTypes.h. So
// the pixel buffer VideoPortAPI::getTexture() hands back is twice as wide,
// in u32 terms, as the HPIXELS the core itself counts in.
static constexpr isize texWidth  = 2 * vamiga::HPIXELS;
static constexpr isize texHeight = vamiga::VPIXELS;

void
SiAmigaRenderer::setController(SiAmigaController *ptr)
{
    if (controller != ptr) {

        controller = ptr;
        emit controllerChanged();
    }
}

void
SiAmigaRenderer::start()
{
    LogTask task("Starting renderer...");

    width = texWidth;
    height = texHeight;

    // No zoom/pan configuration yet (see the header) -- the cutout is just
    // the entire texture.
    auto rect = entire();
    x = rect.x;
    y = rect.y;
    w = rect.w;
    h = rect.h;

    // Get the refresh rate and pass it to the core
    if (auto screen = window() ? window()->screen() : nullptr) {
        controller->core().set(vamiga::Opt::HOST_REFRESH_RATE, (i64)screen->refreshRate());
    }

    // Only proceed if no connection exists yet
    if (m_frameConnection) return;

    setFlag(ItemHasContents, true);
    m_frameConnection = connect(window(), &QQuickWindow::frameSwapped, this, [this]() {
        tick();
        update();
    });
}

void
SiAmigaRenderer::stop()
{
    qCDebug(siLog) << "Stopping renderer...";

    if (m_frameConnection) {

        disconnect(m_frameConnection);
        m_frameConnection = QMetaObject::Connection();
    }

    setFlag(ItemHasContents, false);
}

void
SiAmigaRenderer::tick()
{
    if (!controller) return;

    frame++;

    auto &core = controller->core();

    controller->update();

    // Update texture
    core.videoPort.lockTexture();
    tex = const_cast<u32 *>(core.videoPort.getTexture());
    core.videoPort.unlockTexture();

    // Let the emulator compute the next frame
    core.wakeUp();
}

QSGNode *
SiAmigaRenderer::updatePaintNode(QSGNode *node, UpdatePaintNodeData *)
{
    if (!tex || width <= 0 || height <= 0) {
        delete node;
        return nullptr;
    }

    auto *textureNode = static_cast<QSGSimpleTextureNode *>(node);
    if (!textureNode) {
        textureNode = new QSGSimpleTextureNode();
        textureNode->setOwnsTexture(true);
    }

    QImage img(reinterpret_cast<uchar *>(tex), (int)width, (int)height, QImage::Format_ARGB32);
    QSGTexture *qsgTex = window()->createTextureFromImage(img);

    textureNode->setTexture(qsgTex);
    textureNode->setRect(boundingRect());
    textureNode->setSourceRect(x.current, y.current, w.current, h.current);

    return textureNode;
}

void
SiAmigaRenderer::geometryChange(const QRectF &newGeometry, const QRectF &oldGeometry)
{
    QQuickItem::geometryChange(newGeometry, oldGeometry);

    if (controller) {

        qreal dpr    = window() ? window()->effectiveDevicePixelRatio() : 1.0;
        auto pxWidth  = qRound(newGeometry.width() * dpr);
        auto pxHeight = qRound(newGeometry.height() * dpr);

        controller->core().set(vamiga::Opt::HOST_FRAMEBUF_WIDTH, pxWidth);
        controller->core().set(vamiga::Opt::HOST_FRAMEBUF_HEIGHT, pxHeight);
    }
}

TexRect
SiAmigaRenderer::entire() const
{
    return { 0, 0, double(texWidth), double(texHeight) };
}

TexRect
SiAmigaRenderer::normalize(TexRect rect) const
{
    return { .x = rect.x / texWidth,
             .y = rect.y / texHeight,
             .w = rect.w / texWidth,
             .h = rect.h / texHeight };
}
