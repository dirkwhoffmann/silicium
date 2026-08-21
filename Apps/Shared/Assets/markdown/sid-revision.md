# SID Revision

## Description

Selects the SID (Sound Interface Device) revision used for audio emulation in
the Commodore 64. The SID is responsible for sound synthesis and is widely
regarded as one of the most distinctive sound chips of the home computer era.

The Commodore 64 was manufactured with two major SID revisions: the MOS 6581
and the MOS 8580. While both chips are software-compatible, they differ
significantly in their analog circuitry and filter characteristics, causing
many pieces of music and sound effects to sound noticeably different.

---

## MOS 6581

The MOS 6581 is the original SID chip used in early Commodore 64 models. It is
based on NMOS technology and exhibits considerable variation between individual
chips.

Its analog filters are highly non-linear and often deviate from their nominal
specifications, producing the warm and characteristic sound commonly associated
with classic C64 music. Background noise is relatively high, and resonance can
become strongly distorted at extreme settings.

The 6581 also exhibits the well-known "volume DAC" effect. Because changes to
the master volume register influence the analog output stage, software can use
rapid volume changes to generate low-resolution sampled audio such as speech,
drums, and sound effects.

**Technology:** NMOS  
**Typical systems:** Standard breadbox C64

---

## MOS 8580

The MOS 8580 is the HMOS-II successor to the 6581 and was used in the later
C64C. It provides a cleaner and more consistent analog implementation with
reduced noise and more predictable filter behavior.

Compared to the 6581, its filters are generally more accurate and exhibit a
different frequency response. As a result, music that relies heavily on SID
filters may sound noticeably different on the 8580.

The volume DAC effect is greatly reduced, making software that depends on this
technique behave differently unless specifically adapted for the 8580.

**Technology:** HMOS-II (SID-II)  
**Typical systems:** C64C

---

## Emulation Notes

The differences between the 6581 and 8580 are
clearly audible. Many SID tunes were composed and tuned on a specific chip
revision and may sound different when played on the other.

Filter-heavy music is particularly sensitive to the selected SID revision.
Some compositions are designed specifically for the 6581, while others target
the cleaner filter characteristics of the 8580.

---

## Which Revision Should I Choose?

- **6581** - Emulates the original SID found in most classic Commodore 64 systems.
- **8580** - Emulates the later SID-II used in the C64C.
- **6581** is generally preferred for older software and demos.
- **8580** is often required for software specifically written for the C64C.

If a program recommends a particular SID revision, use that setting for the
most authentic sound reproduction. Otherwise, the 6581 is usually the best
choice for emulating a classic breadbox Commodore 64.