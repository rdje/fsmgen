---
id: ial2-apb-data16-back-to-back-behavior
title: APB sideband data16 back-to-back behavior shipped
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.625?"
  - "which APB data16 back-to-back samples ship?"
  - "does APB requester back-to-back timing support data16 sidebands?"
  - "does APB adjacent setup support data16 two-register completers?"
  - "does fixed APB composition propagate data16 back-to-back timing?"
  - "what APB back-to-back variants remain deferred after .625?"
date: 2026-06-28
status: current
tags: [ial2, apb, data16, sideband, requester, completer, composition, back-to-back, behavior, task-tree]
evidence: docs/IAL2_APB_DATA16_BACK_TO_BACK_BEHAVIOR.md; ppif/apb_requester_transfer_sideband_data16_status_back_to_back.ppif; ppif/apb_requester_transfer_sideband_data16_status_back_to_back.apb; ppif/apb_completer_multi_register_sideband_data16_back_to_back.ppif; ppif/apb_completer_multi_register_sideband_data16_back_to_back.apb; ppif/apb_composition_multi_register_sideband_data16_status_back_to_back.ppif; ppif/apb_composition_multi_register_sideband_data16_status_back_to_back.apb; perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_requester_transfer_sideband_data16_status_back_to_back.ppif | rg '"data_width"|"strobe_width"|"queue_depth"|"queued"|"accepted"'; ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_completer_multi_register_sideband_data16_back_to_back.ppif | rg '"data_width"|"strobe_width"|"setup_admission"|"reg0"|"reg1"|"apb_additional_back_to_back_policies_deferred"'; ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition_multi_register_sideband_data16_status_back_to_back.ppif | rg '"back_to_back_policy"|"data_width"|"strobe_width"|"reg1"|"apb_additional_back_to_back_policies_deferred"'
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.625` ships the bounded APB
sideband-aware data16 back-to-back timing-policy family selected by `.624`.

The shipped public sources are:

- `ppif/apb_requester_transfer_sideband_data16_status_back_to_back.ppif`
- `ppif/apb_requester_transfer_sideband_data16_status_back_to_back.apb`
- `ppif/apb_completer_multi_register_sideband_data16_back_to_back.ppif`
- `ppif/apb_completer_multi_register_sideband_data16_back_to_back.apb`
- `ppif/apb_composition_multi_register_sideband_data16_status_back_to_back.ppif`
- `ppif/apb_composition_multi_register_sideband_data16_status_back_to_back.apb`

The requester is the selected `accepted/busy/status` depth-1 queued,
overflow-reject sideband family widened to 16-bit `PWDATA/PRDATA` and
2-bit `PSTRB`. It queues `queued_wdata width 16`, `queued_prot width 3`, and
`queued_wstrb width 2`, then relaunches the queued APB setup without an
inserted idle bus cycle.

The completer is the selected sideband-aware data16 two-register no-policy
family. It accepts adjacent setup admission, decodes `reg0` at byte address
`0` and `reg1` at byte address `2`, uses 16-bit register data, samples
`PPROT/PSTRB`, and applies two byte-lane write masks. `PSTRB=0` is a mapped
no-byte write, not an error.

The fixed composition combines exactly one selected data16 requester and one
selected data16 completer over 32-bit address, 16-bit data, `PPROT width 3`,
and `PSTRB width 2` wiring. Reports expose aggregate `back_to_back_policy`,
remove broad `apb_back_to_back_policy_deferred` for the six selected surfaces,
and retain narrowed future-policy, remaining-width, and protection-policy
residue.

Protection-only timing, combined data16-protection timing, multi-peripheral
multi-register timing, deeper queues, alternate overflow, accepted-less
requesters, multiple active APB transfers, direct backend, verification-output,
backend-language variants, AXI, AHB, and VHDL remain deferred after `.625`.
