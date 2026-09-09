// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#pragma once

#include "Renderer.h"
#include "SiAmController.h"
#include "utl/common.h"
#include <QImage>

class SiAmRenderer : public Renderer {

    Q_OBJECT

    //
    // Members
    //

    class SiAmController *controller = nullptr;
    u32 *tex                            = nullptr;

    // Frame counter
    isize frame = 0;

    // Frame parameters
    isize nr     = 0;
    isize width  = 0;
    isize height = 0;

    QMetaObject::Connection m_frameConnection;
    QMetaObject::Connection m_configConnection;

    Q_PROPERTY(
        SiAmController *controller READ getController WRITE setController NOTIFY controllerChanged)

    //
    // Methods
    //

  public:

    using Renderer::Renderer;

    SiAmController *getController() const { return controller; }
    void setController(SiAmController *ptr);

    void start() override;
    void stop() override;

  protected:

    QSGNode *updatePaintNode(QSGNode *node, UpdatePaintNodeData *) override;
    void geometryChange(const QRectF &newGeometry, const QRectF &oldGeometry) override;

  private:

    // Called within the render loop
    void tick();

    //
    // Texture cutout
    //

  public:

    // Returns the used texture area (including HBLANK and VBLANK)
    TexRect entire() const override;
    TexRect entireNormalized() const override { return normalize(entire()); }

    // Returns the largest visible texture area (excluding HBLANK and VBLANK)
    TexRect largestVisible() const override;
    TexRect largestVisibleNormalized() const override { return normalize(largestVisible()); }

    // Returns the visible texture area based on the zoom and center
    // parameters (MON_ZOOM/MON_HZOOM/MON_VZOOM/MON_CENTER/MON_HCENTER/
    // MON_VCENTER). Ported from vAmiga's own GUI/Metal/TextureRect.swift,
    // including its MON_ZOOM preset switch (Narrow/Wide/Extreme), but
    // *not* MON_CENTER's "Automatic" (AutoShift) mode: that needs a live
    // DMA-debug/beam window (x1/y1/x2/y2, kept in sync via
    // updateTextureRect(hstrt:...) on the Swift side) that nothing here
    // tracks yet, so MON_CENTER == 1 currently falls back to the same
    // hCenter/vCenter formula as Custom (0) rather than truly auto-shifting.
    TexRect visible() const override;
    TexRect visibleNormalized() const override { return normalize(visible()); }

  private:

    TexRect normalize(TexRect rect) const;

    // Recomputes the cutout from visible(). Called on every config change,
    // and once from start(). Mirrors SiC64Renderer::updateTextureCutout().
    void updateTextureCutout();


    //
    // Screenshots
    //

  public:

    // Grabs a screenshot of the currently displayed frame, cropped to
    // largestVisible() (the same convention the core's own snapshot
    // thumbnails use). Returns a null QImage if no frame has been rendered
    // yet. Mirrors SiC64Renderer::grabScreenshot().
    QImage grabScreenshot() const;

  signals:

    void controllerChanged();
};
