---
id: ial2-apb-multi-peripheral-back-to-back-behavior
title: APB multi-peripheral back-to-back ships selected no-sideband status family
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.609?"
  - "does APB multi-peripheral back-to-back propagation ship?"
  - "which APB multi-peripheral back-to-back samples are supported?"
  - "how does APB back-to-back work through the generated interconnect?"
  - "what APB multi-peripheral back-to-back residue remains?"
date: 2026-06-28
status: current
tags: [ial2, apb, back-to-back, multi-peripheral, behavior, task-tree]
evidence: docs/IAL2_APB_MULTI_PERIPHERAL_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_MULTI_PERIPHERAL_BACK_TO_BACK_READINESS_AUDIT.md; docs/IAL2_APB_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_MULTI_PERIPHERAL_INTERCONNECT_BEHAVIOR.md; ppif/apb_composition_multi_peripheral_status_back_to_back.ppif; ppif/apb_composition_multi_peripheral_status_back_to_back.apb; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1470-ial2-apb-profile-alias.t; t/1472-ial2-apb-composition.t; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t
reverify: prove -Iperl t/1470-ial2-apb-profile-alias.t t/1472-ial2-apb-composition.t t/248-regression-corpus-accounting.t t/297-capability-manifest.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.609` ships the selected APB
multi-peripheral back-to-back propagation family for exactly
`ppif/apb_composition_multi_peripheral_status_back_to_back.ppif` and
`ppif/apb_composition_multi_peripheral_status_back_to_back.apb`.

The selected family is 32-bit, no-sideband, exactly two peripheral completers,
and the existing static non-overlapping address-map/decode shape. The
requester must expose `accepted`, `busy`, and `status width 2`, and use
`(timing-policy (back-to-back queued) (queue-depth 1) (overflow reject))`.
Every peripheral completer must use `(timing-policy (setup-admission
adjacent))`.

Generated behavior reuses the `.607` requester depth-1 queued path. The
generated `apb_interconnect` remains propagation-only: it decodes current
`PSEL/PADDR`, forwards `PENABLE`, muxes selected responses, and keeps unmapped
errors active-access only (`PSEL && PENABLE`). A queued setup to the same or a
different peripheral therefore propagates with `PSEL=1` and `PENABLE=0`
without an inserted idle cycle.

Reports add aggregate `back_to_back_policy` metadata, expose the requester
`accepted` field at the top, remove broad `apb_back_to_back_policy_deferred`
for the selected top/interconnect/requester/peripheral report surfaces, and
retain narrowed `apb_additional_back_to_back_policies_deferred`.

Sideband/data16/protection variants, deeper queues, alternate overflow
policies, multiple active APB bus transfers, direct backend,
verification-output, backend-language variants, AXI, AHB, and VHDL remain
deferred.
