---
id: ial2-axi-manager-post-multi-group-queue-head-read-data-next-slice-selection
title: IAL2 post multi-group queue-head read-data selector chooses last-beat audit
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.128 select?"
  - "what is the next slice after multi-group queue-head read-data?"
  - "why is last-beat-only multi-group read-data an audit first?"
  - "does the .128 selector change generator behavior?"
date: 2026-06-15
status: current
tags: [ial2, axi, manager, queue-head, read-data, same-id, selector, task-tree]
evidence: docs/AXI_IAL2_MANAGER_POST_MULTI_GROUP_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1436-ial2-ppif-parser-cli.t
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.128|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.129|last-beat-only read-data over multiple generated read burst-last concrete same-ID queue-head groups|last-beat-only multi-group read-data|_read_data_response_demux_transaction_coverage|AXI_IAL2_MANAGER_POST_MULTI_GROUP_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION' docs/AXI_IAL2_MANAGER_POST_MULTI_GROUP_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.128` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.129`, readiness audit for
last-beat-only read-data over multiple generated read burst-last concrete
same-ID queue-head groups.

The `.128` selector is documentation-only. It changes no parser, generator,
PPIF sample, support-accounting, test, generated artifact, or HDL behavior.

The next audit is needed because
`_read_data_response_demux_transaction_coverage` currently permits multiple
generated queue-head groups only for `capture_scope multi-beat`; `last-beat`
still requires exactly one depth-2 read queue group. Broadening that guard
without more precise gating could also admit report-only raw-`ARLEN` and
runtime-validation-only multi-group variants, so `.129` must choose the exact
implementation boundary before behavior changes.

The candidate behavior is read-family only, generated
`response-demux.read` boundary `generated_read_burst_last_queue_head_demux`,
two or more depth-2 duplicate concrete read-ID groups, and scalar
`capture_scope last-beat` with per-transaction `data_output` and
`status_output` bindings for every covered transaction.

Report-only/runtime-only variants, deeper queues, same-family mixed auto-ID,
write/read-single-beat multi-group behavior, packed outputs, direct backend,
and VHDL remain deferred.
