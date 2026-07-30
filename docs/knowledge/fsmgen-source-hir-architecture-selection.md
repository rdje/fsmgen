---
id: fsmgen-source-hir-architecture-selection
title: SourceHIR selected as a private pre-IAL semantic boundary
answers:
  - "what is the selected source-facing FSMGEN HIR boundary?"
  - "does source-facing HIR extend IntentHIR?"
  - "what is the first SourceHIR builder?"
  - "what is the first SourceHIR golden fixture?"
  - "is SourceHIR public?"
  - "how does SourceHIR lower into IAL2?"
date: 2026-07-30
status: current
tags: [architecture, source-hir, hir, ial2, ppif, valid-ready, diagnostics]
evidence: docs/FSMGEN_SOURCE_HIR_ARCHITECTURE_SELECTION.md; docs/FSMGEN_SOURCE_HIR_POST_PROTOTYPE_AUDIT.md; docs/decisions/0028-source-facing-hir-is-a-distinct-private-pre-ial-layer.md; docs/decisions/0029-source-hir-remains-private-through-a-second-lowering-route.md; docs/tasks/FSMGEN-HIR-ROADMAP-FRONTIER.md; docs/IR_POLICY.md; perl/FSM/IR/IntentHIR.pm; perl/FSM/IR/LoweredRTLIR.pm; perl/FSM/IR/StructuralRTLIR.pm; ppif/valid_ready_handshake.ppif
reverify: rg -n 'FSM::IR::SourceHIR|valid_ready_handshake\.ppif|private|canonical.*PPIF|IntentHIR' docs/FSMGEN_SOURCE_HIR_ARCHITECTURE_SELECTION.md docs/decisions/0028-source-facing-hir-is-a-distinct-private-pre-ial-layer.md docs/tasks/FSMGEN-HIR-ROADMAP-FRONTIER.md docs/book/src/14-feature-backlog.md
---

`FSMGEN-HIR-ROADMAP-FRONTIER.2` selects a distinct private
`FSM::IR::SourceHIR` above IAL2/IAL1. It does not extend the existing
post-parse `IntentHIR`.

The first producer is a repository-internal constrained Perl builder. It
constructs exactly one protocol-neutral valid-ready object, validates it, and
renders canonical `.ppif` text. That text must pass through the existing PPIF
parser/validator and normal `IAL2 -> IAL1 -> IAL0` chain.

The first golden is `ppif/valid_ready_handshake.ppif`, reproduced byte-for-
byte. The raw object, builder input, and source map remain private; no public
host-language API or report schema is selected.

Leaf `.3` freezes the exact keys, private package APIs, provenance,
diagnostics, renderer/source-map result, t1547 owner, and byte-equivalence
oracle in `docs/FSMGEN_SOURCE_HIR_V1_CONTRACT.md`. Implementation remains
private; `.4` implements the exact three-package/t1547 contract without a
public surface. Audit `.5` now retains the boundary privately through one
concrete-control-to-IAL1 proof; decision `0029` owns that refinement and keeps
public builder selection separate. Clean commit `5d018edbd` activates only
the `.6` design leaf.
