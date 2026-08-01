---
id: ial2-apb-requester-status-field-behavior
title: APB requester status field ships as additive busy-plus-status variants
answers:
  - "does FSMGen support APB requester status output?"
  - "which APB status samples are shipped?"
  - "how does APB requester status lower?"
  - "what are the APB requester status codes?"
  - "what residue remains after APB requester status output?"
  - "does APB requester status change existing APB samples?"
date: 2026-06-27
status: current
tags: [ial2, apb, requester, status-field, ppif, profile-alias, task-tree]
evidence: docs/IAL2_APB_REQUESTER_STATUS_FIELD_BEHAVIOR.md; docs/IAL2_APB_REQUESTER_STATUS_FIELD_CONTRACT_SELECTION.md; ppif/apb_requester_transfer_status.ppif; ppif/apb_requester_transfer_status.apb; ppif/apb_composition_status.ppif; ppif/apb_composition_status.apb; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1470-ial2-apb-profile-alias.t; t/1472-ial2-apb-composition.t; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t; docs/REGRESSION_CORPUS.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: >-
  ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_requester_transfer_status.ppif && ./bin/fsmgen --quiet --strict --check --json ppif/apb_requester_transfer_status.ppif && ./bin/fsmgen --quiet --strict --emit-semantic-json ppif/apb_requester_transfer_status.ppif && ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_requester_transfer_status.apb && ./bin/fsmgen --quiet --strict --check --json ppif/apb_requester_transfer_status.apb && ./bin/fsmgen --quiet --strict --emit-semantic-json ppif/apb_requester_transfer_status.apb && ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition_status.ppif && ./bin/fsmgen --quiet --strict --check --json ppif/apb_composition_status.ppif && ./bin/fsmgen --quiet --strict --emit-semantic-json ppif/apb_composition_status.ppif && ./bin/fsmgen --quiet
  --emit-schedule-json ppif/apb_composition_status.apb && ./bin/fsmgen --quiet --strict --check --json ppif/apb_composition_status.apb && ./bin/fsmgen --quiet --strict --emit-semantic-json ppif/apb_composition_status.apb && prove -Iperl t/1470-ial2-apb-profile-alias.t t/1472-ial2-apb-composition.t t/248-regression-corpus-accounting.t t/297-capability-manifest.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.577` ships additive APB requester status
output support through four busy-plus-status samples:
`ppif/apb_requester_transfer_status.ppif`,
`ppif/apb_requester_transfer_status.apb`,
`ppif/apb_composition_status.ppif`, and
`ppif/apb_composition_status.apb`.

The accepted source shape adds `(status status width 2)` only in APB requester
response blocks that also contain `(busy busy)`. The selected code is
`0 idle`, `1 busy`, `2 done_ok`, and `3 done_error`.

Generated requester sources expose public `busy` and `status[1:0]`. They drive
`status = 1` during setup/access, clear `status = 0` in idle, and publish
done status with `(concat 1'b1 slverr)` after sampling `PSLVERR`.

Status-capable requester-transfer and fixed-composition reports remove both
`apb_requester_status_field_deferred` and
`apb_requester_busy_status_deferred`. Existing no-busy APB samples keep
`apb_requester_busy_status_deferred`; existing busy-only APB samples keep
`apb_requester_status_field_deferred`.
