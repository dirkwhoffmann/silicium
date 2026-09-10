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
#include "SiAmMergeNode.h"
#include "VAmiga.h"

#include <QQuickWindow>
#include <QSGTexture>

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

    // Grab the current frame
    updateTexture();

    // Let the emulator compute the next frame
    core.wakeUp();
}

void
SiAmRenderer::updateTexture()
{
    auto &core = controller->core();

    isize nr = 0;
    bool lof = true;
    bool prevlof = true;

    // Prevent the stable texture from changing
    core.videoPort.lockTexture();

    if (auto *buffer = core.videoPort.getTexture(&nr, &lof, &prevlof)) {

        currLOF = lof;
        prevLOF = prevlof;

        // Check for duplicated or dropped frames
        if (nr != prevNr + 1) {
            // qCDebug(siLog) << "Frame sync mismatch (" << prevNr << "->" << nr << ")";
        }
        prevNr = nr;

        /* Copy the frame out rather than holding on to the emulator's own
         * buffer: the upload happens later, on the render thread, long after
         * the lock is gone. The copy is deep and handed over whole, so the
         * texture built from it keeps its own reference and this never has
         * to be written in place behind the GPU's back.
         */
        QImage frame(reinterpret_cast<const uchar *>(buffer),
                     (int)texWidth, (int)texHeight, QImage::Format_ARGB32);

        if (currLOF) {
            lfImage = frame.copy();
            lfDirty = true;
        } else {
            sfImage = frame.copy();
            sfDirty = true;
        }
    }

    // Release the texture lock
    core.videoPort.unlockTexture();

    /* Work out how bright each field is drawn. Only interlaced frames can
     * flicker -- a non-interlaced picture is carried by a single field, so
     * dimming every other one would just make the whole screen pulse.
     * Mirrors the merge-uniform half of Canvas.makeCommandBuffer().
     */
    auto *config = controller->getConfigController();

    if (currLOF != prevLOF && config->flicker()) {

        auto weight = 1.0f - float(config->flickerWeight()) / 1000.0f;
        longFrameScale = (flickerCnt % 4 >= 2) ? 1.0f : weight;
        shortFrameScale = (flickerCnt % 4 >= 2) ? weight : 1.0f;
        flickerCnt++;

    } else {

        longFrameScale = 1.0f;
        shortFrameScale = 1.0f;
    }
}

QSGNode *
SiAmRenderer::updatePaintNode(QSGNode *node, UpdatePaintNodeData *)
{
    if (lfImage.isNull() && sfImage.isNull()) {
        delete node;
        return nullptr;
    }

    auto *mergeNode = static_cast<SiAmMergeNode *>(node);
    if (!mergeNode) mergeNode = new SiAmMergeNode();

    // Upload whichever fields have been refilled since the last paint. Only
    // one of them changes per frame, so the other one's texture survives --
    // which is the whole point, since interlace needs the previous frame's
    // opposite field to still be around.
    if (lfDirty) {
        lfDirty = false;
        mergeNode->setLongFrameTexture(window()->createTextureFromImage(lfImage));
    }
    if (sfDirty) {
        sfDirty = false;
        mergeNode->setShortFrameTexture(window()->createTextureFromImage(sfImage));
    }

    auto *lf = mergeNode->longFrameTexture();
    auto *sf = mergeNode->shortFrameTexture();

    // Until both fields have been seen once, the one that has stands in for
    // the other. Same substitution non-interlace mode makes below, so the
    // startup frames simply take the plain-copy path.
    if (!lf) lf = sf;
    if (!sf) sf = lf;
    if (!lf) return mergeNode;

    auto *material = mergeNode->mergeMaterial();
    material->texHeight = float(texHeight);

    if (currLOF == prevLOF) {

        // Non-interlace mode: a single field carries the whole picture.
        // Feeding it to both slots collapses the merge to scale1X4Y's copy.
        auto *field = currLOF ? lf : sf;
        material->longFrame = field;
        material->shortFrame = field;
        material->longFrameScale = 1.0f;
        material->shortFrameScale = 1.0f;

    } else {

        // Interlace mode: long frame followed by a short frame, or the
        // other way round -- the shader weaves them line by line.
        material->longFrame = lf;
        material->shortFrame = sf;
        material->longFrameScale = longFrameScale;
        material->shortFrameScale = shortFrameScale;
    }

    mergeNode->updateGeometry(boundingRect(),
                              QRectF(x.current / texWidth, y.current / texHeight,
                                     w.current / texWidth, h.current / texHeight));
    mergeNode->markDirty(QSGNode::DirtyMaterial);

    return mergeNode;
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

    // MON_ZOOM overrides the H/V Zoom knobs with a fixed preset -- SiAmVideoConfig.qml
    // disables those knobs whenever this isn't 0 (Custom), same as
    // VideoSettings.swift's zoomAction/refresh.
    switch (config->zoom()) {
        case 1: hZoom = 1.0;   vZoom = 0.27;  break; // Narrow
        case 2: hZoom = 0.747; vZoom = 0.032; break; // Wide
        case 3: hZoom = 0.0;   vZoom = 0.0;   break; // Extreme
        default: break;
    }

    auto hscale = 1.0 - 0.2 * hZoom;
    auto vscale = 1.0 - 0.2 * vZoom;
    auto width = hscale * max.w;
    auto height = vscale * max.h;

    double bw, bh;

    if (config->center() == 1) {

        // Automatic: center on the live beam window (x1/y1/x2/y2) fed by
        // updateTextureRect(), clamped to the largest visible area.
        bw = x1 - 0.5 * (width - (x2 - x1));
        if (bw < max.x) bw = max.x;
        if (bw > max.x + max.w - width) bw = max.x + max.w - width;

        bh = y1 - 0.5 * (height - (y2 - y1));
        if (bh < max.y) bh = max.y;
        if (bh > max.y + max.h - height) bh = max.y + max.h - height;

    } else {

        bw = max.x + hCenter * (max.w - width);
        bh = max.y + vCenter * (max.h - height);
    }

    return TexRect { .x = bw, .y = bh, .w = width, .h = height };
}

void
SiAmRenderer::updateTextureRect(int hstrt, int vstrt, int hstop, int vstop)
{
    // hstrt/hstop already arrive in super-hires pixel coordinates
    x1 = double(hstrt);
    x2 = double(hstop);
    y1 = double(vstrt);
    y2 = double(vstop);

    // Compensate the texture shift
    x1 -= double(vamiga::HBLANK_MIN) * 8;
    x2 -= double(vamiga::HBLANK_MIN) * 8;

    // Crop to the largest visible area
    auto max = largestVisible();
    if (x1 < max.x) x1 = max.x;
    if (y1 < max.y) y1 = max.y;
    if (x2 > max.x + max.w) x2 = max.x + max.w;
    if (y2 > max.y + max.h) y2 = max.y + max.h;

    updateTextureCutout();
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
