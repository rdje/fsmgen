---
id: fsmgen-source-hir-concrete-control-v2-contract
title: SourceHIR v2 selects a private semantic concrete-control route to canonical IAL1
answers:
  - "what is the second SourceHIR lowering route?"
  - "which IAL1 fixture is the SourceHIR v2 golden?"
  - "does SourceHIR v2 store raw ISF syntax?"
  - "how will SourceHIR concrete control lower to IAL1?"
  - "what does FSMGEN-HIR-ROADMAP-FRONTIER.6 select?"
date: 2026-07-30
status: current
tags: [source-hir, concrete-control, ial1, isf, contract, private]
evidence: docs/FSMGEN_SOURCE_HIR_CONCRETE_CONTROL_V2_CONTRACT.md; docs/decisions/0030-source-hir-v2-is-a-semantic-concrete-control-subset.md; docs/tasks/FSMGEN-HIR-ROADMAP-FRONTIER.md; isf/phase_test.isf; perl/FSM/Adapter/ISF.pm; perl/FSM/Adapter/ISF/Parser.pm; perl/FSM/Scheduler/ISF.pm; t/1179-isf-phase-stage-boundary.t; t/1312-isf-phase-fixture-coverage.t
reverify: prove -Iperl t/1179-isf-phase-stage-boundary.t t/1312-isf-phase-fixture-coverage.t && ./bin/fsmgen --strict --check --json isf/phase_test.isf && ./bin/fsmgen --emit-schedule-json isf/phase_test.isf
---

SourceHIR version 2 selects one private `concrete_control` semantic actor
subset and canonical ISF renderer. It models clock/reset, ordered typed ports,
parameter-to-output named drives, and a linear trigger/phase/completion
transaction; it does not store raw Lispish forms, arbitrary expressions, or a
copy of the ISF parser AST.

The renderer must reproduce `isf/phase_test.isf` exactly: 17 lines, 395 bytes,
SHA-256 `6eeab6c6f2e87c4a91f97fd8c0f2535334a163a7ccf263f30dfcefae51b0d2f2`.
Rendered text re-enters `FSM::Adapter::ISF` and `FSM::Scheduler::ISF`; the
current IAL0 oracle is one 45-line, 484-byte `phase_test.fsm` with SHA-256
`8b82ddb329a6b625d0ec271d9611b35140414a2c84e775c1615e442cdfa65047`.

Implementation is complete and remains private under `.7`, using the existing
SourceHIR object and builder, new `FSM::IR::SourceHIRISFRenderer`, and focused
t1548. The golden ISF and IAL0 hashes, equal typed actor/schedule, provenance,
ordered variants, and no-public-surface rule are proved. Version 1 and every
public CLI/report/manifest/accounting surface remain unchanged. Clean contract
commit `f42fb033d` activated `.7` continuity-only before implementation; clean
implementation commit `8876adb0b` activates `.8` continuity-only for the next
audit.
