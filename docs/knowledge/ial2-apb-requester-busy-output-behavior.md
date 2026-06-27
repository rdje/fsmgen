---
id: ial2-apb-requester-busy-output-behavior
title: APB requester busy output ships as additive PPIF and APB variants
answers:
  - "does FSMGen support APB requester busy output?"
  - "which APB busy samples are shipped?"
  - "how does APB requester busy lower?"
  - "does APB busy change existing APB samples?"
  - "what residue remains after APB busy output?"
date: 2026-06-27
status: current
tags: [ial2, apb, requester, busy, ppif, profile-alias, task-tree]
evidence: docs/IAL2_APB_REQUESTER_BUSY_OUTPUT_BEHAVIOR.md; docs/IAL2_APB_REQUESTER_BUSY_STATUS_CONTRACT_SELECTION.md; ppif/apb_requester_transfer_busy.ppif; ppif/apb_requester_transfer_busy.apb; ppif/apb_composition_busy.ppif; ppif/apb_composition_busy.apb; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1470-ial2-apb-profile-alias.t; t/1472-ial2-apb-composition.t; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_requester_transfer_busy.ppif && ./bin/fsmgen --quiet --strict --check --json ppif/apb_requester_transfer_busy.ppif && ./bin/fsmgen --quiet --strict --emit-semantic-json ppif/apb_requester_transfer_busy.ppif && ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition_busy.ppif && ./bin/fsmgen --quiet --strict --check --json ppif/apb_composition_busy.ppif && ./bin/fsmgen --quiet --strict --emit-semantic-json ppif/apb_composition_busy.ppif && prove -Iperl t/1470-ial2-apb-profile-alias.t t/1472-ial2-apb-composition.t t/248-regression-corpus-accounting.t t/297-capability-manifest.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.572` ships additive APB requester `busy`
output support through four busy-capable samples:
`ppif/apb_requester_transfer_busy.ppif`,
`ppif/apb_requester_transfer_busy.apb`,
`ppif/apb_composition_busy.ppif`, and
`ppif/apb_composition_busy.apb`.

The source syntax adds optional `(busy busy)` inside the APB requester
`(response ...)` block. Busy-capable requester-transfer sources generate
`apb_requester.isf`, `apb_requester.fsm`, and HDL module `apb_requester` with
public `busy`. Busy-capable composition sources also propagate `busy` to the
generated `apb_tb` top.

Existing APB requester-transfer and fixed-composition samples remain
unchanged and keep `apb_requester_busy_status_deferred`. Busy-capable reports
remove that residue and keep `apb_requester_status_field_deferred`, because
named status fields remain future work.
