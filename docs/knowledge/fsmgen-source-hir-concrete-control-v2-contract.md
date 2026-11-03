---
id: fsmgen-source-hir-concrete-control-v2-contract
title: SourceHIR v2 selects a private semantic concrete-control route to canonical IAL1
answers:
  - "what is the second SourceHIR lowering route?"
  - "which IAL1 fixture is the SourceHIR v2 golden?"
  - "does SourceHIR v2 store raw ISF syntax?"
  - "how will SourceHIR concrete control lower to IAL1?"
  - "what does FSMGEN-HIR-ROADMAP-FRONTIER.6 select?"
date: 2026-11-03
status: current
tags: [source-hir, concrete-control, ial1, isf, contract, private]
evidence: docs/tasks/PUBLICATION-REGRESSION-REPAIRS.md; t/1548-source-hir-phase-control.t; docs/FSMGEN_SOURCE_HIR_CONCRETE_CONTROL_V2_CONTRACT.md; docs/decisions/0030-source-hir-v2-is-a-semantic-concrete-control-subset.md; docs/tasks/FSMGEN-HIR-ROADMAP-FRONTIER.md; isf/phase_test.isf; perl/FSM/Adapter/ISF.pm; perl/FSM/Adapter/ISF/Parser.pm; perl/FSM/Scheduler/ISF.pm; t/1179-isf-phase-stage-boundary.t; t/1312-isf-phase-fixture-coverage.t
reverify: prove -Iperl t/1548-source-hir-phase-control.t t/1179-isf-phase-stage-boundary.t t/1312-isf-phase-fixture-coverage.t && ./bin/fsmgen --strict --check --json isf/phase_test.isf && ./bin/fsmgen --emit-schedule-json isf/phase_test.isf
---

SourceHIR v2 selects a private `concrete_control` semantic actor and canonical ISF renderer: clock/reset, ordered typed ports, parameter-to-output named drives and a linear trigger/phase/completion transaction. It stores no raw Lispish forms, arbitrary expressions or ISF parser AST copy.

The renderer reproduces `isf/phase_test.isf` exactly: 17 lines, 395 bytes, SHA-256 `6eeab6c6f2e87c4a91f97fd8c0f2535334a163a7ccf263f30dfcefae51b0d2f2`. Re-entry uses `FSM::Adapter::ISF` and `FSM::Scheduler::ISF`; current IAL0 is one 51-line/558-byte `phase_test.fsm`, SHA-256 `92c497ecb22354ed661af4d2873b31fab44605179b838e3825b04d564af6fe83`, including explicit authored-port roles. The original July oracle remains dated evidence in the promotion audit.

Implementation .7 remains private, reusing the SourceHIR object/builder and adding `FSM::IR::SourceHIRISFRenderer`. T1548 proves exact ISF/IAL0 hashes, equal actor/schedule, provenance, ordered variants and no public exposure. Version1 and public CLI/report/manifest/accounting surfaces remain unchanged. Contractf42fb033d activates .7 continuity-only; implementation8876adb0b activates .8; decision0031 retains the validated two-route seam privately.
