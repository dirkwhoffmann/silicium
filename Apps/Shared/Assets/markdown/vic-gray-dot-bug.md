# Emulate VIC-II Gray Dot Bug

## Description

Enables or disables the hardware-accurate emulation of the so called "Gray Dot Bug" (sometimes called grey dot snow or sparkling).

On original Commodore 64 hardware, this behavior is a known quirk of the newer, HMOS-II based VIC-II video chips (specifically the MOS 8565 and MOS 8562 models found in the C64C/C64 II), whereas the older NMOS chips (MOS 6569 / 6567) do not exhibit this issue.

---

## How the Bug Works
When software writes a new value to a VIC-II color register (such as the border color at $D020 or background color at $D021) at the exact cycle the chip is rendering, the pixel-clock handling momentarily glitches.
As a result, the very first pixel rendered during that specific clock cycle overrides the intended color and flickers as a light gray/white dot.
