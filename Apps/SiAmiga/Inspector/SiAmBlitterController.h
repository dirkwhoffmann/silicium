// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#pragma once

#include "SiAmInspectorController.h"

//
// Blitter inspector controller -- port of vAmiga's own GUI/Inspector/
// BlitterPanel.swift (there is no C64 counterpart; the Blitter is
// Amiga-only). Exposes BLTCON0/BLTCON1 decoded into their sub-fields, the
// per-channel hold/old/new registers and their "use this channel" flags,
// the mask/barrel-shifter/fill circuitry, and the eight-input minterm
// (logic function) generator -- straight off BlitterInfo, field for field,
// the same way the Swift reference's refreshBlitter() reads blitterInfo.
//
// The eight minterm rows (abc/abC/aBc/.../ABC -- lowercase = 0, uppercase
// = 1 for that channel, ascending binary order) are exposed via
// lfEnabled(n)/lfValue(n)/lfLabel(n) rather than 24 named properties
// (enabled flag + computed value + label, times 8), so the panel can
// build them with a Repeater the way SiAmInfoController's CPU register
// file is read via dReg(n)/aReg(n) instead of 16 named properties.
//
// The shared active flag, tick throttle and beam-position readout come
// from SiAmInspectorController.
//

class SiAmController;

class SiAmBlitterController : public SiAmInspectorController {

    Q_OBJECT

    // BLTCON0 / BLTCON1, decoded
    int m_bltcon0A = 0, m_bltcon0B = 0, m_bltcon0C = 0; // ash, bits 11..8, bits 7..0
    int m_bltcon1A = 0, m_bltcon1B = 0, m_bltcon1C = 0; // bsh, bits 11..8, bits 7..0
    bool m_exclusiveFill = false, m_inclusiveFill = false, m_fillCarry = false;
    bool m_descending = false, m_lineMode = false, m_bbusy = false;
    bool m_useA = false, m_useB = false, m_useC = false, m_useD = false;

    // Channel data
    int m_aHold = 0, m_aOld = 0, m_aNew = 0;
    int m_bHold = 0, m_bOld = 0, m_bNew = 0;
    int m_cHold = 0, m_dHold = 0;
    bool m_bzero = false;

    // Mask / shift / fill circuitry
    int m_unmasked = 0, m_afwm = 0, m_alwm = 0, m_masked = 0;
    bool m_firstWord = false, m_lastWord = false;
    int m_barrelAIn = 0, m_barrelAShift = 0, m_barrelAOut = 0;
    int m_barrelBIn = 0, m_barrelBShift = 0, m_barrelBOut = 0;
    int m_fillIn = 0, m_fillOut = 0;

    // Minterm generator inputs and output (dhold doubles as the computed
    // result written to the destination -- see the class comment).
    int m_mintermA = 0, m_mintermB = 0, m_mintermC = 0, m_lfOut = 0;
    // Bit i of bltcon0's LF byte (enabled) and the corresponding computed
    // value for that minterm, indexed 0..7 -- see lfEnabled()/lfValue().
    bool m_lfEnabled[8] = {};
    int m_lfValue[8] = {};

  public:

    explicit SiAmBlitterController(SiAmController *parent = nullptr);

    Q_PROPERTY(int bltcon0A READ bltcon0A NOTIFY blitterChanged)
    Q_PROPERTY(int bltcon0B READ bltcon0B NOTIFY blitterChanged)
    Q_PROPERTY(int bltcon0C READ bltcon0C NOTIFY blitterChanged)
    Q_PROPERTY(int bltcon1A READ bltcon1A NOTIFY blitterChanged)
    Q_PROPERTY(int bltcon1B READ bltcon1B NOTIFY blitterChanged)
    Q_PROPERTY(int bltcon1C READ bltcon1C NOTIFY blitterChanged)

    Q_PROPERTY(bool exclusiveFill READ exclusiveFill NOTIFY blitterChanged)
    Q_PROPERTY(bool inclusiveFill READ inclusiveFill NOTIFY blitterChanged)
    Q_PROPERTY(bool fillCarry READ fillCarry NOTIFY blitterChanged)
    Q_PROPERTY(bool descending READ descending NOTIFY blitterChanged)
    Q_PROPERTY(bool lineMode READ lineMode NOTIFY blitterChanged)
    Q_PROPERTY(bool bbusy READ bbusy NOTIFY blitterChanged)

    Q_PROPERTY(bool useA READ useA NOTIFY blitterChanged)
    Q_PROPERTY(bool useB READ useB NOTIFY blitterChanged)
    Q_PROPERTY(bool useC READ useC NOTIFY blitterChanged)
    Q_PROPERTY(bool useD READ useD NOTIFY blitterChanged)

    Q_PROPERTY(int aHold READ aHold NOTIFY blitterChanged)
    Q_PROPERTY(int aOld READ aOld NOTIFY blitterChanged)
    Q_PROPERTY(int aNew READ aNew NOTIFY blitterChanged)
    Q_PROPERTY(int bHold READ bHold NOTIFY blitterChanged)
    Q_PROPERTY(int bOld READ bOld NOTIFY blitterChanged)
    Q_PROPERTY(int bNew READ bNew NOTIFY blitterChanged)
    Q_PROPERTY(int cHold READ cHold NOTIFY blitterChanged)
    Q_PROPERTY(int dHold READ dHold NOTIFY blitterChanged)
    Q_PROPERTY(bool bzero READ bzero NOTIFY blitterChanged)

    Q_PROPERTY(int unmasked READ unmasked NOTIFY blitterChanged)
    Q_PROPERTY(int afwm READ afwm NOTIFY blitterChanged)
    Q_PROPERTY(int alwm READ alwm NOTIFY blitterChanged)
    Q_PROPERTY(int masked READ masked NOTIFY blitterChanged)
    Q_PROPERTY(bool firstWord READ firstWord NOTIFY blitterChanged)
    Q_PROPERTY(bool lastWord READ lastWord NOTIFY blitterChanged)

    Q_PROPERTY(int barrelAIn READ barrelAIn NOTIFY blitterChanged)
    Q_PROPERTY(int barrelAShift READ barrelAShift NOTIFY blitterChanged)
    Q_PROPERTY(int barrelAOut READ barrelAOut NOTIFY blitterChanged)
    Q_PROPERTY(int barrelBIn READ barrelBIn NOTIFY blitterChanged)
    Q_PROPERTY(int barrelBShift READ barrelBShift NOTIFY blitterChanged)
    Q_PROPERTY(int barrelBOut READ barrelBOut NOTIFY blitterChanged)

    Q_PROPERTY(int fillIn READ fillIn NOTIFY blitterChanged)
    Q_PROPERTY(int fillOut READ fillOut NOTIFY blitterChanged)

    Q_PROPERTY(int mintermA READ mintermA NOTIFY blitterChanged)
    Q_PROPERTY(int mintermB READ mintermB NOTIFY blitterChanged)
    Q_PROPERTY(int mintermC READ mintermC NOTIFY blitterChanged)
    Q_PROPERTY(int lfOut READ lfOut NOTIFY blitterChanged)

    // Minterm row 'n' (0..7, ascending binary abc/abC/.../ABC -- see the
    // class comment): whether bit n of BLTCON0's LF byte is set, the
    // computed (a op b op c) value for that combination, and its label.
    Q_INVOKABLE bool lfEnabled(int n) const { return n >= 0 && n < 8 && m_lfEnabled[n]; }
    Q_INVOKABLE int lfValue(int n) const { return n >= 0 && n < 8 ? m_lfValue[n] : 0; }
    Q_INVOKABLE QString lfLabel(int n) const;

  protected:

    void refreshData() override;

  private:

    int bltcon0A() const { return m_bltcon0A; }
    int bltcon0B() const { return m_bltcon0B; }
    int bltcon0C() const { return m_bltcon0C; }
    int bltcon1A() const { return m_bltcon1A; }
    int bltcon1B() const { return m_bltcon1B; }
    int bltcon1C() const { return m_bltcon1C; }

    bool exclusiveFill() const { return m_exclusiveFill; }
    bool inclusiveFill() const { return m_inclusiveFill; }
    bool fillCarry() const { return m_fillCarry; }
    bool descending() const { return m_descending; }
    bool lineMode() const { return m_lineMode; }
    bool bbusy() const { return m_bbusy; }

    bool useA() const { return m_useA; }
    bool useB() const { return m_useB; }
    bool useC() const { return m_useC; }
    bool useD() const { return m_useD; }

    int aHold() const { return m_aHold; }
    int aOld() const { return m_aOld; }
    int aNew() const { return m_aNew; }
    int bHold() const { return m_bHold; }
    int bOld() const { return m_bOld; }
    int bNew() const { return m_bNew; }
    int cHold() const { return m_cHold; }
    int dHold() const { return m_dHold; }
    bool bzero() const { return m_bzero; }

    int unmasked() const { return m_unmasked; }
    int afwm() const { return m_afwm; }
    int alwm() const { return m_alwm; }
    int masked() const { return m_masked; }
    bool firstWord() const { return m_firstWord; }
    bool lastWord() const { return m_lastWord; }

    int barrelAIn() const { return m_barrelAIn; }
    int barrelAShift() const { return m_barrelAShift; }
    int barrelAOut() const { return m_barrelAOut; }
    int barrelBIn() const { return m_barrelBIn; }
    int barrelBShift() const { return m_barrelBShift; }
    int barrelBOut() const { return m_barrelBOut; }

    int fillIn() const { return m_fillIn; }
    int fillOut() const { return m_fillOut; }

    int mintermA() const { return m_mintermA; }
    int mintermB() const { return m_mintermB; }
    int mintermC() const { return m_mintermC; }
    int lfOut() const { return m_lfOut; }

  signals:

    void blitterChanged();
};
