---
id: fsmgen-source-hir-phase-control-implementation
title: Private SourceHIR concrete-control route to canonical IAL1 implemented
answers:
  - "is the second SourceHIR lowering route implemented?"
  - "which package renders SourceHIR to ISF?"
  - "does SourceHIR v2 reproduce phase_test.isf?"
  - "does SourceHIR v2 preserve the phase_test IAL0 output?"
  - "why did T1548 phase-control IAL0 checksum change?"
  - "how are SourceHIR ISF diagnostics mapped?"
  - "is SourceHIR v2 public?"
date: 2026-11-03
status: current
tags: [source-hir, concrete-control, ial1, isf, implementation, private]
evidence: docs/tasks/PUBLICATION-REGRESSION-REPAIRS.md; perl/FSM/IR/SourceHIR.pm; perl/FSM/IR/SourceHIRBuilder.pm; perl/FSM/IR/SourceHIRISFRenderer.pm; t/1548-source-hir-phase-control.t; t/1547-source-hir-valid-ready.t; t/1179-isf-phase-stage-boundary.t; t/1312-isf-phase-fixture-coverage.t; docs/FSMGEN_SOURCE_HIR_CONCRETE_CONTROL_V2_CONTRACT.md; docs/tasks/FSMGEN-HIR-ROADMAP-FRONTIER.md; isf/phase_test.isf
reverify: prove -Iperl t/1548-source-hir-phase-control.t t/1547-source-hir-valid-ready.t t/1179-isf-phase-stage-boundary.t t/1312-isf-phase-fixture-coverage.t
---

Private SourceHIR v2 `concrete_control` uses `FSM::IR::SourceHIR`, `FSM::IR::SourceHIRBuilder` and `FSM::IR::SourceHIRISFRenderer`: one actor, clock/reset, ordered typed ports, one parameter-to-output drive and one linear trigger/phase/completion transaction; no raw ISF or parser AST storage.

T1548 reproduces `isf/phase_test.isf`: 17 lines, 395 bytes, SHA-256 `6eeab6c6f2e87c4a91f97fd8c0f2535334a163a7ccf263f30dfcefae51b0d2f2`. Shipped adapter/scheduler re-entry yields equal typed actors/reports and one current 51-line/558-byte `phase_test.fsm`, SHA-256 `92c497ecb22354ed661af4d2873b31fab44605179b838e3825b04d564af6fe83`.

The exact six-line/74-byte authored `+interface` block explains the downstream change; removing only it restores the original July checksum. Canonical ISF and remaining state/drive bytes are unchanged.

Generated-position errors use the private 14-nonblank-lines-plus-root map; missing parser positions truthfully fall back to root without inventing a field. No CLI, public schema, serialization, report, manifest, capability or support-accounting surface is added. Implementation8876adb0b activates .8's two-route disposition audit; decision0031 retains the validated seam privately without a third architecture-only route.
