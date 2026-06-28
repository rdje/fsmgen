---
id: ial2-apb-sideband-composition-back-to-back-readiness-audit
title: APB sideband composition back-to-back audit selects contract owner
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.613?"
  - "is APB sideband fixed composition back-to-back ready?"
  - "what APB sideband back-to-back owner comes after .613?"
  - "why does sideband composition back-to-back need a contract selection?"
  - "what should .614 select?"
date: 2026-06-28
status: current
tags: [ial2, apb, sideband, composition, completer, back-to-back, readiness, task-tree]
evidence: docs/IAL2_APB_SIDEBAND_COMPOSITION_BACK_TO_BACK_READINESS_AUDIT.md; docs/IAL2_APB_SIDEBAND_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_BACK_TO_BACK_CONTRACT_SELECTION.md; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md
reverify: rg "IAL2-FEATURE-COMPLETENESS-FRONTIER\\.613|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.614|sideband-aware APB completer|fixed-composition|apb_back_to_back_policy_deferred" docs/IAL2_APB_SIDEBAND_COMPOSITION_BACK_TO_BACK_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.613` audits APB sideband-aware completer
and composition back-to-back readiness after `.612` shipped requester queued
`PPROT/PSTRB` capture.

The audit selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.614`, a no-behavior
contract-selection owner for the bounded 32-bit sideband-aware APB completer
and fixed-composition timing-policy family.

The requester prerequisite is present, and existing sideband completer/fixed
composition substrates already sample or propagate `PPROT/PSTRB`. The remaining
blocker is public-contract and guard scope: completer adjacent setup timing is
still restricted to the 32-bit no-sideband one-register completer, and fixed or
multi-peripheral composition timing-policy compatibility still rejects
sideband-aware wiring.

`.614` should select exact `.ppif`/`.apb` sample names, one-register sideband
completer scope, fixed-composition propagation boundary, report/support
movement, diagnostics, validation, and rollback before implementation.
Multi-peripheral sideband timing propagation, data16/protection variants,
multi-register timing policy, deeper queues, alternate overflow, direct
backend, verification-output, backend-language variants, AXI, AHB, and VHDL
remain deferred.
