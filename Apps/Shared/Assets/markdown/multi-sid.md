# Multi-SID Configuration

## Description

Enables support for additional SID chips beyond the standard single-chip
configuration. Some modified Commodore 64 systems include two or more SID chips
to achieve richer polyphony and more complex sound output. This configuration
controls whether extra SID devices are emulated and where they are mapped in
the C64 memory space.

---

## Standard SID ($D400)

The original Commodore 64 hardware contains a single SID chip mapped to the
fixed I/O address range starting at $D400. This is the default configuration
used by virtually all software and provides full compatibility with standard
games, demos, and music.

---

## Additional SIDs

In multi-SID setups, additional SID chips are mapped to secondary I/O addresses.
Software that support multi-SID setups typically uses the extra chips to extend
polyphony, add stereo separation, or dedicate one SID to percussion or effects
while the other handles melodic voices.

---

## Address Selection Notes

Because multi-SID was never part of the original Commodore 64 design, there is
no universal standard for memory mapping. Correct operation depends on matching
the exact hardware modification expected by the software being run. Incorrect
mapping may result in missing audio channels or silence on secondary voices.