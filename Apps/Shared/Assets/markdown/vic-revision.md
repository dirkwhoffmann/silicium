# VIC-II Revision

## Description

Selects the exact VIC-II (Video Interface Chip) revision used for video
emulation. Commodore produced several VIC-II revisions throughout the lifetime
of the C64, differing in video timing, sprite handling, and hardware quirks.

Most software works on all revisions, but some demos, test programs, and
hardware-specific effects depend on the behavior of a particular chip version.
For the highest authenticity, choose the revision that matches the original
hardware being emulated.

---

## MOS 6569 R1 (PAL)

The 6569R1 is the earliest PAL VIC-II revision used in the first production
runs of the Commodore 64. It contains several hardware bugs and behavioral
differences that were corrected in later revisions.

This revision is primarily of historical interest and is required only for
software that specifically targets early PAL machines.

**Video standard:** PAL  
**Technology:** NMOS  
**Typical systems:** Early 1982 C64 units

---

## MOS 6569 R3 (PAL)

The 6569R3 is the most common PAL VIC-II revision and represents the behavior
of the majority of classic European Commodore 64 systems. Most PAL software,
games, and demos were developed and tested on this revision.

For general PAL emulation, this is usually the most appropriate choice.

**Video standard:** PAL  
**Technology:** NMOS  
**Typical systems:** Standard breadbox C64

---

## MOS 8565 (PAL)

The 8565 is the HMOS-II successor to the 6569 and was used in the later C64C.
It consumes less power and exhibits slightly different internal behavior than
the earlier NMOS chips.

This revision is associated with the well-known "gray dot" (or "sparkle")
artifact that can appear when registers are written during active display
generation.

**Video standard:** PAL  
**Technology:** HMOS-II (VIC-IIe)  
**Typical systems:** C64C

---

## MOS 6567 R56A (NTSC)

The 6567R56A is the earliest NTSC VIC-II revision. Unlike later NTSC chips, it
generates **64 clock cycles per raster line**, resulting in timing differences
that affect some cycle-exact software.

This revision is required for accurate emulation of very early NTSC machines.

**Video standard:** NTSC  
**Technology:** NMOS  
**Raster timing:** 64 cycles per line  
**Typical systems:** Early NTSC C64

---

## MOS 6567 (NTSC)

The later 6567 revision became the standard NTSC VIC-II and corrected several
issues found in the earlier R56A version. It uses **65 clock cycles per raster
line**, which became the timing target for most NTSC software.

For general NTSC emulation, this is usually the preferred choice.

**Video standard:** NTSC  
**Technology:** NMOS  
**Raster timing:** 65 cycles per line  
**Typical systems:** Standard NTSC C64

---

## MOS 8562 (NTSC)

The 8562 is the HMOS-II version of the NTSC VIC-II and was used in NTSC C64C
systems. Like its PAL counterpart (8565), it features lower power consumption
and slightly different internal behavior than the original NMOS revisions.

It also exhibits the characteristic HMOS-II gray-dot artifact behavior.

**Video standard:** NTSC  
**Technology:** HMOS-II (VIC-IIe)  
**Typical systems:** NTSC C64C

---

## Which Revision Should I Choose?

- **6569 R3** - Most common choice for PAL C64 software.
- **6567** - Most common choice for NTSC C64 software.
- **8565 / 8562** - Emulate a C64C with the later HMOS-II VIC-IIe.
- **6569 R1** - Emulate very early PAL hardware.
- **6567 R56A** - Emulate very early NTSC hardware with 64-cycle raster timing.

Unless a program specifically requires a particular VIC-II revision, the
standard PAL (6569R3) or NTSC (6567) variants provide the best compatibility
with classic Commodore 64 software.
```
