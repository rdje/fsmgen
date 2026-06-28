---
id: ial2-apb-multi-peripheral-data16-protection-back-to-back-behavior
title: APB multi-peripheral data16 protection back-to-back behavior shipped
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.634?"
  - "which APB multi-peripheral data16 protection back-to-back behavior shipped?"
  - "which APB multi-peripheral data16 protection back-to-back samples are supported?"
  - "what APB multi-peripheral data16 protection timing residue remains after .634?"
date: 2026-06-28
status: current
tags: [ial2, apb, data16, protection, pprot, multi-peripheral, back-to-back, behavior, task-tree]
evidence: docs/IAL2_APB_MULTI_PERIPHERAL_DATA16_PROTECTION_BACK_TO_BACK_BEHAVIOR.md; ppif/apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back.ppif; ppif/apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back.apb; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1470-ial2-apb-profile-alias.t; t/1472-ial2-apb-composition.t; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.634|apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back|peripheral_completers|propagate_queued_setup_without_idle_cycle|apb_additional_back_to_back_policies_deferred' docs/IAL2_APB_MULTI_PERIPHERAL_DATA16_PROTECTION_BACK_TO_BACK_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm perl/FSM/Support/RegressionCorpus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.634` ships the bounded APB
sideband-aware multi-peripheral data16-protection back-to-back timing-policy
behavior.

The supported public sources are:

- `ppif/apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back.ppif`
- `ppif/apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back.apb`

The selected behavior keeps the two-peripheral status/control protected
data16 topology, 32-bit APB addresses, 16-bit data, `PPROT width 3`, `PSTRB
width 2`, 2-byte-aligned windows at `0` and `258`, and
peripheral-completer-owned register-local privileged `PPROT[0]` policy. It
adds requester `accepted/busy/status` depth-1 queued timing, adjacent setup on
both protected peripheral completers, propagation-only interconnect queued
setup decode, active-access-only unmapped completion, and aggregate
multi-peripheral `back_to_back_policy` reporting.

The selected surfaces remove broad `apb_back_to_back_policy_deferred` and
retain narrowed future timing, broader protection, and remaining-width
residue. Broader multi-peripheral multi-register timing, deeper queues,
alternate overflow, accepted-less requesters, multiple active APB transfers,
broader protection policies, direct backend, verification-output,
backend-language variants, AXI, AHB, and VHDL remain deferred.
