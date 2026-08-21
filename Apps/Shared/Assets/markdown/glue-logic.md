# Glue Logic

## Description

Selects the implementation used for the C64's supporting glue logic. Glue logic
consists of the circuitry responsible for address decoding, memory control,
clock distribution, bus arbitration, and communication between the major system
components.

Throughout the production life of the Commodore 64, this functionality was
implemented using different hardware designs. Early motherboards relied on a
collection of standard logic chips, while later designs integrated much of the
same functionality into custom Commodore integrated circuits.

The differences are largely invisible to software and have only a minor impact
on emulation.

---

## Discrete

Early Commodore 64 motherboards implement glue logic using a collection of
individual TTL logic chips. These devices work together with the PLA to
generate control signals, perform address decoding, and coordinate access to
shared system resources.

This configuration is typical of the original breadbox C64 and reflects the
hardware design of early production units.

**Implementation:** Multiple discrete logic devices  
**Typical systems:** Early breadbox C64

---

## Custom IC

Later Commodore 64 revisions integrate much of the glue logic into one or more
custom Commodore chips. This reduces component count, lowers manufacturing
costs, and simplifies the motherboard design while preserving software
compatibility.

From a software perspective, the resulting system behaves almost identically to 
earlier machines, except for slight timing differences during specific memory 
access scenarios.

**Implementation:** Integrated custom logic  
**Typical systems:** C64C and later motherboard revisions