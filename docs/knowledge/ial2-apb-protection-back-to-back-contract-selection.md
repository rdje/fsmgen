---
id: ial2-apb-protection-back-to-back-contract-selection
title: APB protection back-to-back contract selected
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.627?"
  - "which APB protection back-to-back sources are selected?"
  - "what protected APB timing behavior should .628 implement?"
  - "does APB protection back-to-back include data16-protection?"
  - "does APB protection back-to-back include multi-peripheral timing?"
date: 2026-06-28
status: current
tags: [ial2, apb, protection, pprot, back-to-back, contract, selection, task-tree]
evidence: docs/IAL2_APB_PROTECTION_BACK_TO_BACK_CONTRACT_SELECTION.md; docs/IAL2_POST_APB_DATA16_BACK_TO_BACK_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_PPROT_EFFECTS_BEHAVIOR.md; docs/IAL2_APB_SIDEBAND_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.627|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.628|apb_completer_multi_register_sideband_protection_back_to_back|apb_composition_multi_register_sideband_protection_status_back_to_back|data16-protection timing|multi-peripheral' docs/IAL2_APB_PROTECTION_BACK_TO_BACK_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.627` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.628` to directly implement exactly four
APB sideband-aware protection back-to-back public sources:

- `ppif/apb_completer_multi_register_sideband_protection_back_to_back.ppif`
- `ppif/apb_completer_multi_register_sideband_protection_back_to_back.apb`
- `ppif/apb_composition_multi_register_sideband_protection_status_back_to_back.ppif`
- `ppif/apb_composition_multi_register_sideband_protection_status_back_to_back.apb`

The selected standalone completer is 32-bit, sideband-aware, has `PPROT width
3`, `PSTRB width 4`, and exactly two protected registers: `reg0` at address
`0` with read allow/write privileged-1, and `reg1` at address `4` with
read/write privileged-1. It adds adjacent setup admission while preserving
the existing allowed, denied, zero-strobe, and unmapped access semantics.

The selected fixed composition combines the `.612` sideband requester
`accepted/busy/status` depth-1 queued timing policy with that protected
two-register completer. It propagates `PPROT/PSTRB/PWDATA`, exposes aggregate
`back_to_back_policy`, and leaves enforcement owned by the completer.

Data16-protection timing, multi-peripheral multi-register timing propagation,
deeper queues, alternate overflow, accepted-less requesters, multiple active
APB transfers, broader protection policies, direct backend, verification-output,
backend-language variants, AXI, AHB, and VHDL remain deferred after `.627`.
