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
#include "VAmiga.h"
#include <QString>
#include <QVariantList>

//
// Bus inspector controller -- port of vAmiga's own GUI/Inspector/
// BusPanel.swift (the non-drawing half; the timing-diagram grid itself is
// SiAmLogicView, a QQuickPaintedItem, since that's a drawing job rather
// than a data-controller one). Owns the four probe-selector "Connect..."
// menus (LA_PROBE0..3 / LA_ADDR0..3, read/written through
// SiAmConfigController) and their preset list, which Swift builds as an
// NSMenu off Inspector.presets -- exposed here as a plain QVariantList so
// SiAmBusPanel.qml can build the equivalent with a Menu/Repeater.
//
// The DMA Debugger box (DMA_DEBUG_* options) needs no controller of its
// own -- it's plain option reads/writes, already exposed by
// SiAmConfigController exactly like SiC64BusPanel.qml's own ChannelRow
// reads cc.DMA_DEBUG_*. Only the probe selectors' preset-menu bookkeeping
// and the "IPL" vs. hex-address label formatting live here.
//
// The shared active flag, tick throttle and hex/decimal toggle come from
// SiAmInspectorController -- refreshData() is a no-op override since there
// is nothing here that ages (probe/address are read live from the config
// controller on every access, not cached).
//

class SiAmController;

class SiAmBusController : public SiAmInspectorController {

    Q_OBJECT

  public:

    explicit SiAmBusController(SiAmController *parent = nullptr);

    // The preset list a probe-selector menu offers, in order -- each entry
    // is {name: string, separator: bool}. Mirrors Inspector.presets
    // (BusPanel.swift), minus the trailing separator that precedes Swift's
    // embedded free-text field there (SiAmBusPanel.qml has its own address
    // field per channel instead, not folded into the menu).
    Q_INVOKABLE QVariantList presetModel() const;

    // Applies preset 'index' (into presetModel()) to probe channel 'channel'
    // (0..3): sets LA_PROBEn and, if the preset carries one, LA_ADDRn.
    Q_INVOKABLE void selectPreset(int channel, int index);

    // Applies a user-typed hex address to probe channel 'channel': sets
    // LA_PROBEn to MEMORY and LA_ADDRn to the parsed value. Returns false
    // (and changes nothing) if 'hex' doesn't parse, mirroring
    // busAddrAction's NSSound.beep() rejection path.
    Q_INVOKABLE bool selectAddress(int channel, const QString &hex);

    // Current label for probe channel 'channel' (0..3), matching
    // refreshProbeSelector(): "Connect..." when unconnected, a 6-digit hex
    // address for MEMORY, or "IPL".
    Q_INVOKABLE QString probeLabel(int channel) const;

  protected:

    void refreshData() override { }

  private:

    struct Preset { const char *name; vamiga::Probe probe; bool hasAddr; unsigned addr; };
    static const Preset presets[];
    static constexpr int numPresets = 19;
};
