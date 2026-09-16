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

#include "vcconfig.h"
#include "Colors.h"

namespace vc64 {

template <TexelFormat F>
RgbColor::RgbColor(const GpuColor<F> &c)
{
    r = c.r() / 255.0;
    g = c.g() / 255.0;
    b = c.b() / 255.0;
}

template RgbColor::RgbColor(const GpuColor<TexelFormat::ABGR> &);
template RgbColor::RgbColor(const GpuColor<TexelFormat::ARGB> &);
template RgbColor::RgbColor(const GpuColor<TexelFormat::RGBA> &);

RgbColor::RgbColor(const YuvColor &c)
{
    r = c.y + 1.140 * c.v;
    g = c.y - 0.395 * c.u - 0.581 * c.v;
    b = c.y + 2.032 * c.u;
}

RgbColor
RgbColor::mix(RgbColor additive, double weight)
{
    // printf("mix: old %f %f %f weight = %f\n", r, g, b, weight);
    // printf("mix: add %f %f %f\n", additive.r, additive.g, additive.b);

    assert(additive.r <= 1.0);
    assert(additive.g <= 1.0);
    assert(additive.b <= 1.0);

    double newR = r + (additive.r - r) * weight;
    double newG = g + (additive.g - g) * weight;
    double newB = b + (additive.b - b) * weight;

    // RgbColor c = RgbColor(newR, newG, newB);
    // printf("mix: new %f %f %f\n", c.r, c.g, c.b);

    return RgbColor(newR, newG, newB);
}

RgbColor
RgbColor::mix(RgbColor additive, double weight1, double weight2)
{
    assert(additive.r <= 1.0);
    assert(additive.g <= 1.0);
    assert(additive.b <= 1.0);
    
    double newR = r * weight1 + additive.r * weight2;
    double newG = g * weight1 + additive.g * weight2;
    double newB = b * weight1 + additive.b * weight2;

    return RgbColor(newR, newG, newB);
}

const RgbColor RgbColor::black(0.0, 0.0, 0.0);
const RgbColor RgbColor::white(1.0, 1.0, 1.0);
const RgbColor RgbColor::red(1.0, 0.0, 0.0);
const RgbColor RgbColor::green(0.0, 1.0, 0.0);
const RgbColor RgbColor::blue(0.0, 0.0, 1.0);
const RgbColor RgbColor::yellow(1.0, 1.0, 0.0);
const RgbColor RgbColor::magenta(1.0, 0.0, 1.0);
const RgbColor RgbColor::cyan(0.0, 1.0, 1.0);

//
//
//

YuvColor::YuvColor(const RgbColor &c)
{
    y =  0.299 * c.r + 0.587 * c.g + 0.114 * c.b;
    u = -0.147 * c.r - 0.289 * c.g + 0.436 * c.b;
    v =  0.615 * c.r - 0.515 * c.g - 0.100 * c.b;
}

const YuvColor YuvColor::black(RgbColor::black);
const YuvColor YuvColor::white(RgbColor::white);
const YuvColor YuvColor::red(RgbColor::red);
const YuvColor YuvColor::green(RgbColor::green);
const YuvColor YuvColor::blue(RgbColor::blue);
const YuvColor YuvColor::yellow(RgbColor::yellow);
const YuvColor YuvColor::magenta(RgbColor::magenta);
const YuvColor YuvColor::cyan(RgbColor::cyan);

//
//
//

template <TexelFormat F>
GpuColor<F>::GpuColor(const RgbColor &c) :
rawValue(pack(u8(c.r * 255), u8(c.g * 255), u8(c.b * 255), 0xFF))
{

}

template <TexelFormat F> const GpuColor<F> GpuColor<F>::black(RgbColor::black);
template <TexelFormat F> const GpuColor<F> GpuColor<F>::white(RgbColor::white);
template <TexelFormat F> const GpuColor<F> GpuColor<F>::red(RgbColor::red);
template <TexelFormat F> const GpuColor<F> GpuColor<F>::green(RgbColor::green);
template <TexelFormat F> const GpuColor<F> GpuColor<F>::blue(RgbColor::blue);
template <TexelFormat F> const GpuColor<F> GpuColor<F>::yellow(RgbColor::yellow);
template <TexelFormat F> const GpuColor<F> GpuColor<F>::magenta(RgbColor::magenta);
template <TexelFormat F> const GpuColor<F> GpuColor<F>::cyan(RgbColor::cyan);

template <TexelFormat F>
GpuColor<F>
GpuColor<F>::mix(const RgbColor &color, double weight) const
{
    RgbColor mixedColor = RgbColor(*this).mix(color, weight);
    return GpuColor<F>(mixedColor);
}

template <TexelFormat F>
GpuColor<F>
GpuColor<F>::mix(const RgbColor &color, double weight1, double weight2) const
{
    RgbColor mixedColor = RgbColor(*this).mix(color, weight1, weight2);
    return GpuColor<F>(mixedColor);
}

// GpuColor<F> exists for exactly these three formats -- explicitly
// instantiate all of it here rather than pulling the definitions into the
// header, keeping the format-specific bit-twiddling compiled once each.
template struct GpuColor<TexelFormat::ABGR>;
template struct GpuColor<TexelFormat::ARGB>;
template struct GpuColor<TexelFormat::RGBA>;

}
