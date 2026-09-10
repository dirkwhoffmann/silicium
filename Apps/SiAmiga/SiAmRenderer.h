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
    u32 *tex = nullptr;

    // Frame counter
    isize frame = 0;

    // Frame parameters
    isize nr     = 0;
    isize width  = 0;
    isize height = 0;

    QMetaObject::Connection m_frameConnection;
    QMetaObject::Connection m_configConnection;

    // Live display-window rect, fed by Msg::VIEWPORT
    double x1 = 0.0, y1 = 0.0, x2 = 0.0, y2 = 0.0;

    Q_PROPERTY(SiAmController *controller READ getController WRITE setController NOTIFY controllerChanged)


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

    // Returns the visible texture area based on the zoom and center parameters
    TexRect visible() const override;
    TexRect visibleNormalized() const override { return normalize(visible()); }

    // Feeds a fresh display-window rect into visible()'s AutoShift branch and recomputes the cutout.
    void updateTextureRect(int hstrt, int vstrt, int hstop, int vstop);

  private:

    TexRect normalize(TexRect rect) const;

    // Recomputes the cutout from visible(). Called on every config change, and once from start()
    void updateTextureCutout();


    //
    // Screenshots
    //

  public:

    // Grabs a screenshot of the currently displayed frame, cropped to largestVisible()
    QImage grabScreenshot() const;

  signals:

    void controllerChanged();
};
