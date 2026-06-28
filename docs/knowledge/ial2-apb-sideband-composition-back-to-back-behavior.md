---
id: ial2-apb-sideband-composition-back-to-back-behavior
title: APB sideband completer and fixed-composition back-to-back behavior shipped
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.615?"
  - "which APB sideband back-to-back completer samples ship?"
  - "which APB sideband fixed-composition back-to-back samples ship?"
  - "does APB sideband fixed composition propagate queued PPROT and PSTRB?"
  - "what APB sideband back-to-back timing-policy work remains deferred after .615?"
date: 2026-06-28
status: current
tags: [ial2, apb, sideband, composition, completer, back-to-back, behavior, task-tree]
evidence: docs/IAL2_APB_SIDEBAND_COMPOSITION_BACK_TO_BACK_BEHAVIOR.md; ppif/apb_completer_sideband_back_to_back.ppif; ppif/apb_completer_sideband_back_to_back.apb; ppif/apb_composition_sideband_status_back_to_back.ppif; ppif/apb_composition_sideband_status_back_to_back.apb; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md
reverify: ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition_sideband_status_back_to_back.ppif | rg '"back_to_back_policy"|"PPROT"|"PSTRB"|"apb_additional_back_to_back_policies_deferred"'; ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_completer_sideband_back_to_back.ppif | rg '"setup_admission"|"PPROT"|"PSTRB"|"apb_additional_back_to_back_policies_deferred"'
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.615` ships the bounded 32-bit
sideband-aware APB completer and fixed-composition back-to-back behavior
selected by `.614`.

The shipped public sources are:

- `ppif/apb_completer_sideband_back_to_back.ppif`
- `ppif/apb_completer_sideband_back_to_back.apb`
- `ppif/apb_composition_sideband_status_back_to_back.ppif`
- `ppif/apb_composition_sideband_status_back_to_back.apb`

The selected completer is one-register, 32-bit, sideband-aware, and accepts
`(timing-policy (setup-admission adjacent))` with `PPROT width 3` and
`PSTRB width 4`. It samples `PPROT/PSTRB` on `PSEL && !PENABLE`, applies
`PSTRB` byte enables, and does not require an inter-transfer idle cycle.

The selected fixed composition combines the `.612` sideband requester queued
`PPROT/PSTRB` capture with that adjacent sideband completer. Reports expose
aggregate `back_to_back_policy`, remove broad
`apb_back_to_back_policy_deferred` for the selected surfaces, and retain
`apb_additional_back_to_back_policies_deferred`.

Sideband multi-peripheral timing propagation, data16/protection variants,
multi-register timing policy, deeper queues, alternate overflow, accepted-less
requester surfaces, multiple active APB transfers, direct backend,
verification-output, backend-language variants, AXI, AHB, and VHDL remain
deferred after `.615`.
