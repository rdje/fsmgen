---
id: fsmgen-source-hir-valid-ready-implementation
title: Private SourceHIR valid-ready golden path implemented
answers:
  - "is SourceHIR implemented?"
  - "which SourceHIR packages exist?"
  - "does SourceHIR reproduce the PPIF golden?"
  - "does SourceHIR bypass the PPIF parser?"
  - "is SourceHIR a public API?"
date: 2026-07-30
status: current
tags: [source-hir, implementation, ppif, valid-ready, private, golden]
evidence: perl/FSM/IR/SourceHIR.pm; perl/FSM/IR/SourceHIRBuilder.pm; perl/FSM/IR/SourceHIRPPIFRenderer.pm; t/1547-source-hir-valid-ready.t; docs/FSMGEN_SOURCE_HIR_V1_CONTRACT.md; docs/tasks/FSMGEN-HIR-ROADMAP-FRONTIER.md; ppif/valid_ready_handshake.ppif
reverify: prove -Iperl t/1547-source-hir-valid-ready.t
---

The private SourceHIR version-1 valid-ready path is implemented by
`FSM::IR::SourceHIR`, `FSM::IR::SourceHIRBuilder`, and
`FSM::IR::SourceHIRPPIFRenderer`.

Focused t1547 proves closed validation, immutability, defensive clones,
relative/logical provenance, deterministic diagnostics, generated-line and
root-fallback remapping, ordered variants, and exact byte equality with the
tracked 14-line/428-byte PPIF fixture. The rendered text is reparsed through
the existing PPIF adapter and produces the same IAL1, IAL0, schedule, and
protocol reports as the hand-written fixture.

The implementation is private and adds no CLI, normalized report, capability
manifest, support-accounting entry, public builder package, or direct IAL2
generator call.

Post-prototype audit `.5` keeps the implementation private: its healthy
equivalence proof rejects retirement, while one test producer, one schema, and
only an IAL2 renderer reject immediate public promotion. The next design leaf
now selects semantic SourceHIR version 2 and a phase-test IAL1 golden. The
version-1 implementation remains unchanged after `.7` implements the separate
private concrete-control route; `.8` owns the next promotion audit.
