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
#include <cstdint>
#include <vector>

//
// Port of the old Swift-based emulator's DmaView (DmaView.swift): the live
// preview of the VICII DMA debugger's texture shown in the Bus inspector.
//
// A self-contained QQuickItem that mirrors SiC64Renderer's texture plumbing
// but for the DMA texture (VideoPort::getDmaTexture). It self-drives off its
// window's frameSwapped signal while visible -- so it only renders while the
// Bus inspector window is actually on screen -- and needs no controller
// wiring beyond the static core() accessor.
//

class SiC64DmaView : public QQuickItem {

    Q_OBJECT

    // The most recently grabbed DMA texture (a private copy taken under the
    // core's texture lock, so updatePaintNode can use it without racing the
    // emulator thread)
    std::vector<uint32_t> buffer;
    int width = 0;
    int height = 0;

    QMetaObject::Connection m_frameConnection;

  public:

    explicit SiC64DmaView(QQuickItem *parent = nullptr);

  protected:

    QSGNode *updatePaintNode(QSGNode *node, UpdatePaintNodeData *) override;

    // Connects/disconnects the frameSwapped grab loop as the item enters or
    // leaves a window, so the view is live exactly while it's in a scene (and
    // naturally idle while the Bus inspector window is hidden, since a hidden
    // window emits no frames).
    void itemChange(ItemChange change, const ItemChangeData &value) override;

  private:

    void connectToWindow(QQuickWindow *win);
    void disconnectFromWindow();

    // Copies the current DMA texture out of the core (under its lock)
    void grab();
};
