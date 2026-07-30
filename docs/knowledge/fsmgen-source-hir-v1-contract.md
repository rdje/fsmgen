---
id: fsmgen-source-hir-v1-contract
title: Private SourceHIR v1 valid-ready contract selected
answers:
  - "what keys are in SourceHIR version 1?"
  - "what methods build and render SourceHIR v1?"
  - "how are SourceHIR diagnostics represented?"
  - "how are PPIF errors remapped to SourceHIR provenance?"
  - "what test owns SourceHIR implementation?"
  - "what is the SourceHIR byte-equivalence oracle?"
date: 2026-07-30
status: current
tags: [architecture, source-hir, contract, ppif, valid-ready, provenance, diagnostics]
evidence: docs/FSMGEN_SOURCE_HIR_V1_CONTRACT.md; docs/FSMGEN_SOURCE_HIR_ARCHITECTURE_SELECTION.md; docs/tasks/FSMGEN-HIR-ROADMAP-FRONTIER.md; ppif/valid_ready_handshake.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/ValidReadyChannel.pm
reverify: rg -n 'validate_valid_ready|build_valid_ready|render_ppif|diagnostic_from_ppif_error|t/1547|428|6cbc68152c9e1658a341994bc2ccdd83bdb94b26aedd20d4180c996b5124f7ac' docs/FSMGEN_SOURCE_HIR_V1_CONTRACT.md docs/tasks/FSMGEN-HIR-ROADMAP-FRONTIER.md
---

SourceHIR version 1 is a private, closed, immutable object for exactly one
protocol-neutral valid-ready channel. `FSM::IR::SourceHIRBuilder` validates and
builds it; `FSM::IR::SourceHIRPPIFRenderer` emits canonical PPIF plus a private
source map.

The object records schema/root identity, intent/profile, source object and
ordered anchors, channel/reset/endpoints/ordered payload, and repository-local
or logical provenance keyed by JSON-Pointer-style semantic paths. Diagnostics
are private structured hashes with stable internal codes and deterministic
source-location fallback.

The first oracle is byte equality with `ppif/valid_ready_handshake.ppif`:
14 lines, 428 bytes, SHA-256
`6cbc68152c9e1658a341994bc2ccdd83bdb94b26aedd20d4180c996b5124f7ac`.
Completed implementation leaf `.4` owns the three packages and focused
`t/1547-source-hir-valid-ready.t`; no public API/report/accounting surface is
selected. Audit `.5` retains this version-1 path privately and selects a
separate concrete-control-to-IAL1 design leaf before promotion is
reconsidered. Leaf `.6` now selects additive discriminated schema version 2
for that route; version 1 stays unchanged.
