---
id: ial2-apb-sideband-multi-register-back-to-back-contract-selection
title: APB sideband multi-register back-to-back contract selected
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.621?"
  - "what APB sideband multi-register back-to-back samples should .622 implement?"
  - "what is the selected APB sideband multi-register back-to-back contract?"
  - "which APB back-to-back timing variants remain deferred after .621?"
date: 2026-06-28
status: current
tags: [ial2, apb, sideband, multi-register, back-to-back, contract, task-tree]
evidence: docs/IAL2_APB_SIDEBAND_MULTI_REGISTER_BACK_TO_BACK_CONTRACT_SELECTION.md; docs/IAL2_APB_DATA16_PROTECTION_BACK_TO_BACK_READINESS_AUDIT.md; ppif/apb_completer_multi_register_sideband.ppif; ppif/apb_composition_multi_register_sideband.ppif; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.621|IAL2-FEATURE-COMPLETENESS-FRONTIER\.622|apb_completer_multi_register_sideband_back_to_back|apb_composition_multi_register_sideband_status_back_to_back|multi-peripheral multi-register timing propagation remains deferred' docs/IAL2_APB_SIDEBAND_MULTI_REGISTER_BACK_TO_BACK_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.621` selects the public contract for the
bounded APB sideband-aware multi-register back-to-back timing-policy
prerequisite.

`.622` should implement exactly four public sources:

- `ppif/apb_completer_multi_register_sideband_back_to_back.ppif`
- `ppif/apb_completer_multi_register_sideband_back_to_back.apb`
- `ppif/apb_composition_multi_register_sideband_status_back_to_back.ppif`
- `ppif/apb_composition_multi_register_sideband_status_back_to_back.apb`

The selected completer is a 32-bit sideband-aware two-register no-policy
completer with `PPROT width 3`, `PSTRB width 4`, `wait_cycles width 4`,
registers at addresses `0` and `4`, and adjacent setup admission.

The selected fixed composition combines the `.612` sideband requester
`accepted/busy/status` depth-1 queued timing policy with that selected
multi-register completer and sideband-aware fixed wiring.

Selected reports should remove broad `apb_back_to_back_policy_deferred` only
from the selected standalone completer and fixed-composition report surfaces,
while retaining narrowed future-policy residue.

Multi-peripheral multi-register timing propagation, data16/protection timing,
combined data16-protection timing, deeper queues, alternate overflow,
accepted-less requesters, multiple active APB transfers, direct backend,
verification-output, backend-language variants, AXI, AHB, and VHDL remain
deferred.
