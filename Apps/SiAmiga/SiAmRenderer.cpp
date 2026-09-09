// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "SiAmRenderer.h"
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
SiAmRenderer::setController(SiAmController *ptr)
{
    if (controller != ptr) {

        controller = ptr;

        // Track the monitor's zoom and center options
        if (m_configConnection) disconnect(m_configConnection);
        if (controller) {
            m_configConnection = connect(controller->getConfigController(),
                                         &SiAmConfigController::configChanged,
                                         this,
                                         &SiAmRenderer::updateTextureCutout);
        }

        emit controllerChanged();
    }
}

void
SiAmRenderer::start()
{
    LogTask task("Starting renderer...");

    width = texWidth;
    height = texHeight;

    updateTextureCutout();

    // Get the refresh rate and pass it to the core
    if (auto screen = window() ? window()->screen() : nullptr) {
        controller->core().set(vamiga::Opt::HOST_REFRESH_RATE, (i64)screen->refreshRate());
    }

    // Set the texture format
    controller->getConfigController()->setHostTexFormat((int)vamiga::TexFormat::ARGB);

    // Only proceed if no connection exists yet
    if (m_frameConnection) return;

    setFlag(ItemHasContents, true);
    m_frameConnection = connect(window(), &QQuickWindow::frameSwapped, this, [this]() {
        tick();
        update();
    });
}

void
SiAmRenderer::stop()
{
    qCDebug(siLog) << "Stopping renderer...";

    if (m_frameConnection) {

        disconnect(m_frameConnection);
        m_frameConnection = QMetaObject::Connection();
    }

    setFlag(ItemHasContents, false);
}

void
SiAmRenderer::tick()
{
    if (!controller) return;

    frame++;

    auto &core = controller->core();
    auto &cpuInfo = core.cpu.getInfo();
    auto &amigaInfo = core.amiga.getInfo();

    controller->update();
    controller->getActivityController()->update(cpuInfo.clock, amigaInfo.frame, frame);
    controller->getInspectorController()->tick();
    controller->getCIAController()->tick();
    controller->getEventController()->tick();
    controller->getMemoryController()->tick();
    controller->getCopperController()->tick();
    controller->getBlitterController()->tick();
    controller->getPaulaController()->tick();
    controller->getBusController()->tick();
    controller->getCPUController()->tick();
    controller->getDeniseController()->tick();
    controller->getPortController()->tick();

    // Update texture
    core.videoPort.lockTexture();
    tex = const_cast<u32 *>(core.videoPort.getTexture());
    core.videoPort.unlockTexture();

    // Let the emulator compute the next frame
    core.wakeUp();
}

QSGNode *
SiAmRenderer::updatePaintNode(QSGNode *node, UpdatePaintNodeData *)
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
SiAmRenderer::geometryChange(const QRectF &newGeometry, const QRectF &oldGeometry)
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
SiAmRenderer::entire() const
{
    return { 0, 0, double(texWidth), double(texHeight) };
}

TexRect
SiAmRenderer::largestVisible() const
{
    if (!controller) return entire();

    bool pal = controller->core().agnus.getTraits().isPAL;

    auto x1 = 8.0 * vamiga::HBLANK_CNT;
    auto x2 = 8.0 * vamiga::PAL::HPOS_CNT;
    auto y1 = double(pal ? vamiga::PAL::VBLANK_CNT : vamiga::NTSC::VBLANK_CNT);
    auto y2 = double(pal ? vamiga::PAL::VPOS_CNT : vamiga::NTSC::VPOS_CNT);

    return TexRect { .x = x1, .y = y1, .w = x2 - x1, .h = y2 - y1 - 1 };
}

TexRect
SiAmRenderer::visible() const
{
    if (!controller) return entire();

    auto *config = controller->getConfigController();
    auto max = largestVisible();

    auto hZoom = double(config->hZoom()) / 1000.0;
    auto vZoom = double(config->vZoom()) / 1000.0;
    auto hCenter = double(config->hCenter()) / 1000.0;
    auto vCenter = double(config->vCenter()) / 1000.0;

    auto hscale = 1.0 - 0.2 * hZoom;
    auto vscale = 1.0 - 0.2 * vZoom;
    auto width = hscale * max.w;
    auto height = vscale * max.h;

    auto bw = max.x + hCenter * (max.w - width);
    auto bh = max.y + vCenter * (max.h - height);

    return TexRect { .x = bw, .y = bh, .w = width, .h = height };
}

void
SiAmRenderer::updateTextureCutout()
{
    if (!controller) return;

    auto rect = visible();
    x = rect.x;
    y = rect.y;
    w = rect.w;
    h = rect.h;

    // Repaint even if the render loop isn't running
    update();
}

TexRect
SiAmRenderer::normalize(TexRect rect) const
{
    return { .x = rect.x / texWidth,
             .y = rect.y / texHeight,
             .w = rect.w / texWidth,
             .h = rect.h / texHeight };
}

QImage
SiAmRenderer::grabScreenshot() const
{
    if (!controller) return QImage();

    auto &core = controller->core();

    // Lock, copy, and unlock right away -- unlike tick(), which only stores
    // the pointer for updatePaintNode() to consume shortly after (safe there
    // because it runs almost immediately on the same thread cadence), this
    // can be called at an arbitrary time from the GUI thread, so the pixel
    // data must be copied out while the emulator thread is held off.
    core.videoPort.lockTexture();
    const u32 *src = core.videoPort.getTexture();
    QImage grabbed;
    if (src) {
        grabbed = QImage(reinterpret_cast<const uchar *>(src),
                          (int)texWidth, (int)texHeight, QImage::Format_ARGB32).copy();
    }
    core.videoPort.unlockTexture();

    if (grabbed.isNull()) return QImage();

    auto rect = largestVisible();
    return grabbed.copy(qRound(rect.x), qRound(rect.y), qRound(rect.w), qRound(rect.h));
}
