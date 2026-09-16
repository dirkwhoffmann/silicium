// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#pragma once

#include <QQuickItem>
#include <vector>
#include <cstdint>

//
// Live preview of the DMA debugger's raw visualization, shown in the Layers
// inspector (SiAmXRayPanel.qml). Grabs VideoPortAPI::getXrayTexture() --
// PixelEngine's xrayTexture ring buffer, painted by DmaDebugger::
// computeOverlay() independently of the real picture -- so it shows DMA
// usage whenever XRAY_MODE is XRAY_DMA, whether or not XRAY_OVERLAY is
// also blending it into the display. Mirrors SiC64DmaView, which does the
// same for VICII's own separate DMA texture.
//
// A self-contained QQuickItem: it self-drives off its window's frameSwapped
// signal while visible, so it only grabs a fresh texture while the Layers
// inspector window is actually on screen, and needs no controller wiring
// beyond the static core() accessor.
//

class SiAmDmaView : public QQuickItem {

    Q_OBJECT

    // The most recently grabbed texture (a private copy taken under the
    // core's texture lock, so updatePaintNode can use it without racing the
    // emulator thread)
    std::vector<uint32_t> buffer;

    QMetaObject::Connection m_frameConnection;

  public:

    explicit SiAmDmaView(QQuickItem *parent = nullptr);

  protected:

    QSGNode *updatePaintNode(QSGNode *node, UpdatePaintNodeData *) override;

    // Connects/disconnects the frameSwapped grab loop as the item enters or
    // leaves a window, so the view is live exactly while it's in a scene (and
    // naturally idle while the Layers inspector window is hidden, since a
    // hidden window emits no frames).
    void itemChange(ItemChange change, const ItemChangeData &value) override;

  private:

    void connectToWindow(QQuickWindow *win);
    void disconnectFromWindow();

    // Copies the current stable texture out of the core (under its lock)
    void grab();
};
