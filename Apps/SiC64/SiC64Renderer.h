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
#include "C64Controller.h"
#include "utl/common.h"
#include <QImage>

class SiC64Renderer : public Renderer {

    Q_OBJECT

    //
    // Members
    //

    class C64Controller *controller = nullptr;
    u32 *tex                        = nullptr;

    // Frame counter
    isize frame = 0;

    // Frame parameters
    isize nr     = 0;
    isize width  = 0;
    isize height = 0;

    QMetaObject::Connection m_frameConnection;
    QMetaObject::Connection m_configConnection;

    Q_PROPERTY(
        C64Controller *controller READ getController WRITE setController NOTIFY controllerChanged)

    //
    // Methods
    //

  public:

    using Renderer::Renderer;

    C64Controller *getController() const { return controller; }
    void setController(C64Controller *ptr);

    void start() override;
    void stop() override;

  protected:

    QSGNode *updatePaintNode(QSGNode *node, UpdatePaintNodeData *) override;
    void geometryChange(const QRectF &newGeometry, const QRectF &oldGeometry) override;

  private:

    // Called within start()
    void setupRefreshRate();

    // Called within the render loop
    void tick();

    //
    // Texture cutout
    //

  public:

    // Returns the used texture area (including HBLANK and VBLANK)
    TexRect entire() const override;
    TexRect entireNormalized() const override { return normalize(entire()); }

    // Returns the largest visibile texture area (excluding HBLANK and VBLANK)
    TexRect largestVisible() const override;
    TexRect largestVisibleNormalized() const override { return normalize(largestVisible()); }

    // Returns the visible texture area based on the zoom and center parameters
    TexRect visible() const override;
    TexRect visibleNormalized() const override { return normalize(visible()); }

  private:

    TexRect normalize(TexRect rect) const;

    // Recomputes the cutout from visible(). Called on every config change.
    void updateTextureCutout();


    //
    // Screenshots
    //

  public:

    // Grabs a screenshot of the currently displayed frame, cropped to
    // largestVisible() (the same convention the core's own snapshot
    // thumbnails use). Returns a null QImage if no frame has been rendered
    // yet.
    QImage grabScreenshot() const;

  signals:

    void controllerChanged();
};
