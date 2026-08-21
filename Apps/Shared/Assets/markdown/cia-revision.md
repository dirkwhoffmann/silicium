# CIA Revision

## Description

Selects the Complex Interface Adapter (CIA) revision used for emulation. The
CIA is responsible for timers, interrupts, keyboard scanning, joystick input,
the IEC serial bus, and communication with various peripheral devices.

The Commodore 64 was manufactured with two CIA revisions. While the chips are
implemented using different fabrication technologies, their functional behavior
is nearly identical. As a result, the selected CIA revision has only a minimal
effect on emulation and rarely affects software compatibility.

---

## MOS 6526

The MOS 6526 is the original CIA used in early Commodore 64 systems. It is
based on NMOS technology and represents the classic implementation found in
most breadbox C64 models.

The vast majority of software was developed and tested on systems equipped with
this revision.

**Technology:** NMOS  
**Typical systems:** Standard breadbox C64

---

## MOS 8521

The MOS 8521 is the HMOS-II successor to the 6526 and was used in later C64C
models. It offers reduced power consumption and improved manufacturing
characteristics while maintaining compatibility with the original design.

From a software perspective, the 8521 behaves almost identically to the 6526,
and only a few hardware-level differences are known.

**Technology:** HMOS-II  
**Typical systems:** C64C
