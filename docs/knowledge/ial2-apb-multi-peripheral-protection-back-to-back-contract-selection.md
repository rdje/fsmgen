---
id: ial2-apb-multi-peripheral-protection-back-to-back-contract-selection
title: APB sideband protection multi-peripheral back-to-back sources selected
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.637?"
  - "which APB multi-peripheral protection back-to-back sources are selected?"
  - "what will IAL2-FEATURE-COMPLETENESS-FRONTIER.638 implement?"
  - "what is the selected 32-bit APB sideband protection multi-peripheral timing contract?"
date: 2026-06-28
status: current
tags: [ial2, apb, multi-peripheral, protection, sideband, back-to-back, contract, task-tree]
evidence: >-
  docs/IAL2_APB_MULTI_PERIPHERAL_PROTECTION_BACK_TO_BACK_CONTRACT_SELECTION.md; docs/IAL2_APB_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_READINESS_AUDIT.md; docs/IAL2_APB_MULTI_PERIPHERAL_DATA16_PROTECTION_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_PROTECTION_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_SIDEBAND_MULTI_PERIPHERAL_BACK_TO_BACK_BEHAVIOR.md; ppif/apb_composition_multi_peripheral_sideband_protection.ppif; ppif/apb_composition_multi_peripheral_sideband_protection.apb; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md;
  docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.637|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.638|apb_composition_multi_peripheral_sideband_protection_status_back_to_back|PPROT width 3|PSTRB width 4|apb_back_to_back_policy_deferred' docs/IAL2_APB_MULTI_PERIPHERAL_PROTECTION_BACK_TO_BACK_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm perl/FSM/Support/RegressionCorpus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.637` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.638` to directly implement exactly:

- `ppif/apb_composition_multi_peripheral_sideband_protection_status_back_to_back.ppif`
- `ppif/apb_composition_multi_peripheral_sideband_protection_status_back_to_back.apb`

The selected contract is the 32-bit protected status/control timing variant
of the existing `apb_composition_multi_peripheral_sideband_protection` family.
It uses one requester, exactly two peripheral completers, 32-bit data and
addressing, `PPROT width 3`, `PSTRB width 4`, status/control windows at `0`
and `256`, requester queued back-to-back timing with `accepted/busy/status`,
adjacent setup admission on both peripheral completers, propagation-only
interconnect decode, peripheral-completer-owned protection enforcement, and
aggregate `back_to_back_policy` reporting.

`.637` changes no behavior. `.638` owns the source pair, selected guard
widening, report/residue movement, support accounting, focused tests,
behavior docs, mdBook, Memory, Knowledge Map, and validation. No-policy
multi-peripheral multi-register timing, sideband data16 no-policy
multi-register timing, broader data16-protection generalization, generalized
register shapes, deeper queues, alternate overflow, accepted-less requesters,
multiple-active APB transfers, broader protection-policy families, direct
backend, verification-output, backend-language variants, AXI, AHB, and VHDL
remain deferred.
