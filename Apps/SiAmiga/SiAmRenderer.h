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

    // The stub has no zoom/pan configuration yet (see C64Controller's
    // SiC64ConfigController for what that eventually looks like), so both of
    // these are the same as entire() for now.
    TexRect largestVisible() const override { return entire(); }
    TexRect largestVisibleNormalized() const override { return entireNormalized(); }

    TexRect visible() const override { return entire(); }
    TexRect visibleNormalized() const override { return entireNormalized(); }

  private:

    TexRect normalize(TexRect rect) const;

  signals:

    void controllerChanged();
};
