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
// Live preview of the DMA debugger's overlay, shown in the Layers inspector
// (SiAmLayersPanel.qml). Unlike SiC64 -- whose VICII DMA debugger renders
// into a texture of its own (VideoPort::getDmaTexture) -- vAmiga's
// DmaDebugger::computeOverlay() paints straight into the emulator's regular
// video texture, so there is no separate DMA-only texture to grab: this view
// just mirrors the main stable texture (getTexture()), which already carries
// the overlay once DMA_DEBUG_ENABLE is on.
//
// A self-contained QQuickItem, otherwise the same shape as SiC64DmaView: it
// self-drives off its window's frameSwapped signal while visible, so it only
// grabs a fresh texture while the Layers inspector window is actually on
// screen, and needs no controller wiring beyond the static core() accessor.
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
