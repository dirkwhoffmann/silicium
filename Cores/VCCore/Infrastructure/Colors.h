// -----------------------------------------------------------------------------
// This file is part of VirtualC64
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// This FILE is dual-licensed. You are free to choose between:
//
//     - The GNU General Public License v3 (or any later version)
//     - The Mozilla Public License v2
//
// SPDX-License-Identifier: GPL-3.0-or-later OR MPL-2.0
// -----------------------------------------------------------------------------

#pragma once

#include "BasicTypes.h"
#include "ColorTypes.h"

namespace vc64 {

struct YuvColor;
template <TexelFormat> struct GpuColor;

struct RgbColor {

    double r;
    double g;
    double b;

    RgbColor() : r(0), g(0), b(0) {}
    RgbColor(double rv, double gv, double bv) : r(rv), g(gv), b(bv) {}
    RgbColor(u8 rv, u8 gv, u8 bv) : r(rv / 255.0), g(gv / 255.0), b(bv / 255.0) {}
    RgbColor(const struct YuvColor &c);
    template <TexelFormat F> RgbColor(const GpuColor<F> &c);

    static const RgbColor black;
    static const RgbColor white;
    static const RgbColor red;
    static const RgbColor green;
    static const RgbColor blue;
    static const RgbColor yellow;
    static const RgbColor magenta;
    static const RgbColor cyan;

    RgbColor mix(RgbColor additive, double weight);
    RgbColor mix(RgbColor additive, double weight1, double weight2);
    RgbColor tint(double weight) { return mix(white, weight); }
    RgbColor shade(double weight) { return mix(black, weight); }
};

struct YuvColor {

    double y;
    double u;
    double v;

    YuvColor() : y(0), u(0), v(0) { }
    YuvColor(double yv, double uv, double vv) : y(yv), u(uv), v(vv) { }
    YuvColor(u8 yv, u8 uv, u8 vv) : y(yv / 255.0), u(uv / 255.0), v(vv / 255.0) { }
    YuvColor(const struct RgbColor &c);
    template <TexelFormat F> YuvColor(const GpuColor<F> &c) : YuvColor(RgbColor(c)) { }

    static const YuvColor black;
    static const YuvColor white;
    static const YuvColor red;
    static const YuvColor green;
    static const YuvColor blue;
    static const YuvColor yellow;
    static const YuvColor magenta;
    static const YuvColor cyan;
};

/* A 32-bit pixel color, laid out exactly as a texel of format F.
 *
 * Mirrors vAmiga's own GpuColor<F> (Components/Denise/Colors.h) -- both
 * cores are meant to move to a shared utlib color type eventually, so the
 * two APIs are kept in step: same field name, same pack()/r()/g()/b()/a()
 * shape, same "the format is a template parameter, not a runtime field"
 * design. A GpuColor<F>'s rawValue is always already packed as format F, so
 * constructing one from raw channel values or reading r()/g()/b()/a() back
 * out is correct by construction, for whichever F it was made with -- there
 * is no separate "convert to/from the host's texel format" step left where
 * the two could disagree (the bug this design replaced in vAmiga's own DMA
 * debugger: a fixed-ABGR GpuColor silently mixed the wrong channel whenever
 * the host wasn't running in ABGR).
 *
 * Only three instantiations exist (one per TexelFormat), explicitly
 * instantiated in Colors.cpp.
 */
template <TexelFormat F>
struct GpuColor {

    u32 rawValue;

    constexpr GpuColor() : rawValue(0) {}
    constexpr explicit GpuColor(u32 v) : rawValue(v) {}
    GpuColor(const RgbColor &c);
    constexpr GpuColor(u8 r, u8 g, u8 b, u8 a = 0xFF) : rawValue(pack(r, g, b, a)) {}

    // Packs/unpacks the four channels per F -- the only place that needs to
    // know the byte layout at all.
    static constexpr u32 pack(u8 r, u8 g, u8 b, u8 a)
    {
        if constexpr (F == TexelFormat::ABGR) return u32(a) << 24 | u32(b) << 16 | u32(g) << 8 | u32(r);
        else if constexpr (F == TexelFormat::ARGB) return u32(a) << 24 | u32(r) << 16 | u32(g) << 8 | u32(b);
        else return u32(r) << 24 | u32(g) << 16 | u32(b) << 8 | u32(a); // RGBA
    }

    constexpr u8 r() const
    {
        if constexpr (F == TexelFormat::ABGR) return u8(rawValue);
        else if constexpr (F == TexelFormat::ARGB) return u8(rawValue >> 16);
        else return u8(rawValue >> 24); // RGBA
    }
    constexpr u8 g() const
    {
        if constexpr (F == TexelFormat::RGBA) return u8(rawValue >> 16);
        else return u8(rawValue >> 8); // ABGR and ARGB agree on green's position
    }
    constexpr u8 b() const
    {
        if constexpr (F == TexelFormat::ABGR) return u8(rawValue >> 16);
        else if constexpr (F == TexelFormat::ARGB) return u8(rawValue);
        else return u8(rawValue >> 8); // RGBA
    }
    constexpr u8 a() const
    {
        if constexpr (F == TexelFormat::RGBA) return u8(rawValue);
        else return u8(rawValue >> 24); // ABGR and ARGB agree on alpha's position
    }

    static const GpuColor black;
    static const GpuColor white;
    static const GpuColor red;
    static const GpuColor green;
    static const GpuColor blue;
    static const GpuColor yellow;
    static const GpuColor magenta;
    static const GpuColor cyan;

    bool operator==(const GpuColor &rhs) const {
        return rawValue == rhs.rawValue;
    }

    GpuColor mix(const RgbColor &color, double weight) const;
    GpuColor mix(const RgbColor &color, double weight1, double weight2) const;
    GpuColor tint(double weight) const { return mix(RgbColor::white, weight); }
    GpuColor shade(double weight) const { return mix(RgbColor::black, weight); }
};

}
