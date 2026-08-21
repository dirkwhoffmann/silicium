// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#pragma once

#include "SiC64InspectorController.h"
#include <QColor>

//
// VICII inspector controller -- port of the old Swift-based emulator's VICII
// inspector (Inspector.swift's VICII tab / VICPanel.swift). Exposes the
// video chip's counters, display/memory state, interrupt and lightpen
// registers, the currently selected sprite's attributes, and the "cutter"
// layer stencils (which write through to the VICII_CUT_LAYERS / _OPACITY
// options).
//
// Numeric fields honour the shared format setting (C64Controller::format).
// The shared active flag, tick throttle and beam-position readout come from
// SiC64InspectorController.
//

class C64Controller;

class SiC64VICController : public SiC64InspectorController {

    Q_OBJECT

    int m_selectedSprite = 0;

    // Counters -- raw ints so the panel's SiNumberView can format them per
    // the shared display format.
    int m_yCounter = 0, m_xCounter = 0, m_vc = 0, m_vcBase = 0, m_rc = 0, m_vmli = 0;

    // Display
    int m_ctrl1 = 0, m_ctrl2 = 0, m_dx = 0, m_dy = 0;
    bool m_denBit = false, m_badLine = false, m_displayState = false, m_vblank = false;
    QString m_screenGeometry, m_displayMode;
    bool m_vFlop = false, m_hFlop = false;
    QColor m_borderColor, m_bgColor0, m_bgColor1, m_bgColor2, m_bgColor3;

    // Memory
    int m_memSelect = 0;
    QString m_memoryBankAddr, m_screenMemoryAddr, m_charMemoryAddr;
    bool m_ultimax = false;

    // Interrupts
    int m_irqRasterline = 0, m_imr = 0, m_irr = 0;
    bool m_imrLP = false, m_imrSS = false, m_imrSB = false, m_imrRaster = false;
    bool m_irrIrq = false, m_irrLP = false, m_irrSS = false, m_irrSB = false, m_irrRaster = false;

    // Lightpen
    int m_latchedLPX = 0, m_latchedLPY = 0;
    bool m_lpLine = false, m_lpIrqHasOccurred = false;

    // Selected sprite
    int m_sprX = 0, m_sprY = 0;
    bool m_sprEnabled = false, m_sprExpandX = false, m_sprExpandY = false;
    bool m_sprPriority = false, m_sprMulticolor = false;
    bool m_sprSSCollision = false, m_sprSBCollision = false;
    QColor m_sprColor, m_sprExtra1, m_sprExtra2;

  public:

    explicit SiC64VICController(C64Controller *parent = nullptr);

    Q_PROPERTY(int selectedSprite READ selectedSprite WRITE setSelectedSprite NOTIFY vicChanged)

    Q_PROPERTY(int yCounter READ yCounter NOTIFY vicChanged)
    Q_PROPERTY(int xCounter READ xCounter NOTIFY vicChanged)
    Q_PROPERTY(int vc READ vc NOTIFY vicChanged)
    Q_PROPERTY(int vcBase READ vcBase NOTIFY vicChanged)
    Q_PROPERTY(int rc READ rc NOTIFY vicChanged)
    Q_PROPERTY(int vmli READ vmli NOTIFY vicChanged)

    Q_PROPERTY(int ctrl1 READ ctrl1 NOTIFY vicChanged)
    Q_PROPERTY(int ctrl2 READ ctrl2 NOTIFY vicChanged)
    Q_PROPERTY(int dx READ dx NOTIFY vicChanged)
    Q_PROPERTY(int dy READ dy NOTIFY vicChanged)
    Q_PROPERTY(bool denBit READ denBit NOTIFY vicChanged)
    Q_PROPERTY(bool badLine READ badLine NOTIFY vicChanged)
    Q_PROPERTY(bool displayState READ displayState NOTIFY vicChanged)
    Q_PROPERTY(bool vblank READ vblank NOTIFY vicChanged)
    Q_PROPERTY(QString screenGeometry READ screenGeometry NOTIFY vicChanged)
    Q_PROPERTY(QString displayMode READ displayMode NOTIFY vicChanged)
    Q_PROPERTY(bool vFlop READ vFlop NOTIFY vicChanged)
    Q_PROPERTY(bool hFlop READ hFlop NOTIFY vicChanged)
    Q_PROPERTY(QColor borderColor READ borderColor NOTIFY vicChanged)
    Q_PROPERTY(QColor bgColor0 READ bgColor0 NOTIFY vicChanged)
    Q_PROPERTY(QColor bgColor1 READ bgColor1 NOTIFY vicChanged)
    Q_PROPERTY(QColor bgColor2 READ bgColor2 NOTIFY vicChanged)
    Q_PROPERTY(QColor bgColor3 READ bgColor3 NOTIFY vicChanged)

    Q_PROPERTY(int memSelect READ memSelect NOTIFY vicChanged)
    Q_PROPERTY(bool ultimax READ ultimax NOTIFY vicChanged)
    Q_PROPERTY(QString memoryBankAddr READ memoryBankAddr NOTIFY vicChanged)
    Q_PROPERTY(QString screenMemoryAddr READ screenMemoryAddr NOTIFY vicChanged)
    Q_PROPERTY(QString charMemoryAddr READ charMemoryAddr NOTIFY vicChanged)

    Q_PROPERTY(int irqRasterline READ irqRasterline NOTIFY vicChanged)
    Q_PROPERTY(int imr READ imr NOTIFY vicChanged)
    Q_PROPERTY(bool imrLP READ imrLP NOTIFY vicChanged)
    Q_PROPERTY(bool imrSS READ imrSS NOTIFY vicChanged)
    Q_PROPERTY(bool imrSB READ imrSB NOTIFY vicChanged)
    Q_PROPERTY(bool imrRaster READ imrRaster NOTIFY vicChanged)
    Q_PROPERTY(int irr READ irr NOTIFY vicChanged)
    Q_PROPERTY(bool irrIrq READ irrIrq NOTIFY vicChanged)
    Q_PROPERTY(bool irrLP READ irrLP NOTIFY vicChanged)
    Q_PROPERTY(bool irrSS READ irrSS NOTIFY vicChanged)
    Q_PROPERTY(bool irrSB READ irrSB NOTIFY vicChanged)
    Q_PROPERTY(bool irrRaster READ irrRaster NOTIFY vicChanged)

    Q_PROPERTY(int latchedLPX READ latchedLPX NOTIFY vicChanged)
    Q_PROPERTY(int latchedLPY READ latchedLPY NOTIFY vicChanged)
    Q_PROPERTY(bool lpLine READ lpLine NOTIFY vicChanged)
    Q_PROPERTY(bool lpIrqHasOccurred READ lpIrqHasOccurred NOTIFY vicChanged)

    Q_PROPERTY(int sprX READ sprX NOTIFY vicChanged)
    Q_PROPERTY(int sprY READ sprY NOTIFY vicChanged)
    Q_PROPERTY(bool sprEnabled READ sprEnabled NOTIFY vicChanged)
    Q_PROPERTY(bool sprExpandX READ sprExpandX NOTIFY vicChanged)
    Q_PROPERTY(bool sprExpandY READ sprExpandY NOTIFY vicChanged)
    Q_PROPERTY(bool sprPriority READ sprPriority NOTIFY vicChanged)
    Q_PROPERTY(bool sprMulticolor READ sprMulticolor NOTIFY vicChanged)
    Q_PROPERTY(bool sprSSCollision READ sprSSCollision NOTIFY vicChanged)
    Q_PROPERTY(bool sprSBCollision READ sprSBCollision NOTIFY vicChanged)
    Q_PROPERTY(QColor sprColor READ sprColor NOTIFY vicChanged)
    Q_PROPERTY(QColor sprExtra1 READ sprExtra1 NOTIFY vicChanged)
    Q_PROPERTY(QColor sprExtra2 READ sprExtra2 NOTIFY vicChanged)

    // Cutter (layer stencils). These write straight through to the
    // VICII_CUT_LAYERS bitmask / VICII_CUT_OPACITY options.
    Q_PROPERTY(bool cutEnable READ cutEnable WRITE setCutEnable NOTIFY cutChanged)
    Q_PROPERTY(bool cutBorder READ cutBorder WRITE setCutBorder NOTIFY cutChanged)
    Q_PROPERTY(bool cutForeground READ cutForeground WRITE setCutForeground NOTIFY cutChanged)
    Q_PROPERTY(bool cutBackground READ cutBackground WRITE setCutBackground NOTIFY cutChanged)
    Q_PROPERTY(bool cutSprites READ cutSprites WRITE setCutSprites NOTIFY cutChanged)
    Q_PROPERTY(int cutOpacity READ cutOpacity WRITE setCutOpacity NOTIFY cutChanged)
    // Bit i of cutSpriteMask corresponds to sprite i (0..7).
    Q_PROPERTY(int cutSpriteMask READ cutSpriteMask NOTIFY cutChanged)

    int selectedSprite() const { return m_selectedSprite; }
    void setSelectedSprite(int value);

    // Per-sprite cutter toggle (sprite 0..7), driven from the panel.
    Q_INVOKABLE void toggleCutSprite(int sprite);

  protected:

    void refreshData() override;

  private:

    int yCounter() const { return m_yCounter; }
    int xCounter() const { return m_xCounter; }
    int vc() const { return m_vc; }
    int vcBase() const { return m_vcBase; }
    int rc() const { return m_rc; }
    int vmli() const { return m_vmli; }
    int ctrl1() const { return m_ctrl1; }
    int ctrl2() const { return m_ctrl2; }
    int dx() const { return m_dx; }
    int dy() const { return m_dy; }
    bool denBit() const { return m_denBit; }
    bool badLine() const { return m_badLine; }
    bool displayState() const { return m_displayState; }
    bool vblank() const { return m_vblank; }
    QString screenGeometry() const { return m_screenGeometry; }
    QString displayMode() const { return m_displayMode; }
    bool vFlop() const { return m_vFlop; }
    bool hFlop() const { return m_hFlop; }
    QColor borderColor() const { return m_borderColor; }
    QColor bgColor0() const { return m_bgColor0; }
    QColor bgColor1() const { return m_bgColor1; }
    QColor bgColor2() const { return m_bgColor2; }
    QColor bgColor3() const { return m_bgColor3; }
    int memSelect() const { return m_memSelect; }
    bool ultimax() const { return m_ultimax; }
    QString memoryBankAddr() const { return m_memoryBankAddr; }
    QString screenMemoryAddr() const { return m_screenMemoryAddr; }
    QString charMemoryAddr() const { return m_charMemoryAddr; }
    int irqRasterline() const { return m_irqRasterline; }
    int imr() const { return m_imr; }
    bool imrLP() const { return m_imrLP; }
    bool imrSS() const { return m_imrSS; }
    bool imrSB() const { return m_imrSB; }
    bool imrRaster() const { return m_imrRaster; }
    int irr() const { return m_irr; }
    bool irrIrq() const { return m_irrIrq; }
    bool irrLP() const { return m_irrLP; }
    bool irrSS() const { return m_irrSS; }
    bool irrSB() const { return m_irrSB; }
    bool irrRaster() const { return m_irrRaster; }
    int latchedLPX() const { return m_latchedLPX; }
    int latchedLPY() const { return m_latchedLPY; }
    bool lpLine() const { return m_lpLine; }
    bool lpIrqHasOccurred() const { return m_lpIrqHasOccurred; }
    int sprX() const { return m_sprX; }
    int sprY() const { return m_sprY; }
    bool sprEnabled() const { return m_sprEnabled; }
    bool sprExpandX() const { return m_sprExpandX; }
    bool sprExpandY() const { return m_sprExpandY; }
    bool sprPriority() const { return m_sprPriority; }
    bool sprMulticolor() const { return m_sprMulticolor; }
    bool sprSSCollision() const { return m_sprSSCollision; }
    bool sprSBCollision() const { return m_sprSBCollision; }
    QColor sprColor() const { return m_sprColor; }
    QColor sprExtra1() const { return m_sprExtra1; }
    QColor sprExtra2() const { return m_sprExtra2; }

    // Cutter layer bitmask helpers (see VICPanel.swift's masks)
    static constexpr int MaskEnable     = 0x1000;
    static constexpr int MaskBorder     = 0x0800;
    static constexpr int MaskForeground = 0x0400;
    static constexpr int MaskBackground = 0x0200;
    static constexpr int MaskSprites    = 0x0100;

    int cutLayers() const;
    void setLayer(int mask, bool on);

    bool cutEnable() const { return cutLayers() & MaskEnable; }
    void setCutEnable(bool v) { setLayer(MaskEnable, v); }
    bool cutBorder() const { return cutLayers() & MaskBorder; }
    void setCutBorder(bool v) { setLayer(MaskBorder, v); }
    bool cutForeground() const { return cutLayers() & MaskForeground; }
    void setCutForeground(bool v) { setLayer(MaskForeground, v); }
    bool cutBackground() const { return cutLayers() & MaskBackground; }
    void setCutBackground(bool v) { setLayer(MaskBackground, v); }
    bool cutSprites() const { return cutLayers() & MaskSprites; }
    void setCutSprites(bool v) { setLayer(MaskSprites, v); }
    int cutSpriteMask() const { return cutLayers() & 0xFF; }
    int cutOpacity() const;
    void setCutOpacity(int value);

  signals:

    void vicChanged();
    void cutChanged();
};
