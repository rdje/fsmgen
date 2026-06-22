---
id: ial2-feature-completeness-next-slice
title: IAL2 feature completeness next slice is post counted group-local same-ID enqueue selection
answers:
  - "what is the next IAL2 feature completeness slice?"
  - "what is the next IAL2 PNT task?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.211?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.212?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.213?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.214?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.215?"
  - "what is the next AXI manager slice?"
  - "what is the next AXI manager task after counted capacity substrate?"
  - "what is the next AXI manager task after counted admitted guard alignment?"
date: 2026-06-22
status: current
tags: [ial2, axi, manager, same-id, concrete-id, ordering, feature-completeness, task-tree]
evidence: docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/AXI_IAL2_MANAGER_COUNTED_ADMITTED_REQUEST_GUARD_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_COUNTED_ADMITTED_REQUEST_GUARD_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_COUNTED_CAPACITY_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_COUNTED_SAME_ID_CAPACITY_SUBSTRATE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_COUNTED_ADMISSION_CAPACITY_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_GROUP_LOCAL_SAME_ID_ENQUEUE_READINESS_AUDIT.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md; docs/knowledge/ial2-counted-admitted-request-guard-behavior.md; docs/knowledge/ial2-counted-same-id-capacity-substrate.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.214|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.215|COUNTED_ADMITTED_REQUEST_GUARD_BEHAVIOR|counted_request_set_capacity_fit|request_set_fit_expression|request_assertion_scope|concrete_id_group|group-local request assertions' docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/AXI_IAL2_MANAGER_COUNTED_ADMITTED_REQUEST_GUARD_BEHAVIOR.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

The next IAL2 feature-completeness slice is
`IAL2-FEATURE-COMPLETENESS-FRONTIER.215`, the selector for the next
roadmap-aligned AXI manager slice after counted admitted-request guard
alignment and group-local request assertions shipped.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.211` shipped counted selected-request
capacity/status substrate for generated same-ID queue-head families with
multiple concrete-ID groups. The substrate reports
`counted_same_id_selected_requests`, counted request groups,
`request_count_expression`, `maximum_request_count`, `counted_submit` capacity
matrices, Boolean completion accounting, and
`over_capacity_policy: reject_current_request_set`, while preserving the
family-wide request onehot assertion.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.212` selected `.213`. The selector found
that counted capacity/status can reject over-capacity current request sets,
but admitted-request pulses still use scalar pending storage plus Boolean
completion fan-in. Directly narrowing the family-wide request onehot to
group-local assertions could therefore enqueue requests that the capacity
matrix rejects. Queue transitions are already per concrete-ID group, so the
next owner is the admitted-pulse guard/alignment audit, not a direct behavior
implementation.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.213` selected `.214`. The audit found the
IAL1 expression substrate already supports the needed arithmetic and
comparison guard expressions, so the implementation could stay local to the AXI
IAL2 generator.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.214` shipped that implementation. Counted
generated multi-group queue-head families now derive a
`request_set_fit_expression` from the counted capacity/status occupancy,
completion, request-count, and max-pending cases; gate each counted
admitted-request pulse with that expression; report
`guard_source: counted_request_set_capacity_fit` and
`request_assertion_scope: concrete_id_group`; and replace the counted
family-wide same-ID request onehot with per concrete-ID group assertions.
Non-counted directions and mixed auto-ID single concrete-group directions keep
Boolean admission and family-wide request assertions.

Historical notes from earlier queue-head frontier selection follow.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.106` shipped the first generated
same-ID queue behavior boundary for the public read burst-last depth-2 sample.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.108` shipped generated AXI same-ID write
queue-head behavior for one duplicate concrete write-ID group of two
transactions at computed depth 2. The generated match is write response event
plus concrete `BID` plus the compact one-hot queue head transaction bit, and
the existing auto-ID write demux path remains separate.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.109` selected `.110`, and `.110` has now
shipped generated AXI read `single-beat` same-ID queue-head behavior for one
duplicate concrete read-ID group of two transactions at computed depth 2. The
generated match is raw read response event plus concrete `RID` plus the
compact one-hot queue head transaction bit, without `RLAST`.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.111` selected queue-head read-data
readiness as `.112`. `IAL2-FEATURE-COMPLETENESS-FRONTIER.112` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.113`, generated single-beat read-data
capture for bounded read single-beat concrete same-ID queue-head demux.
`IAL2-FEATURE-COMPLETENESS-FRONTIER.113` shipped that behavior for
`ppif/axi_manager_capacity_status_read_single_beat_same_id_queue_head_read_data.ppif`
and advanced the frontier to `IAL2-FEATURE-COMPLETENESS-FRONTIER.114`.
`IAL2-FEATURE-COMPLETENESS-FRONTIER.114` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.115`, generated last-beat read-data
capture for the bounded read burst-last concrete same-ID queue-head demux
shape. `IAL2-FEATURE-COMPLETENESS-FRONTIER.115` shipped that behavior for
`ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_read_data.ppif`
and advanced the frontier to `IAL2-FEATURE-COMPLETENESS-FRONTIER.116`, the
selector for the next queue-head/read-data expansion.
`IAL2-FEATURE-COMPLETENESS-FRONTIER.116` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.117`, generated raw-`ARLEN`
burst-length capture for the bounded queue-head last-beat read-data shape.
`IAL2-FEATURE-COMPLETENESS-FRONTIER.117` shipped that report-only behavior for
`ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_burst_length.ppif`
and advanced the frontier to `IAL2-FEATURE-COMPLETENESS-FRONTIER.118`.
`IAL2-FEATURE-COMPLETENESS-FRONTIER.118` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.119`, generated queue-head
beat-count/`RLAST` runtime validation for the same bounded queue-head
last-beat read-data shape. `IAL2-FEATURE-COMPLETENESS-FRONTIER.119` shipped
that behavior for
`ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_burst_length_runtime_assertion.ppif`
and advanced the frontier to `IAL2-FEATURE-COMPLETENESS-FRONTIER.120`, the
next queue-head/read-data expansion selector. `IAL2-FEATURE-COMPLETENESS-FRONTIER.120`
selected `IAL2-FEATURE-COMPLETENESS-FRONTIER.121`, and `.121` shipped
generated multi-beat read-data output-bank behavior for the bounded read
burst-last concrete same-ID queue-head demux shape.

The already-covered public samples now report generated response demux,
generated same-ID ordering, `accepted_same_id_reuse: true`, and
`generated_queue_behavior: true` only for the bounded read burst-last, write,
and read single-beat depth-2 two-transaction shapes. Generated queue-head
read-data capture is now supported for the bounded read single-beat queue-head
shape and the bounded read burst-last queue-head last-beat shape. The
single-beat path reports `generated_queue_head_response_demux_completion_pulse`;
the last-beat path reports
`generated_queue_head_response_demux_last_beat_completion_pulse`. Existing
auto-ID read-data capture keeps its auto-ID completion-validity values.
The queue-head multi-beat path now reports `per_beat_output_bank`,
per-transaction valid masks and length outputs, scalar `RRESP` aggregation,
`read_data.residue: []`, and `response_demux.residue: []` for the bounded
sample. `IAL2-FEATURE-COMPLETENESS-FRONTIER.122` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.123`, readiness audit for multiple
independent read burst-last depth-2 concrete same-ID queue-head response-demux
groups. `IAL2-FEATURE-COMPLETENESS-FRONTIER.123` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.124`, generated read burst-last
response-demux-only queue-head behavior for two or more duplicate concrete
read-ID groups, each exactly two transactions at computed depth `2`. `.124`
must preserve the existing family-wide admitted-request onehot boundary and
must not claim read-data over multiple groups, same-family auto-ID, deeper
queues, write-family or single-beat multi-group behavior, packed outputs,
direct backend, or VHDL.

The IAL2 factoring stance remains that common constructs should be promoted
only after compatible reuse is proven across multiple profiles.
