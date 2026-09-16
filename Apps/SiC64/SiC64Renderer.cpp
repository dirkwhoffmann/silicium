// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "SiC64Renderer.h"
#include "Logger.h"
#include "VCCore/Infrastructure/Constants.h"
#include "VirtualC64.h"

#include <QQuickWindow>
#include <QSGSimpleTextureNode>

void
SiC64Renderer::setController(C64Controller *ptr)
{
    if (controller != ptr) {

        controller = ptr;

        // Track the monitor's zoom and center options
        if (m_configConnection) disconnect(m_configConnection);
        if (controller) {
            m_configConnection = connect(controller->getConfigController(),
                                         &SiC64ConfigController::configChanged,
                                         this,
                                         &SiC64Renderer::updateTextureCutout);
        }

        emit controllerChanged();
    }
}

void
SiC64Renderer::start()
{
    LogTask task("Starting renderer...");

    updateTextureCutout();

    // Get the refresh rate and pass it to the core
    setupRefreshRate();

    // Set the texture format
    controller->getConfigController()->setHostTexFormat((int)vc64::TexFormat::ARGB);

    // Only proceed if no connection exists yet
    if (m_frameConnection) return;

    setFlag(ItemHasContents, true);
    m_frameConnection = connect(window(), &QQuickWindow::frameSwapped, this, [this]() {
        tick();
        update();
    });
}

void
SiC64Renderer::setupRefreshRate()
{
    auto updateRefreshRate = [this](QScreen *screen) {
        qCDebug(siLog) << "Refresh rate:" << screen->refreshRate();
        auto *config = controller->getConfigController();
        config->setHostRefreshRate(screen->refreshRate());
    };

    if (auto screen = window()->screen()) {

        updateRefreshRate(screen);
        connect(screen, &QScreen::refreshRateChanged, this, [=](qreal rate) {
            updateRefreshRate(screen);
        });
        connect(window(), &QQuickWindow::screenChanged, this, [=](QScreen *newScreen) {
            updateRefreshRate(newScreen);
            connect(newScreen, &QScreen::refreshRateChanged, this, [=](qreal rate) {
                updateRefreshRate(newScreen);
            });
        });
    }
}

void
SiC64Renderer::stop()
{
    qCDebug(siLog) << "Stopping renderer...";

    if (m_frameConnection) {

        disconnect(m_frameConnection);
        m_frameConnection = QMetaObject::Connection();
    }

    // Optional: stop rendering
    setFlag(ItemHasContents, false);
}

void
SiC64Renderer::tick()
{
    if (!controller) return;

    frame++;

    auto &core = controller->core();
    auto &cpuInfo = core.cpu.getInfo();
    auto &c64Info = core.c64.getInfo();

    controller->update();
    controller->getActivityController()->update(cpuInfo.cycle, c64Info.frame, frame);
    controller->getEventController()->tick();
    controller->getCIAController()->tick();
    controller->getBusController()->tick();
    controller->getCPUController()->tick();
    controller->getMemoryController()->tick();
    controller->getVICController()->tick();
    controller->getSIDController()->tick();

    // Update texture
    core.videoPort.lockTexture();
    tex = const_cast<u32 *>(core.videoPort.getTexture(&nr, &width, &height));
    core.videoPort.unlockTexture();

    // Let the emulator compute the next frame
    core.wakeUp();
}

QSGNode *
SiC64Renderer::updatePaintNode(QSGNode *node, UpdatePaintNodeData *)
{
    if (!tex || width <= 0 || height <= 0) {
        delete node;
        return nullptr;
    }

    auto *textureNode = static_cast<QSGSimpleTextureNode *>(node);
    if (!textureNode) {
        textureNode = new QSGSimpleTextureNode();
        // Tells the node to delete the QSGTexture object when it's replaced or destroyed
        textureNode->setOwnsTexture(true);
    }

    // 1. Wrap your raw u32 buffer into a QImage
    // Note: QImage doesn't copy the data here, it just points to it.
    QImage img(reinterpret_cast<uchar *>(tex), width, height, QImage::Format_ARGB32);

    // 2. Create a GPU texture from the QImage
    QSGTexture *qsgTex = window()->createTextureFromImage(img);

    // 3. Update the node
    textureNode->setTexture(qsgTex);
    textureNode->setRect(boundingRect());

    // Set the texture cutout
    textureNode->setSourceRect(x.current, y.current, w.current, h.current);

    return textureNode;
}

void
SiC64Renderer::geometryChange(const QRectF &newGeometry, const QRectF &oldGeometry)
{
    QQuickItem::geometryChange(newGeometry, oldGeometry);

    if (controller) {

        qreal dpr   = window() ? window()->effectiveDevicePixelRatio() : 1.0;
        auto width  = qRound(newGeometry.width() * dpr);
        auto height = qRound(newGeometry.height() * dpr);

        controller->core().set(vc64::Opt::HOST_FRAMEBUF_WIDTH, width);
        controller->core().set(vc64::Opt::HOST_FRAMEBUF_HEIGHT, height);
    }
}

TexRect
SiC64Renderer::entire() const
{
    auto &traits = controller->core().vicii.getTraits();
    auto w = traits.cyclesPerLine * 8;
    auto h = traits.linesPerFrame;

    return { 0, 0, double(w), double(h) };
}

TexRect
SiC64Renderer::largestVisible() const
{
    if (controller->core().vicii.getTraits().pal) {
        return TexRect { .x = 104, .y = 16, .w = 487 - 104, .h = 299 - 16 };
    } else {
        return TexRect { .x = 104, .y = 16, .w = 487 - 104, .h = 249 - 16 };
    }
}

TexRect
SiC64Renderer::visible() const {

    auto max = largestVisible();
    auto *config = controller->getConfigController();

    auto hCenter = double(config->hCenter()) / 1000.0;
    auto vCenter = double(config->vCenter()) / 1000.0;
    auto hZoom = double(config->hZoom()) / 1000.0;
    auto vZoom = double(config->vZoom()) / 1000.0;
    auto width = (1.0 - hZoom) * max.w;
    auto bw = max.x + hCenter * (max.w - width);
    auto height = (1.0 - vZoom) *max.h;
    auto bh = max.y + vCenter * (max.h - height);

    return TexRect { .x = bw, .y = bh, .w = width, .h = height };
}

void
SiC64Renderer::updateTextureCutout()
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
SiC64Renderer::normalize(TexRect rect) const
{
    return { .x = rect.x / vc64::Tex::width,
             .y = rect.y / vc64::Tex::height,
             .w = rect.w / vc64::Tex::width,
             .h = rect.h / vc64::Tex::height };
}

QImage
SiC64Renderer::grabScreenshot() const
{
    if (!controller) return QImage();

    auto &core = controller->core();

    // Lock, copy, and unlock right away -- unlike tick(), which only stores
    // the pointer for updatePaintNode() to consume shortly after (safe there
    // because it runs almost immediately on the same thread cadence), this
    // can be called at an arbitrary time from the GUI thread, so the pixel
    // data must be copied out while the emulator thread is held off.
    isize texNr, texWidth, texHeight;
    core.videoPort.lockTexture();
    const u32 *src = core.videoPort.getTexture(&texNr, &texWidth, &texHeight);
    QImage grabbed;
    if (src && texWidth > 0 && texHeight > 0) {
        grabbed = QImage(reinterpret_cast<const uchar *>(src),
                          (int)texWidth, (int)texHeight, QImage::Format_ARGB32).copy();
    }
    core.videoPort.unlockTexture();

    if (grabbed.isNull()) return QImage();

    auto rect = largestVisible();
    return grabbed.copy(qRound(rect.x), qRound(rect.y), qRound(rect.w), qRound(rect.h));
}
