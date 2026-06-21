# AXI IAL2 Manager Counted Admission Capacity Readiness Audit

Status: readiness audit for `IAL2-FEATURE-COMPLETENESS-FRONTIER.210` on
2026-06-21.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.210`

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.211`, the bounded implementation
owner for counted same-ID request capacity substrate while preserving the
current family-wide same-ID request onehot assertion.

Counted same-direction admission belongs in the shared capacity/status matrix,
not in a detached same-ID-only overlay. The public `pending_reads`,
`pending_writes`, `*_slots_available`, `*_full`, and `*_can_accept` outputs are
owned by `_direction_rules`; any admission layer that accepts more than one
same-direction request without updating that matrix would create inconsistent
public status.

This audit changes no parser, generator, PPIF sample, support-accounting
catalog, validation, generated artifact, test, or HDL behavior.

## Evidence Read

The audit read:

- `.209` group-local enqueue readiness audit and the admitted request pulse
  behavior note.
- Capacity/status rule matrix code: `_direction_rules`, `_rule_lines`,
  `_event_guards`, `_next_pending`, and `_can_accept`.
- Transaction-event dispatch, admitted-boundary, queue-head transition,
  response-state, report, support-accounting, and focused generator/PPIF test
  surfaces.
- IAL1 expression and lowering support for runtime list expressions and
  arithmetic expressions.
- Public PPIF samples for read/write multi-group queue-head response-demux and
  policy-only same-ID issue-order-queue coverage.
- README, `ROADMAP_V2.md`, mdBook, downstream integration spec, public
  contract, task tree, Memory, and Knowledge Map.

## Live Probe Findings

Representative public samples and temporary `/tmp` low-capacity mutations all
preserve the same current shape:

```text
ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_response_demux.ppif
  read max=4 storage=axi0_pending_reads_q
  read request_fanin=(| axi0_r0_request axi0_r1_request axi0_r2_request axi0_r3_request)
  read selected=axi0_r0_request,axi0_r1_request,axi0_r2_request,axi0_r3_request
  read admitted_assertions=axi0_read_issue_order_queue_request_onehot0
  read_matrix rule_count=20

ppif/axi_manager_capacity_status_write_multi_group_same_id_queue_head_response_demux.ppif
  write max=4 storage=axi0_pending_writes_q
  write request_fanin=(| axi0_w0_request axi0_w1_request axi0_w2_request axi0_w3_request)
  write selected=axi0_w0_request,axi0_w1_request,axi0_w2_request,axi0_w3_request
  write admitted_assertions=axi0_write_issue_order_queue_request_onehot0
  write_matrix rule_count=20

/tmp/ial2-counted-read-cap3.ppif
  read max=3 storage=axi0_pending_reads_q
  read request_fanin=(| axi0_r0_request axi0_r1_request axi0_r2_request axi0_r3_request)
  read selected=axi0_r0_request,axi0_r1_request,axi0_r2_request,axi0_r3_request
  read admitted_assertions=axi0_read_issue_order_queue_request_onehot0
  read_matrix rule_count=16

/tmp/ial2-counted-write-cap3.ppif
  write max=3 storage=axi0_pending_writes_q
  write request_fanin=(| axi0_w0_request axi0_w1_request axi0_w2_request axi0_w3_request)
  write selected=axi0_w0_request,axi0_w1_request,axi0_w2_request,axi0_w3_request
  write admitted_assertions=axi0_write_issue_order_queue_request_onehot0
  write_matrix rule_count=16
```

Generated IAL1 for the low-capacity read mutation shows why a direct
group-local onehot replacement is unsafe without counted capacity first:

```lisp
(rule axi0_r0_admitted_request
  (& axi0_r0_request
     (| (< axi0_pending_reads_q 3)
        (| axi0_r0_complete axi0_r1_complete axi0_r2_complete axi0_r3_complete)))
  (pulse axi0_r0_admitted_request_pulse_q))

(rule axi0_r2_admitted_request
  (& axi0_r2_request
     (| (< axi0_pending_reads_q 3)
        (| axi0_r0_complete axi0_r1_complete axi0_r2_complete axi0_r3_complete)))
  (pulse axi0_r2_admitted_request_pulse_q))

(rule read_submit_only_occ2
  (& (| axi0_r0_request axi0_r1_request axi0_r2_request axi0_r3_request)
     (! (| axi0_r0_complete axi0_r1_complete axi0_r2_complete axi0_r3_complete))
     (== axi0_pending_reads_q 2))
  (axi0_pending_reads_q 3)
  (axi0_pending_reads 3)
  (axi0_read_slots_available 0)
  (axi0_read_full 1)
  (axi0_read_can_accept 1))
```

At occupancy 2 with max-pending 3, two distinct concrete-ID group requests
would both satisfy the admitted-pulse guard if the family-wide onehot were
narrowed, but the direction counter would record only one submit.

Generated IAL1 for the low-capacity write mutation shows the same issue on the
write side:

```lisp
(rule axi0_w0_admitted_request
  (& axi0_w0_request
     (| (< axi0_pending_writes_q 3)
        (| axi0_w0_complete axi0_w1_complete axi0_w2_complete axi0_w3_complete)))
  (pulse axi0_w0_admitted_request_pulse_q))

(rule axi0_w2_admitted_request
  (& axi0_w2_request
     (| (< axi0_pending_writes_q 3)
        (| axi0_w0_complete axi0_w1_complete axi0_w2_complete axi0_w3_complete)))
  (pulse axi0_w2_admitted_request_pulse_q))

(rule write_submit_only_occ2
  (& (| axi0_w0_request axi0_w1_request axi0_w2_request axi0_w3_request)
     (! (| axi0_w0_complete axi0_w1_complete axi0_w2_complete axi0_w3_complete))
     (== axi0_pending_writes_q 2))
  (axi0_pending_writes_q 3)
  (axi0_pending_writes 3)
  (axi0_write_slots_available 0)
  (axi0_write_full 1)
  (axi0_write_can_accept 1))
```

Schedule reports for the low-capacity mutations had zero `compile_issues`,
zero `priority_resolutions`, zero `resource_arbitration` entries, and zero
`verification_observations`; the scheduler has no hidden counted-capacity
model that would repair this later.

## Implementation Placement

The next implementation should extend the shared direction capacity/status
matrix with an additive counted-submit path for selected generated same-ID
queue-head families. The path should remain inactive for ordinary Boolean
direction fan-in shapes.

A same-ID-only admission layer was rejected because it would either duplicate
the direction pending/status outputs or accept request pulses that the public
capacity matrix cannot count. A smaller report-only prerequisite was also
rejected: the needed substrate can be implemented directly while preserving
the family-wide request onehot, so legal public-sample behavior remains the
same and future group-local onehot narrowing has a real capacity model to
reuse.

The counted matrix should initially preserve the existing family-wide
`*_issue_order_queue_request_onehot0` assertion. Under legal inputs this keeps
the externally supported behavior one-request-per-direction-per-cycle, while
the generated substrate and report metadata become ready for a later
group-local assertion slice.

## Required Report Fields

The `.211` implementation should add these machine-readable fields without
removing existing fields:

- `transaction_event_dispatch.directions[].request_accounting.mode`:
  `boolean_fanin` for the existing path or `counted_same_id_selected_requests`
  for a selected generated same-ID queue-head family.
- `transaction_event_dispatch.directions[].request_accounting.counted_request_events`:
  the concrete request events counted for the direction.
- `transaction_event_dispatch.directions[].request_accounting.request_count_expression`:
  the IAL1 expression that sums the selected request events.
- `transaction_event_dispatch.directions[].request_accounting.maximum_request_count`:
  the number of selected counted request events.
- `transaction_event_dispatch.directions[].request_accounting.capacity_owner`:
  `generated_scheduler_or_status_rules.<read|write>_capacity_matrix`.
- `generated_scheduler_or_status_rules[].accounting_mode`:
  `boolean_submit` or `counted_submit`.
- `generated_scheduler_or_status_rules[].counted_request_events`,
  `request_count_expression`, `maximum_request_count`,
  `over_capacity_policy`, and `completion_accounting_mode`.
- `same_id_ordering.concrete_id_reuse_policy.<family>.admitted_request_boundary.accounting_mode`:
  `capacity_storage_and_completion_fanin` for current Boolean behavior or
  `counted_capacity_storage_and_completion_fanin` once the counted substrate
  owns the selected family.

`over_capacity_policy` should be `reject_current_request_set`: if the counted
request count exceeds free slots plus one same-cycle completion credit, no new
same-direction requests are admitted in that cycle. The completion side remains
Boolean in this substrate because current response-demux queue-head behavior
selects at most one response event per direction per cycle.

## Semantics To Preserve And Implement

The counted path should compute:

- `request_count`: sum of selected counted request events for the direction.
- `completion_count`: `1` when the existing direction completion fan-in is
  true, otherwise `0`.
- `free_slots_before_submit`: `max_pending - pending_storage`.
- `can_accept_current_request_set`: when `request_count` is zero, preserve the
  current idle/completion semantics (`pending_storage < max_pending` or a
  completion is present); otherwise require
  `request_count <= free_slots_before_submit + completion_count`.
- `accepted_request_count`: `request_count` when the current request set fits,
  otherwise `0`.
- `next_pending`: saturated non-negative
  `pending_storage - completion_count + accepted_request_count`.

The public scalar `*_can_accept` remains the status for the current cycle's
request set, not a vector of per-transaction readiness bits. `*_slots_available`
and `*_full` must derive from `next_pending`, so they stay aligned with
`pending_reads` and `pending_writes`.

Same-group simultaneous requests remain unsupported. `.211` must keep the
family-wide request onehot assertion. The later group-local enqueue slice may
replace that with per-concrete-ID group onehots only after counted status
preservation is proven.

## Validation Gates For `.211`

The implementation slice should run focused generator tests that prove:

- non-counted samples still report `boolean_fanin` and preserve generated
  capacity rule behavior;
- selected generated same-ID queue-head families report counted request
  accounting with the exact selected request events and owner fields;
- low-capacity read and write fixtures produce rules that do not count two or
  more selected request events as one submit;
- admitted-pulse guards and capacity/status outputs agree on over-capacity
  combinations;
- the existing family-wide onehot assertions remain present until the later
  group-local enqueue owner changes them.

Focused PPIF/CLI, strict check JSON, semantic JSON, mdBook, Knowledge Map,
memory architecture, and diff gates should accompany the implementation. HDL
verification is warranted for at least one read and one write counted-substrate
sample if the generated HDL text changes for public samples.

## Public Contract Impact

No public PPIF syntax change is needed. The impact is additive report metadata
and generated capacity/status internals for selected generated same-ID
queue-head families. Existing public samples remain one-request-per-cycle under
the preserved family-wide request onehot assertion.

The rollback boundary is local to the counted request-accounting metadata and
the direction capacity/status matrix generation. Parser syntax, public sample
set, response-demux behavior, read-data behavior, support identities, and
queue-state transition enumeration remain outside `.211` unless the focused
implementation owner explicitly proves they must move.
