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

    // Frame counter
    isize frame = 0;

    /* Long and short frame buffers (raw emulator data). Which one a frame
     * lands in is decided by its LOF flag. While the machine isn't
     * interlacing every frame carries the same flag and one buffer holds the
     * whole picture; in interlace mode the flag alternates and the two
     * buffers hold consecutive half-frames, which the merge shader weaves
     * back together. Mirrors Canvas.lfTexture/sfTexture in vAmiga.
     */
    QImage lfImage;
    QImage sfImage;

    // Set once the matching buffer holds a frame the GPU hasn't seen yet
    bool lfDirty = false;
    bool sfDirty = false;

    // Indicates whether the recently grabbed frames were long or short frames
    bool currLOF = true;
    bool prevLOF = true;

    // Frame number of the previously grabbed texture (drop/dup detection)
    isize prevNr = 0;

    // Used to emulate interlace flickering
    isize flickerCnt = 0;

    // Per-field brightness, recomputed with every grabbed frame
    float longFrameScale = 1.0f;
    float shortFrameScale = 1.0f;

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

    // Grabs the emulator's stable texture into the matching field buffer and
    // works out this frame's flicker weights. Mirrors Canvas.updateTexture()
    // plus the merge-uniform half of Canvas.makeCommandBuffer() in vAmiga.
    void updateTexture();

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
