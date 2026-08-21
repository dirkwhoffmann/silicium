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

// A self-contained QQuickItem in the same mold as SiC64DmaView, except the
// image is produced by Memory::drawHeatmap() into a controller-owned buffer
// rather than fetched from the video port. It self-drives off its window's
// frameSwapped signal while in a scene (idle while the window is hidden), so
// it needs no explicit QML wiring. The heatmap data itself is only meaningful
// while the core's MEM_HEATMAP option is on -- SiC64MemoryController enables
// it while the Memory panel is active.

class SiC64Heatmap : public QQuickItem {

    Q_OBJECT

    static constexpr int Width = 256;
    static constexpr int Height = 256;

    std::vector<uint32_t> buffer;

    QMetaObject::Connection m_frameConnection;

  public:

    explicit SiC64Heatmap(QQuickItem *parent = nullptr);

  protected:

    QSGNode *updatePaintNode(QSGNode *node, UpdatePaintNodeData *) override;
    void itemChange(ItemChange change, const ItemChangeData &value) override;

  private:

    void connectToWindow(QQuickWindow *win);
    void disconnectFromWindow();

    // Renders the current heatmap into 'buffer'
    void grab();
};
