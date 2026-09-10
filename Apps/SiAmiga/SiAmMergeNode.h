// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#pragma once

#include <QSGGeometry>
#include <QSGGeometryNode>
#include <QSGMaterial>

class QSGTexture;

// Draws the Amiga picture by weaving its two half-frames (fields) together --
// the Qt counterpart of vAmiga's merge1X4Y/scale1X4Y compute kernels (see
// GUI/Metal/Shaders.metal and Canvas.makeCommandBuffer()).
//
// vAmiga materializes the result in a 4x-height merge texture because a chain
// of further compute passes (enhancer, bloom, upscaler, scanlines) reads it
// back. SiAmiga has no such chain -- the merged picture goes straight to the
// screen -- so the same field selection happens in the fragment shader at
// sample time instead, which needs no intermediate render target. Should the
// effect chain ever be ported, this is the place to revisit.
//
// Non-interlace mode points both texture slots at the same field and leaves
// both scales at 1.0, which collapses the merge to scale1X4Y's plain copy.

class SiAmMergeMaterial : public QSGMaterial {

  public:

    SiAmMergeMaterial();

    QSGMaterialType *type() const override;
    QSGMaterialShader *createShader(QSGRendererInterface::RenderMode) const override;
    int compare(const QSGMaterial *other) const override;

    // Field textures, owned by the node rather than by this material. Both
    // point at the same texture while the machine isn't interlacing.
    QSGTexture *longFrame = nullptr;
    QSGTexture *shortFrame = nullptr;

    // Per-field brightness, used to emulate interlace flicker
    float longFrameScale = 1.0f;
    float shortFrameScale = 1.0f;

    // Height of a single field texture, in texels
    float texHeight = 1.0f;
};

class SiAmMergeNode : public QSGGeometryNode {

  public:

    SiAmMergeNode();
    ~SiAmMergeNode() override;

    SiAmMergeMaterial *mergeMaterial() { return &m_material; }

    QSGTexture *longFrameTexture() const { return m_lfTexture; }
    QSGTexture *shortFrameTexture() const { return m_sfTexture; }

    // Both take ownership and drop whatever texture they replace. Called
    // from updatePaintNode(), i.e. on the render thread, which is also where
    // this node is destroyed -- so every texture create and delete stays on
    // the thread that owns the graphics resources.
    void setLongFrameTexture(QSGTexture *texture);
    void setShortFrameTexture(QSGTexture *texture);

    // 'source' is in normalized texture coordinates
    void updateGeometry(const QRectF &target, const QRectF &source);

  private:

    QSGGeometry m_geometry;
    SiAmMergeMaterial m_material;

    QSGTexture *m_lfTexture = nullptr;
    QSGTexture *m_sfTexture = nullptr;
};
