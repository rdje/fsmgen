---
id: ial2-apb-sideband-multi-register-back-to-back-behavior
title: APB sideband multi-register back-to-back behavior shipped
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.622?"
  - "which APB sideband multi-register back-to-back samples ship?"
  - "does APB sideband multi-register completer support adjacent setup?"
  - "does fixed APB composition propagate sideband multi-register back-to-back timing?"
  - "what APB back-to-back timing variants remain deferred after .622?"
date: 2026-06-28
status: current
tags: [ial2, apb, sideband, multi-register, composition, completer, back-to-back, behavior, task-tree]
evidence: docs/IAL2_APB_SIDEBAND_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md; ppif/apb_completer_multi_register_sideband_back_to_back.ppif; ppif/apb_completer_multi_register_sideband_back_to_back.apb; ppif/apb_composition_multi_register_sideband_status_back_to_back.ppif; ppif/apb_composition_multi_register_sideband_status_back_to_back.apb; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_completer_multi_register_sideband_back_to_back.ppif | rg '"setup_admission"|"reg0"|"reg1"|"PPROT"|"PSTRB"|"apb_additional_back_to_back_policies_deferred"'; ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition_multi_register_sideband_status_back_to_back.ppif | rg '"back_to_back_policy"|"setup_admission"|"queue_depth"|"reg0"|"reg1"|"apb_additional_back_to_back_policies_deferred"'
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.622` ships the bounded APB sideband-aware
multi-register back-to-back timing-policy prerequisite selected by `.621`.

The shipped public sources are:

- `ppif/apb_completer_multi_register_sideband_back_to_back.ppif`
- `ppif/apb_completer_multi_register_sideband_back_to_back.apb`
- `ppif/apb_composition_multi_register_sideband_status_back_to_back.ppif`
- `ppif/apb_composition_multi_register_sideband_status_back_to_back.apb`

The selected completer is 32-bit, sideband-aware, no-policy, and has exactly
two registers: `reg0` at address `0` and `reg1` at address `4`. It accepts
`(timing-policy (setup-admission adjacent))`, samples `PPROT/PSTRB` on
`PSEL && !PENABLE`, applies `PSTRB` byte enables to the selected decoded
register, and does not require an inter-transfer idle cycle.

The selected fixed composition combines the `.612` sideband requester
`accepted/busy/status` depth-1 queued timing policy with that two-register
completer and sideband-aware fixed wiring. Reports expose aggregate
`back_to_back_policy`, remove broad `apb_back_to_back_policy_deferred` for the
selected surfaces, and retain narrowed
`apb_additional_back_to_back_policies_deferred`.

Multi-peripheral multi-register timing propagation, data16/protection timing,
combined data16-protection timing, deeper queues, alternate overflow,
accepted-less requesters, multiple active APB transfers, direct backend,
verification-output, backend-language variants, AXI, AHB, and VHDL remain
deferred after `.622`.
