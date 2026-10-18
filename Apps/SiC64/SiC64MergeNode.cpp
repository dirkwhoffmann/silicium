// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "SiC64MergeNode.h"

#include <QSGMaterialShader>
#include <QSGTexture>

namespace {

// Byte offsets into the std140 uniform block both shaders declare
constexpr int uniformMatrix = 0;        // mat4  (64 bytes)
constexpr int uniformOpacity = 64;      // float
constexpr int uniformXrayOverlay = 68;  // float
constexpr int uniformXrayStyle = 72;    // float
constexpr int uniformXrayWeight = 76;   // float
constexpr int uniformSize = 80;

class SiC64MergeShader : public QSGMaterialShader {

  public:

    SiC64MergeShader()
    {
        setShaderFileName(VertexStage, QStringLiteral(":/shaders/sic64merge.vert.qsb"));
        setShaderFileName(FragmentStage, QStringLiteral(":/shaders/sic64merge.frag.qsb"));
    }

    bool updateUniformData(RenderState &state,
                           QSGMaterial *newMaterial,
                           QSGMaterial *oldMaterial) override
    {
        Q_UNUSED(oldMaterial);

        auto *material = static_cast<SiC64MergeMaterial *>(newMaterial);
        auto *buf = state.uniformData();
        Q_ASSERT(buf->size() >= uniformSize);

        if (state.isMatrixDirty()) {
            const auto matrix = state.combinedMatrix();
            memcpy(buf->data() + uniformMatrix, matrix.constData(), 64);
        }

        if (state.isOpacityDirty()) {
            const float opacity = state.opacity();
            memcpy(buf->data() + uniformOpacity, &opacity, 4);
        }

        memcpy(buf->data() + uniformXrayOverlay, &material->xrayOverlay, 4);
        memcpy(buf->data() + uniformXrayStyle, &material->xrayStyle, 4);
        memcpy(buf->data() + uniformXrayWeight, &material->xrayWeight, 4);

        return true;
    }

    void updateSampledImage(RenderState &state,
                            int binding,
                            QSGTexture **texture,
                            QSGMaterial *newMaterial,
                            QSGMaterial *oldMaterial) override
    {
        Q_UNUSED(oldMaterial);

        auto *material = static_cast<SiC64MergeMaterial *>(newMaterial);
        auto *t = (binding == 1) ? material->picture : material->xray;

        if (!t) { *texture = nullptr; return; }

        // Pixels are shown as they are, and the xray pixels are compared
        // against black, so nothing is smoothed
        t->setFiltering(QSGTexture::Nearest);
        t->setMipmapFiltering(QSGTexture::None);
        t->setHorizontalWrapMode(QSGTexture::ClampToEdge);
        t->setVerticalWrapMode(QSGTexture::ClampToEdge);
        t->commitTextureOperations(state.rhi(), state.resourceUpdateBatch());

        *texture = t;
    }
};

} // namespace

SiC64MergeMaterial::SiC64MergeMaterial()
{
    setFlag(QSGMaterial::Blending, true);
}

QSGMaterialType *
SiC64MergeMaterial::type() const
{
    static QSGMaterialType type;
    return &type;
}

QSGMaterialShader *
SiC64MergeMaterial::createShader(QSGRendererInterface::RenderMode) const
{
    return new SiC64MergeShader;
}

int
SiC64MergeMaterial::compare(const QSGMaterial *other) const
{
    auto *o = static_cast<const SiC64MergeMaterial *>(other);

    if (picture != o->picture) return picture < o->picture ? -1 : 1;
    if (xray != o->xray) return xray < o->xray ? -1 : 1;
    if (xrayOverlay != o->xrayOverlay) return xrayOverlay < o->xrayOverlay ? -1 : 1;
    if (xrayStyle != o->xrayStyle) return xrayStyle < o->xrayStyle ? -1 : 1;
    if (xrayWeight != o->xrayWeight) return xrayWeight < o->xrayWeight ? -1 : 1;

    return 0;
}

SiC64MergeNode::SiC64MergeNode() : m_geometry(QSGGeometry::defaultAttributes_TexturedPoint2D(), 4)
{
    setGeometry(&m_geometry);
    setMaterial(&m_material);
}

SiC64MergeNode::~SiC64MergeNode()
{
    delete m_picture;
    delete m_xray;
}

void
SiC64MergeNode::setPictureTexture(QSGTexture *texture)
{
    if (m_picture == texture) return;

    delete m_picture;
    m_picture = texture;
}

void
SiC64MergeNode::setXrayTexture(QSGTexture *texture)
{
    if (m_xray == texture) return;

    delete m_xray;
    m_xray = texture;
}

void
SiC64MergeNode::updateGeometry(const QRectF &target, const QRectF &source)
{
    QSGGeometry::updateTexturedRectGeometry(&m_geometry, target, source);
    markDirty(QSGNode::DirtyGeometry);
}
