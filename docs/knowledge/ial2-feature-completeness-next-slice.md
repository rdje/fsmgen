---
id: ial2-feature-completeness-next-slice
title: IAL2 feature completeness next slice is post-dynamic-read-RLAST selection
answers:
  - "what is the next IAL2 feature completeness slice?"
  - "what is the next IAL2 PNT task?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.211?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.212?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.213?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.214?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.215?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.216?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.217?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.218?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.219?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.220?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.221?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.222?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.223?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.224?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.225?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.226?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.227?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.228?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.229?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.230?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.231?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.232?"
  - "what is the next AXI manager slice?"
  - "what is the next AXI manager task after counted capacity substrate?"
  - "what is the next AXI manager task after counted admitted guard alignment?"
  - "what is the next AXI manager task after counted group-local enqueue?"
date: 2026-06-22
status: current
tags: [ial2, axi, manager, same-id, concrete-id, ordering, feature-completeness, task-tree]
evidence: docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/tasks/DOCTRINE-ENFORCEMENT-ADOPTION.md; docs/TASK_TREE.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_TRANSACTION_ID_CAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_TRANSACTION_ID_CAPTURE_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_TRANSACTION_ID_CAPTURE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_ID_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_TRANSACTION_ID_CAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_TRANSACTION_ID_CAPTURE_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_TRANSACTION_ID_CAPTURE_MATCHING_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_DYNAMIC_WRITE_ID_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_WRITE_TRANSACTION_ID_CAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_WRITE_TRANSACTION_ID_CAPTURE_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_TRANSACTION_ID_CAPTURE_MATCHING_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_DYNAMIC_TRANSACTION_ID_METADATA_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_TRANSACTION_ID_METADATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_TRANSACTION_ID_METADATA_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_DYNAMIC_TRANSACTION_ID_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_COUNTED_GROUP_LOCAL_ENQUEUE_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_COUNTED_ADMITTED_REQUEST_GUARD_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_COUNTED_ADMITTED_REQUEST_GUARD_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_COUNTED_CAPACITY_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_COUNTED_SAME_ID_CAPACITY_SUBSTRATE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_COUNTED_ADMISSION_CAPACITY_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_GROUP_LOCAL_SAME_ID_ENQUEUE_READINESS_AUDIT.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md; docs/knowledge/ial2-dynamic-read-rlast-transaction-id-capture-behavior.md; docs/knowledge/ial2-dynamic-read-rlast-transaction-id-capture-contract-selection.md; docs/knowledge/ial2-dynamic-read-rlast-transaction-id-capture-readiness-audit.md; docs/knowledge/ial2-post-dynamic-read-id-next-slice-selection.md; docs/knowledge/ial2-dynamic-read-transaction-id-capture-behavior.md; docs/knowledge/ial2-dynamic-read-transaction-id-capture-contract-selection.md; docs/knowledge/ial2-dynamic-read-transaction-id-capture-matching-readiness-audit.md; docs/knowledge/ial2-post-dynamic-write-id-next-slice-selection.md; docs/knowledge/ial2-dynamic-write-transaction-id-capture-behavior.md; docs/knowledge/ial2-dynamic-write-transaction-id-capture-contract-selection.md; docs/knowledge/ial2-dynamic-transaction-id-capture-matching-readiness-audit.md; docs/knowledge/ial2-post-dynamic-transaction-id-metadata-next-slice-selection.md; docs/knowledge/ial2-dynamic-transaction-id-metadata-behavior.md; docs/knowledge/ial2-dynamic-transaction-id-metadata-readiness-audit.md; docs/knowledge/ial2-dynamic-transaction-id-contract-selection.md; docs/knowledge/ial2-dynamic-same-id-issue-order-readiness-audit.md; docs/knowledge/ial2-post-counted-group-local-enqueue-next-slice-selection.md; docs/knowledge/ial2-counted-admitted-request-guard-behavior.md; docs/knowledge/ial2-counted-same-id-capacity-substrate.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.231|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.232|DYNAMIC_READ_RLAST_TRANSACTION_ID_CAPTURE_BEHAVIOR|bounded_dynamic_read_rid_rlast_demux_contract|matched_dynamic_id_and_last_signal' docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_TRANSACTION_ID_CAPTURE_BEHAVIOR.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

The next active IAL2 project slice is
`IAL2-FEATURE-COMPLETENESS-FRONTIER.232`, selector for the next exact IAL2
feature-completeness owner after bounded dynamic read burst-last/`RLAST`
transaction-ID capture and response matching shipped in `.231`.

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

`IAL2-FEATURE-COMPLETENESS-FRONTIER.215` selected `.216`. The selector found
no immediate stale support-accounting or report cleanup blocker after `.214`.
Representative generated queue-head reports expose
`counted_request_set_capacity_fit` and
`request_assertion_scope: concrete_id_group`, while the remaining local
ordering residue is `per_id_issue_order_queues` and the broader unsupported
residue is dynamic arbitration beyond selected counted concrete-ID queue-head
groups. `.216` must stay audit-only unless it first selects a later dynamic
per-ID queue/scoreboard implementation or prerequisite owner.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.216` selected `.217`. The audit found no
cleanup or lower-layer prerequisite. Bounded concrete queue-head behavior is
generated over static concrete ID values and finite transaction inventory, but
PPIF transactions currently accept only `auto` or concrete `(value N)` IDs.
Generalized dynamic/user-ID arbitration therefore needs public contract
selection before parser, queue, or scoreboard behavior.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.217` selected transaction-local
`(id dynamic)` and `.218`. The selected dynamic ID source is the family
request-ID signal declared in `id-families` at the transaction's admitted
request point. Dynamic ID capture, response matching, same-ID policy, queues,
scoreboards, support accounting, generated artifacts, validation, tests, and
HDL remain deferred until later owners.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.218` selected `.219`, direct
metadata-first `(id dynamic)` parser/report implementation. `.219` must accept
exactly transaction-local `(id dynamic)`, require a positive-width
`id-families` request/response signal contract, report user-supplied
selected-not-generated dynamic metadata, add a support-accounted metadata-only
sample, and fail closed for same-family behavior clauses that would need
dynamic capture, response matching, queues, scoreboards, read-data routing, or
HDL behavior.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.219` shipped that parser/report metadata
boundary and support-accounted sample, then advanced the frontier to `.220`.
`IAL2-FEATURE-COMPLETENESS-FRONTIER.220` selected `.221`, readiness audit for
generated dynamic transaction-ID capture and response matching. Dynamic ID
capture, response matching, same-ID ordering, read-data routing, queues,
scoreboards, direct backend behavior, HDL behavior, and VHDL remain deferred.
`IAL2-FEATURE-COMPLETENESS-FRONTIER.221` selected `.222`, public contract
selection for bounded dynamic write transaction-ID capture and `BID` response
matching. `.222` must settle admitted-request capture timing, single-active
dynamic ownership, stored-ID/busy lifetime, matched-response
completion/release semantics, assertions/diagnostics, report vocabulary,
validation, rollback, and explicit residue before any parser, generator,
sample, support-accounting, validation, generated-artifact, test, or HDL
behavior changes.
`IAL2-FEATURE-COMPLETENESS-FRONTIER.222` selected `.223`, direct generated
bounded dynamic write transaction-ID capture and `BID` response matching.
The public contract reuses existing `response-demux.write` with one
transaction-local dynamic write ID, rejects a new dynamic-ID lifecycle clause,
and requires admitted-request capture, single-active selected-ID/busy storage,
matched `BID` completion, busy release, dynamic write demux reports, and
explicit residue preservation.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.223` shipped that behavior with
`ppif/axi_manager_capacity_status_dynamic_write_response_demux.ppif`. The
generated path captures `AWID` on admitted dynamic write requests, stores
generated selected-ID/busy state, matches `BID` against the captured ID,
pulses the transaction completion, releases busy, reports
`bounded_dynamic_write_bid_demux_contract`, and marks the covered transaction
ID `generated_capture_matching`.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.224` selected `.225`, readiness audit for
generated dynamic read transaction-ID capture and `RID` response matching.
Read response scope, `RLAST`, read-data consumption, burst/runtime validation,
interleaving, assertions, and report vocabulary need audit before behavior
changes.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.225` selected `.226`, public contract
selection for bounded single-beat dynamic read transaction-ID capture and
`RID` response matching. The audit found no cleanup or lower-layer prerequisite
but kept dynamic read burst-last/`RLAST`, read-data routing,
burst-length/runtime validation, interleaving, multiple dynamic reads, mixed
dynamic/static read demux, same-cycle recapture, same-ID ordering, queues,
scoreboards, direct backend behavior, HDL shapes outside the selected
SystemVerilog path, and VHDL deferred.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.226` selected `.227`, direct generated
behavior for bounded single-beat dynamic read transaction-ID capture and
`RID` response matching. The selected public contract reuses existing
`response-demux.read` with one transaction-local dynamic read ID,
`response-scope single-beat`, no `last_signal`, admitted read request-ID
capture, single-active selected-ID/busy ownership, raw accepted read response
plus `RID == captured_id` completion, generated busy release, read-specific
dynamic assertions, and `bounded_dynamic_read_rid_demux_contract` report
vocabulary.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.227` shipped that generated bounded
single-beat dynamic read behavior and advanced the frontier to `.228`, the next
exact-owner selector after bounded single-active dynamic read/write demux.
`IAL2-FEATURE-COMPLETENESS-FRONTIER.228` selected `.229`, readiness audit for
dynamic read burst-last/`RLAST` transaction-ID capture and response matching.
`IAL2-FEATURE-COMPLETENESS-FRONTIER.229` selected `.230`, public contract
selection for bounded dynamic read burst-last/`RLAST` transaction-ID capture
and response matching. The audit found no lower-layer prerequisite or stale
report/static cleanup blocker, but direct behavior still needs public contract
ownership for syntax, last-signal ownership, non-last beat lifetime,
completion/release semantics, assertions, report vocabulary, read-data and
burst/runtime interaction, generated artifact boundaries, validation, rollback,
and residue.
`IAL2-FEATURE-COMPLETENESS-FRONTIER.230` selected `.231`, direct generated
behavior for bounded dynamic read burst-last/`RLAST` transaction-ID capture and
response matching. The selected public contract reuses existing
`response-demux.read` with one dynamic read transaction, `response-scope
burst-last`, one-bit `last-signal`, admitted `ARID` capture, single-active
selected-ID/busy state across non-last beats, and generated completion only on
matched `RID` plus asserted `RLAST`.
`IAL2-FEATURE-COMPLETENESS-FRONTIER.231` shipped that generated behavior with
`ppif/axi_manager_capacity_status_dynamic_read_response_demux_burst_last.ppif`
and advanced the frontier to `.232`, selector for the next exact IAL2 owner.

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
