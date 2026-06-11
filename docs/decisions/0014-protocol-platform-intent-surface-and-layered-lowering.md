# 0014 — Protocol/platform intent surface and layered lowering for IAL2

- Date: 2026-06-12
- Type: architecture
- Status: accepted-partial

## Context

IAL2 is intended to express protocol and platform intent above explicit IAL1
actor/network scheduling. The user clarified that IAL2 must apply across
protocol families, including AXI, CHI, ACE, AHB, APB, ATB, and future
protocols, rather than becoming an AXI-only language surface.

The user also clarified that IAL2 must not lower directly to IAL0 `.fsm`.
IAL2 behavior must first become reviewable IAL1 `.isf`, and only then lower to
IAL0 `.fsm`.

The exact extension name is still being shaped. Current candidate directions
are:

- `.pif`: Protocol Intent Format.
- `.ppi`: Protocol/Platform Intent.
- `.ppif`: Protocol/Platform Intent Format.

## Decision

Future IAL2 must use a protocol/platform-generic file surface. Do not use
protocol-specific IAL2 extensions such as `.axi`.

A future IAL2 file can declare or select a protocol vocabulary inside the file,
but the file surface itself remains generic enough for protocol and platform
intent across AXI, CHI, ACE, AHB, APB, ATB, and future protocols.

The mandatory lowering chain is:

```text
IAL2 -> IAL1 / .isf -> IAL0 / .fsm -> HDL
```

Direct `IAL2 -> IAL0` lowering is forbidden. Direct IAL2-to-`.fsm`
generation is also forbidden, even as a shortcut.

The exact extension name remains open among `.pif`, `.ppi`, `.ppif`, or a
future explicitly accepted generic variant. Protocol-specific names remain
out of bounds.

## Consequences

- `.isf` remains IAL1 and should not become a mixed IAL1/IAL2 container.
- Future IAL2 tooling must emit or preserve reviewable IAL1 before IAL0
  exists.
- Protocol vocabulary can be selected inside the IAL2 file, but extension,
  tooling identity, and documentation must remain protocol/platform-generic.
- AXI manager work is one IAL2 vocabulary candidate, not a language boundary.
- Any future implementation requires a new exact task-tree owner for parser,
  diagnostics, lowering, emitted IAL1, emitted IAL0, reports, tests, and
  mdBook examples.
