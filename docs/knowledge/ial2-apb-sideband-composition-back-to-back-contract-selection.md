---
id: ial2-apb-sideband-composition-back-to-back-contract-selection
title: APB sideband completer and fixed-composition back-to-back contract selected
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.614?"
  - "what APB sideband back-to-back samples should .615 implement?"
  - "what is the sideband APB completer back-to-back contract?"
  - "what is the sideband APB fixed-composition back-to-back contract?"
  - "why does .615 implement sideband completer and fixed composition together?"
date: 2026-06-28
status: current
tags: [ial2, apb, sideband, composition, completer, back-to-back, contract, task-tree]
evidence: docs/IAL2_APB_SIDEBAND_COMPOSITION_BACK_TO_BACK_CONTRACT_SELECTION.md; docs/IAL2_APB_SIDEBAND_COMPOSITION_BACK_TO_BACK_READINESS_AUDIT.md; docs/IAL2_APB_SIDEBAND_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_BACK_TO_BACK_CONTRACT_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md
reverify: rg "IAL2-FEATURE-COMPLETENESS-FRONTIER\\.614|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.615|apb_completer_sideband_back_to_back|apb_composition_sideband_status_back_to_back|sideband-aware APB completer" docs/IAL2_APB_SIDEBAND_COMPOSITION_BACK_TO_BACK_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.614` selects the public contract for the
bounded 32-bit sideband-aware APB completer and fixed-composition
back-to-back timing-policy family.

`.615` should implement exactly four public sources:

- `ppif/apb_completer_sideband_back_to_back.ppif`
- `ppif/apb_completer_sideband_back_to_back.apb`
- `ppif/apb_composition_sideband_status_back_to_back.ppif`
- `ppif/apb_composition_sideband_status_back_to_back.apb`

The selected completer is one-register, 32-bit, sideband-aware
(`PPROT width 3`, `PSTRB width 4`), and uses the existing
`(timing-policy (setup-admission adjacent))` vocabulary. The selected fixed
composition combines the `.612` sideband requester back-to-back policy with
that sideband completer adjacent setup policy and sideband-aware fixed wiring.

`.615` implements the standalone sideband completer and fixed composition
together because the fixed-composition contract cannot be validated without the
sideband adjacent completer, while the requester prerequisite already shipped.
Multi-peripheral sideband timing propagation, data16/protection variants,
multi-register timing policy, deeper queues, alternate overflow, direct
backend, verification-output, backend-language variants, AXI, AHB, and VHDL
remain deferred.
