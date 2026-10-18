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

// Draws the C64 picture. If the GPU is the compositor of the xray texture
// (see Opt::XRAY_COMPOSITOR), the fragment shader blends it into the picture.
// Otherwise, the picture is drawn as it is.

class SiC64MergeMaterial : public QSGMaterial {

  public:

    SiC64MergeMaterial();

    QSGMaterialType *type() const override;
    QSGMaterialShader *createShader(QSGRendererInterface::RenderMode) const override;
    int compare(const QSGMaterial *other) const override;

    // Owned by the node, not by this material
    QSGTexture *picture = nullptr;
    QSGTexture *xray = nullptr;

    // Blends the xray texture into the picture if set (see sic64merge.frag)
    float xrayOverlay = 0.0f;
    float xrayStyle = 0.0f;
    float xrayWeight = 0.0f;
};

class SiC64MergeNode : public QSGGeometryNode {

  public:

    SiC64MergeNode();
    ~SiC64MergeNode() override;

    SiC64MergeMaterial *mergeMaterial() { return &m_material; }

    QSGTexture *pictureTexture() const { return m_picture; }
    QSGTexture *xrayTexture() const { return m_xray; }

    // Both take ownership and drop whatever texture they replace
    void setPictureTexture(QSGTexture *texture);
    void setXrayTexture(QSGTexture *texture);

    // 'source' is in normalized texture coordinates
    void updateGeometry(const QRectF &target, const QRectF &source);

  private:

    QSGGeometry m_geometry;
    SiC64MergeMaterial m_material;

    QSGTexture *m_picture = nullptr;
    QSGTexture *m_xray = nullptr;
};
