---
id: ial2-apb-data16-protection-back-to-back-contract-selection
title: APB data16-protection back-to-back contract selected
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.630?"
  - "which APB data16-protection back-to-back sources are selected?"
  - "what data16 protected APB timing behavior should .631 implement?"
  - "does APB data16-protection back-to-back include multi-peripheral timing?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.631 implement?"
date: 2026-06-28
status: current
tags: [ial2, apb, data16, protection, pprot, back-to-back, contract, selection, task-tree]
evidence: docs/IAL2_APB_DATA16_PROTECTION_BACK_TO_BACK_CONTRACT_SELECTION.md; docs/IAL2_POST_APB_PROTECTION_BACK_TO_BACK_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_PROTECTION_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_DATA16_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_DATA16_PPROT_EFFECTS_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.630|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.631|apb_completer_multi_register_sideband_data16_protection_back_to_back|apb_composition_multi_register_sideband_data16_protection_status_back_to_back|multi-peripheral data16-protection timing' docs/IAL2_APB_DATA16_PROTECTION_BACK_TO_BACK_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.630` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.631` to directly implement exactly four
APB sideband-aware data16-protection back-to-back public sources:

- `ppif/apb_completer_multi_register_sideband_data16_protection_back_to_back.ppif`
- `ppif/apb_completer_multi_register_sideband_data16_protection_back_to_back.apb`
- `ppif/apb_composition_multi_register_sideband_data16_protection_status_back_to_back.ppif`
- `ppif/apb_composition_multi_register_sideband_data16_protection_status_back_to_back.apb`

No requester-only public source is selected. The fixed-composition source
must embed the already shipped data16 sideband requester timing shape and the
selected data16-protection adjacent completer shape.

The selected standalone completer is 16-bit, sideband-aware, has `PPROT width
3`, `PSTRB width 2`, `reg0` at byte address `0` with read allow/write
privileged-1, and `reg1` at byte address `2` with read/write privileged-1.
It adds adjacent setup admission while preserving allowed, denied,
zero-strobe, and unmapped access semantics.

The selected fixed composition combines the `.625` data16 sideband requester
with that protected data16 completer, propagates 16-bit `PWDATA`, `PPROT`, and
2-bit `PSTRB`, exposes aggregate `back_to_back_policy`, and leaves enforcement
owned by the completer.

Multi-peripheral data16-protection timing, broader multi-peripheral
multi-register timing, deeper queues, alternate overflow, accepted-less
requesters, multiple active APB transfers, direct backend, verification-output,
backend-language variants, AXI, AHB, and VHDL remain deferred after `.630`.
