---
id: axi-ial2-valid-ready-generator-first-slice
title: AXI IAL2 Valid-Ready generator first slice
answers:
  - "is any IAL2 implementation shipped?"
  - "what is the first shipped AXI-derived IAL2 implementation?"
  - "how do I use the AXI Valid-Ready IAL2 generator?"
  - "does AXI Valid-Ready IAL2 lower directly to .fsm?"
  - "does AXI Valid-Ready IAL2 have a public CLI suffix?"
date: 2026-06-12
status: current
tags: [axi, ial2, valid-ready, generator, isf, lowering]
evidence: docs/AXI_IAL2_VALID_READY_GENERATOR_FIRST_SLICE.md; perl/FSM/IAL2/ProtocolIntent/ValidReadyChannel.pm; t/1435-axi-ial2-valid-ready-generator.t; docs/tasks/AXI-IAL2-VALID-READY-GENERATOR-FIRST-SLICE.md
reverify: prove -Iperl t/1435-axi-ial2-valid-ready-generator.t
---

`FSM::IAL2::ProtocolIntent::ValidReadyChannel` is the first shipped
behavior-bearing IAL2 slice. It is an in-process API, not a public file parser
or CLI suffix. It accepts one AXI Valid-Ready contract object, emits reviewable
generated `.isf`, parses that `.isf` through `FSM::Adapter::ISF`, lowers it
through `FSM::Scheduler::ISF` to reviewable `.fsm`, and returns an IAL2
source-anchor/residue report.

The first slice is monitor-only. It reports `VALID && READY` as the transfer
condition and generates assertion carriers for prior-cycle stalled `VALID`
hold plus payload/control stability. Public `.pif`, `.ppi`, `.ppif`, `.axi`,
and full AXI manager behavior remain unshipped.
