---
id: ial2-apb-completer-interconnect-readiness-audit
title: APB completer/interconnect is ready for contract selection, not implementation
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.558 select?"
  - "is APB completer/interconnect generation ready for implementation?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.559?"
  - "what blocks direct APB completer generation?"
  - "does APB completer/interconnect have lower-layer evidence?"
date: 2026-06-26
status: current
tags: [ial2, apb, ppif, profile-alias, task-tree]
evidence: docs/IAL2_APB_COMPLETER_INTERCONNECT_READINESS_AUDIT.md; docs/IAL2_POST_APB_SURFACE_SYNC_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_APB_PPIF_REQUESTER_TRANSFER_BEHAVIOR.md; docs/IAL2_APB_PPIF_SOURCE_SHAPE_CONTRACT_SELECTION.md; fsm/apb_completer.fsm; fsm/apb_tb.fsm; ppif/apb_requester_transfer.apb; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: ./bin/fsmgen --quiet --strict --check --json fsm/apb_completer.fsm && ./bin/fsmgen --quiet --strict --check --json fsm/apb_tb.fsm && ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_requester_transfer.apb && ./bin/fsmgen --quiet --strict --check --json ppif/apb_requester_transfer.apb
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.558` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.559`, APB completer/interconnect public
contract selection.

The audit finds APB completer/interconnect ready for contract selection, not
direct implementation. Lower-layer evidence exists in `fsm/apb_completer.fsm`
and `fsm/apb_tb.fsm`, and current APB IAL2 requester-transfer behavior keeps
the `apb_completer_and_interconnect_generation_deferred` residue explicit.

Direct implementation is blocked until a public owner selects the APB
completer/interconnect vocabulary, whether completer and interconnect are
split or combined, the mandatory generated `.isf` before generated `.fsm`
artifact path, report/support-accounting identities, diagnostics, and `.ppif`
versus `.apb` exposure.
