// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "SiAmMergeNode.h"

#include <QSGMaterialShader>
#include <QSGTexture>

namespace {

// Byte offsets into the std140 uniform block both shaders declare
constexpr int uniformMatrix = 0;            // mat4  (64 bytes)
constexpr int uniformOpacity = 64;          // float
constexpr int uniformLongFrameScale = 68;   // float
constexpr int uniformShortFrameScale = 72;  // float
constexpr int uniformTexHeight = 76;        // float
constexpr int uniformXrayOverlay = 80;      // float
constexpr int uniformXrayFgWeight = 84;     // float
constexpr int uniformXrayBgWeight = 88;     // float
constexpr int uniformSize = 92;

class SiAmMergeShader : public QSGMaterialShader {

  public:

    SiAmMergeShader()
    {
        setShaderFileName(VertexStage, QStringLiteral(":/shaders/merge.vert.qsb"));
        setShaderFileName(FragmentStage, QStringLiteral(":/shaders/merge.frag.qsb"));
    }

    bool updateUniformData(RenderState &state,
                           QSGMaterial *newMaterial,
                           QSGMaterial *oldMaterial) override
    {
        Q_UNUSED(oldMaterial);

        auto *material = static_cast<SiAmMergeMaterial *>(newMaterial);
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

        // The scales change with every interlaced frame (see the flicker
        // handling in SiAmRenderer::tick()), so they're always rewritten.
        memcpy(buf->data() + uniformLongFrameScale, &material->longFrameScale, 4);
        memcpy(buf->data() + uniformShortFrameScale, &material->shortFrameScale, 4);
        memcpy(buf->data() + uniformTexHeight, &material->texHeight, 4);
        memcpy(buf->data() + uniformXrayOverlay, &material->xrayOverlay, 4);
        memcpy(buf->data() + uniformXrayFgWeight, &material->xrayFgWeight, 4);
        memcpy(buf->data() + uniformXrayBgWeight, &material->xrayBgWeight, 4);

        return true;
    }

    void updateSampledImage(RenderState &state,
                            int binding,
                            QSGTexture **texture,
                            QSGMaterial *newMaterial,
                            QSGMaterial *oldMaterial) override
    {
        Q_UNUSED(oldMaterial);

        auto *material = static_cast<SiAmMergeMaterial *>(newMaterial);
        QSGTexture *t = nullptr;
        switch (binding) {

            case 1: t = material->longFrame; break;
            case 2: t = material->shortFrame; break;
            case 3: t = material->longXray; break;
            default: t = material->shortXray; break;
        }

        if (!t) { *texture = nullptr; return; }

        // The xray pixels are compared against black, so they are not smoothed
        const bool xray = binding >= 3;

        t->setFiltering(xray ? QSGTexture::Nearest : QSGTexture::Linear);
        t->setMipmapFiltering(QSGTexture::None);
        t->setHorizontalWrapMode(QSGTexture::ClampToEdge);
        t->setVerticalWrapMode(QSGTexture::ClampToEdge);
        t->commitTextureOperations(state.rhi(), state.resourceUpdateBatch());

        *texture = t;
    }
};

} // namespace

SiAmMergeMaterial::SiAmMergeMaterial()
{
    setFlag(QSGMaterial::Blending, true);
}

QSGMaterialType *
SiAmMergeMaterial::type() const
{
    static QSGMaterialType type;
    return &type;
}

QSGMaterialShader *
SiAmMergeMaterial::createShader(QSGRendererInterface::RenderMode) const
{
    return new SiAmMergeShader;
}

int
SiAmMergeMaterial::compare(const QSGMaterial *other) const
{
    auto *o = static_cast<const SiAmMergeMaterial *>(other);

    if (longFrame != o->longFrame) return longFrame < o->longFrame ? -1 : 1;
    if (shortFrame != o->shortFrame) return shortFrame < o->shortFrame ? -1 : 1;
    if (longXray != o->longXray) return longXray < o->longXray ? -1 : 1;
    if (shortXray != o->shortXray) return shortXray < o->shortXray ? -1 : 1;
    if (xrayOverlay != o->xrayOverlay) return xrayOverlay < o->xrayOverlay ? -1 : 1;
    if (xrayFgWeight != o->xrayFgWeight) return xrayFgWeight < o->xrayFgWeight ? -1 : 1;
    if (xrayBgWeight != o->xrayBgWeight) return xrayBgWeight < o->xrayBgWeight ? -1 : 1;
    if (longFrameScale != o->longFrameScale) return longFrameScale < o->longFrameScale ? -1 : 1;
    if (shortFrameScale != o->shortFrameScale) return shortFrameScale < o->shortFrameScale ? -1 : 1;
    if (texHeight != o->texHeight) return texHeight < o->texHeight ? -1 : 1;

    return 0;
}

SiAmMergeNode::SiAmMergeNode() : m_geometry(QSGGeometry::defaultAttributes_TexturedPoint2D(), 4)
{
    setGeometry(&m_geometry);
    setMaterial(&m_material);
}

SiAmMergeNode::~SiAmMergeNode()
{
    delete m_lfTexture;
    delete m_sfTexture;
    delete m_lxTexture;
    delete m_sxTexture;
}

void
SiAmMergeNode::setLongFrameTexture(QSGTexture *texture)
{
    if (m_lfTexture == texture) return;

    delete m_lfTexture;
    m_lfTexture = texture;
}

void
SiAmMergeNode::setShortFrameTexture(QSGTexture *texture)
{
    if (m_sfTexture == texture) return;

    delete m_sfTexture;
    m_sfTexture = texture;
}

void
SiAmMergeNode::setLongXrayTexture(QSGTexture *texture)
{
    if (m_lxTexture == texture) return;

    delete m_lxTexture;
    m_lxTexture = texture;
}

void
SiAmMergeNode::setShortXrayTexture(QSGTexture *texture)
{
    if (m_sxTexture == texture) return;

    delete m_sxTexture;
    m_sxTexture = texture;
}

void
SiAmMergeNode::updateGeometry(const QRectF &target, const QRectF &source)
{
    QSGGeometry::updateTexturedRectGeometry(&m_geometry, target, source);
    markDirty(QSGNode::DirtyGeometry);
}
