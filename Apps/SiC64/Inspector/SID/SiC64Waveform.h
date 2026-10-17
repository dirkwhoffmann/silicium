// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#pragma once

#include <QQuickItem>
#include <cstdint>
#include <vector>

//
// Port of the old Swift-based emulator's WaveformView (WaveformView.swift):
// the live audio waveform shown in the SID inspector.
//
// A self-contained QQuickItem in the same mold as SiC64DmaView / SiC64Heatmap,
// except the image is produced by SID::draw() -- which also returns an
// auto-scaling amplitude that is fed back on the next frame -- and the buffer
// is sized to the item rather than fixed. It self-drives off its window's
// frameSwapped signal while in a scene (idle while the window is hidden).
//
// 'sid' selects the audio source: -1 draws the combined audio buffer, 0..3 a
// specific SID's output (see SIDPanel.swift's waveform source popup).
//

class SiC64Waveform : public QQuickItem {

    Q_OBJECT

    std::vector<uint32_t> buffer;
    int texW = 0;
    int texH = 0;

    // Auto-scaling amplitude carried across frames by SID::draw()
    float maxAmp = 0.001f;

    int m_sid = -1;

    QMetaObject::Connection m_frameConnection;

  public:

    explicit SiC64Waveform(QQuickItem *parent = nullptr);

    Q_PROPERTY(int sid READ sid WRITE setSid NOTIFY sidChanged)

    int sid() const { return m_sid; }
    void setSid(int value);

  protected:

    QSGNode *updatePaintNode(QSGNode *node, UpdatePaintNodeData *) override;
    void itemChange(ItemChange change, const ItemChangeData &value) override;

  private:

    void connectToWindow(QQuickWindow *win);
    void disconnectFromWindow();

    // Renders the current waveform into 'buffer'
    void grab();

  signals:

    void sidChanged();
};
