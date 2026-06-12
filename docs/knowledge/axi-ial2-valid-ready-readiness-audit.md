---
id: axi-ial2-valid-ready-readiness-audit
title: AXI IAL2 Valid-Ready implementation readiness audit
answers:
  - "is the codebase ready for an AXI Valid-Ready IAL2 implementation?"
  - "which code owns the future AXI Valid-Ready IAL2 implementation path?"
  - "should AXI Valid-Ready IAL2 be added to the .isf parser?"
  - "what should the first AXI Valid-Ready IAL2 code slice avoid?"
  - "which tests are relevant to AXI Valid-Ready IAL2 readiness?"
date: 2026-06-12
status: current
tags: [axi, ial2, valid-ready, readiness, isf, lowering]
evidence: docs/AXI_IAL2_VALID_READY_READINESS_AUDIT.md; docs/AXI_IAL2_FIRST_IMPLEMENTATION_SUBSET_SELECTION.md; docs/tasks/AXI-IAL2-VALID-READY-READINESS-AUDIT.md
reverify: rg -n "Readiness Conclusions|Minimum Future Owner Map|Safe First Implementation Boundary|Explicit Deferrals" docs/AXI_IAL2_VALID_READY_READINESS_AUDIT.md
---

`docs/AXI_IAL2_VALID_READY_READINESS_AUDIT.md` records that the codebase is
ready for a narrow in-process AXI Valid-Ready IAL2 generator slice only if it
emits reviewable generated `.isf`, then uses the existing
`FSM::Adapter::ISF` and `FSM::Scheduler::ISF` path to emit reviewable `.fsm`.

The first implementation should not extend `.isf` with IAL2 source forms,
should not revive deprecated `(handshake ...)` metadata, should not add public
`.pif`/`.ppi`/`.ppif`/`.axi` CLI suffixes, and should not claim the full AXI
manager. The future owner must add a separate source-anchor/residue report
because the current schedule JSON is an IAL1 lowering report, not an IAL2
protocol-intent report.
