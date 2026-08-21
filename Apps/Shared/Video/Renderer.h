// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#pragma once

#include "utl/common.h"
#include "utl/wrappers/Animated.h"
#include <QQuickItem>
#include <QSGSimpleRectNode>

//
// Types
//

struct TexRect {
    double x, y, w, h;
};

class Renderer : public QQuickItem {

    Q_OBJECT

  protected:

    // Texture cutout
    utl::Animated<double> x;
    utl::Animated<double> y;
    utl::Animated<double> w;
    utl::Animated<double> h;

  public:

    Renderer(QQuickItem *parent = nullptr);

    //
    // Life cycle
    //

  public:

    virtual void start() {}
    virtual void stop() {}

    //
    // Texture cutout
    //

  public:

    // Returns the used texture area (including HBLANK and VBLANK)
    virtual TexRect entire() const = 0;
    virtual TexRect entireNormalized() const = 0;

    // Returns the largest visibile texture area (excluding HBLANK and VBLANK)
    virtual TexRect largestVisible() const = 0;
    virtual TexRect largestVisibleNormalized() const = 0;

    // Returns the visible texture area based on the zoom and center parameters
    virtual TexRect visible() const = 0;
    virtual TexRect visibleNormalized() const = 0;
};