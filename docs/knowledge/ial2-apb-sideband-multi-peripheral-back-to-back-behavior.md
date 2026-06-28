---
id: ial2-apb-sideband-multi-peripheral-back-to-back-behavior
title: APB sideband multi-peripheral back-to-back behavior shipped
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.618?"
  - "does APB sideband multi-peripheral back-to-back timing propagation ship?"
  - "which APB sideband multi-peripheral back-to-back samples are supported?"
  - "which APB back-to-back timing variants remain deferred after .618?"
date: 2026-06-28
status: current
tags: [ial2, apb, sideband, multi-peripheral, back-to-back, behavior, task-tree]
evidence: docs/IAL2_APB_SIDEBAND_MULTI_PERIPHERAL_BACK_TO_BACK_BEHAVIOR.md; ppif/apb_composition_multi_peripheral_sideband_status_back_to_back.ppif; ppif/apb_composition_multi_peripheral_sideband_status_back_to_back.apb; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1470-ial2-apb-profile-alias.t; t/1472-ial2-apb-composition.t; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition_multi_peripheral_sideband_status_back_to_back.ppif && ./bin/fsmgen --quiet --strict --check --json ppif/apb_composition_multi_peripheral_sideband_status_back_to_back.apb && ./bin/fsmgen --quiet --strict --emit-semantic-json ppif/apb_composition_multi_peripheral_sideband_status_back_to_back.ppif && prove -Iperl t/1470-ial2-apb-profile-alias.t t/1472-ial2-apb-composition.t t/248-regression-corpus-accounting.t t/297-capability-manifest.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.618` ships the bounded 32-bit
sideband-aware APB multi-peripheral status back-to-back family.

The supported public sources are:

- `ppif/apb_composition_multi_peripheral_sideband_status_back_to_back.ppif`
- `ppif/apb_composition_multi_peripheral_sideband_status_back_to_back.apb`

The selected contract has one requester, exactly two peripheral completers,
requester `accepted/busy/status`, depth-1 queued requester timing,
`PPROT width 3`, `PSTRB width 4`, adjacent setup admission on every
one-register peripheral completer, and the existing static non-overlapping
status/control address-map/decode shape.

Generated behavior reuses the `.612` requester queued `PPROT/PSTRB` capture,
the `.615` adjacent sideband completer setup admission, and the existing
propagation-only multi-peripheral interconnect. The interconnect decodes
queued setup using current `PSEL/PADDR` with `PENABLE` low and fans out
`PPROT/PSTRB` to the selected peripherals without inserting an idle cycle.

The selected top, requester, interconnect, and peripheral report surfaces
remove broad `apb_back_to_back_policy_deferred` residue. They retain narrowed
future-policy residue plus `apb_protection_policy_effects_deferred` because
this slice propagates `PPROT` values but does not add new access-control
semantics.

Data16/protection back-to-back timing variants, multi-register timing policy,
deeper queues, alternate overflow, accepted-less requesters, multiple active
APB transfers, multi-requester interconnects, direct backend,
verification-output, backend-language variants, AXI, AHB, and VHDL remain
deferred.
