---
id: fsmgen-source-hir-phase-control-implementation
title: Private SourceHIR concrete-control route to canonical IAL1 implemented
answers:
  - "is the second SourceHIR lowering route implemented?"
  - "which package renders SourceHIR to ISF?"
  - "does SourceHIR v2 reproduce phase_test.isf?"
  - "does SourceHIR v2 preserve the phase_test IAL0 output?"
  - "how are SourceHIR ISF diagnostics mapped?"
  - "is SourceHIR v2 public?"
date: 2026-07-30
status: current
tags: [source-hir, concrete-control, ial1, isf, implementation, private]
evidence: perl/FSM/IR/SourceHIR.pm; perl/FSM/IR/SourceHIRBuilder.pm; perl/FSM/IR/SourceHIRISFRenderer.pm; t/1548-source-hir-phase-control.t; t/1547-source-hir-valid-ready.t; t/1179-isf-phase-stage-boundary.t; t/1312-isf-phase-fixture-coverage.t; docs/FSMGEN_SOURCE_HIR_CONCRETE_CONTROL_V2_CONTRACT.md; docs/tasks/FSMGEN-HIR-ROADMAP-FRONTIER.md; isf/phase_test.isf
reverify: prove -Iperl t/1548-source-hir-phase-control.t t/1547-source-hir-valid-ready.t t/1179-isf-phase-stage-boundary.t t/1312-isf-phase-fixture-coverage.t
---

The private SourceHIR version-2 `concrete_control` route is implemented by
`FSM::IR::SourceHIR`, `FSM::IR::SourceHIRBuilder`, and
`FSM::IR::SourceHIRISFRenderer`. The closed semantic object models one actor,
clock/reset, ordered typed ports, one parameter-to-output drive, and one linear
trigger/phase/completion transaction without raw ISF or parser-AST storage.

T1548 proves canonical output equals `isf/phase_test.isf` at 17 lines, 395
bytes, and SHA-256
`6eeab6c6f2e87c4a91f97fd8c0f2535334a163a7ccf263f30dfcefae51b0d2f2`.
The generated text re-enters the shipped adapter/scheduler and preserves one
45-line, 484-byte `phase_test.fsm` with SHA-256
`8b82ddb329a6b625d0ec271d9611b35140414a2c84e775c1615e442cdfa65047`,
plus the equal typed actor and schedule report.

Generated-position errors map through the private 14-nonblank-line-plus-root
source map. Because current parser failures may omit a generated position, the
remapper truthfully falls back to SourceHIR root provenance instead of
inventing a field location. The implementation adds no CLI, public schema,
serialization, report, manifest, capability, or support-accounting surface.
Clean implementation commit `8876adb0b` activates `.8` continuity-only for the
evidence-based two-route disposition audit. Decision `0031` now retains the
validated seam privately and selects no third architecture-only route.
