# AXI IAL2 Manager Mixed Dynamic/Static Write Same-ID Issue-Order Queue Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.502`

Date: 2026-06-25

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.502` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.503`, direct bounded implementation of
generated mixed dynamic/static write `BID` same-ID `issue-order-queue`
behavior for exactly one dynamic write transaction and one concrete static
write transaction.

No parser, IAL1, IAL0, SystemVerilog, support-accounting, backend-language,
external converter, or VHDL prerequisite is required first. The current
fail-closed boundary is local to the AXI manager capacity/status generator's
write response-demux queue planning and report projection.

This audit changes no parser, generator, PPIF sample, support-accounting
catalog, generated artifact, report JSON, test, HDL/runtime behavior, external
converter dependency, arbitrary-cardinality queue behavior, direct backend
behavior, backend-language variant, verification-code output, or VHDL
behavior.

## Current Boundary

The public parser already accepts:

```lisp
(same-id-ordering
  (write (dynamic-id-reuse issue-order-queue)))
```

The existing one-dynamic plus one-static mixed write response-demux sample:

```text
ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux.ppif
```

ships generated `BID` matching for:

```text
w0: dynamic ID captured from axi0_awid
w1: concrete static ID 3
response ID signal: axi0_bid
write-max-pending: 2
```

That mixed demux intentionally requires no `same_id_ordering.write`, reserves
the concrete static ID away from dynamic capture, and emits static-ID
exclusion assertions. That is correct for response-demux-only mixed matching,
but it is not the desired issue-order queue semantics, because the queue must
allow the dynamic request to use the static concrete ID and preserve order
only when the two queued entries match by ID.

The existing all-dynamic write queue samples:

```text
ppif/axi_manager_capacity_status_dynamic_write_same_id_issue_order_queue.ppif
ppif/axi_manager_capacity_status_dynamic_write_depth3_same_id_issue_order_queue.ppif
```

ship compact runtime-ID issue-order slots for two or three all-dynamic write
transactions. Each occupied slot stores one transaction identity bit and one
captured `AWID`; raw `BID` response matching selects the earliest occupied
slot whose captured ID equals `axi0_bid`. This is the right queue model for
the mixed write shape, provided a static transaction enqueue stores the
concrete literal in the slot ID field instead of capturing `axi0_awid`.

## Probe Evidence

A temporary `/tmp` candidate was derived from the existing mixed write PPIF by
adding:

```lisp
(same-id-ordering
  (write (dynamic-id-reuse issue-order-queue)))
```

A RAM-guarded run failed closed before generated artifacts were emitted:

```text
AXI manager capacity/status IAL2 contract response_demux.write dynamic-id-reuse issue-order-queue requires exactly two or three all-dynamic write transactions in this slice
```

The failure occurs in `_response_demux_dynamic_write_issue_order_queue_plan`.
That planner currently recognizes `dynamic-id-reuse issue-order-queue` before
the mixed dynamic/static demux planner, then requires all selected write
transactions to be dynamic and the dynamic count to be exactly two or three.
Because the candidate has one dynamic and one concrete static write
transaction, it fails closed there.

The older generic dynamic matching path also remains intentionally closed:
`_response_demux_dynamic_write_transaction` rejects
`same_id_ordering.write` unless the selected dynamic policy is reject. The
mixed dynamic/static helper underneath it can build the response-demux-only
state, but that state uses `static_concrete_ids_reserved` and static-ID
exclusion instead of queue-owned accepted same-ID reuse.

## Implementation Readiness

Direct implementation is ready as a narrow local generator slice:

- add a mixed dynamic/static write issue-order queue plan for exactly one
  dynamic write transaction plus one concrete static write transaction;
- require `write-max-pending >= 2`, write ID-family metadata, explicit
  `response-demux.write`, and `same-id-ordering.write
  (dynamic-id-reuse issue-order-queue)`;
- reject `write auto_id_lifecycle` for this shape, as the all-dynamic write
  queue does;
- reuse the compact runtime-ID slot representation, with transaction identity
  bits plus one slot ID register;
- enqueue the dynamic transaction with slot ID assigned from `axi0_awid`;
- enqueue the static transaction with slot ID assigned from the concrete
  sized literal such as `4'd3`;
- match `axi0_bid` against the earliest occupied slot's stored ID, preserving
  same-ID order and allowing different IDs to complete out of global order;
- preserve the first slice's onehot0 enqueue policy across the dynamic and
  static request events;
- keep same-cycle selected dequeue plus one enqueue semantics aligned with
  the existing dynamic queue transition generator;
- report accepted same-ID reuse through generated queue behavior, not through
  static-ID exclusion reject mapping; and
- keep generated behavior bounded to the exact one-dynamic plus one-static
  write `BID` shape.

The implementation should not reuse the mixed response-demux selected-ID/busy
state directly. It should not emit dynamic request static-ID reservation
assertions or dynamic active-not-static-ID assertions for this queue shape,
because dynamic/static same-ID overlap is the behavior being accepted and
ordered.

## Report Contract For `.503`

The implementation should introduce a distinct mixed queue report surface
rather than overloading the all-dynamic one:

```text
response_demux.write.mode:
  bounded_mixed_dynamic_static_write_bid_issue_order_queue_demux_contract
response_demux.write.transaction_completion_source:
  generated_mixed_dynamic_static_issue_order_queue_demux
response_demux.write.transaction_completion_semantics:
  earliest_matching_captured_or_static_runtime_id
response_demux.write.queue_state_representation:
  compact_runtime_id_issue_order_slots
response_demux.write.runtime_id_queue_key:
  captured_or_static_request_id
response_demux.write.response_demux_strategy:
  mixed_dynamic_static_issue_order_earliest_matching_slot
response_demux.write.mixed_transactions.dynamic:
  w0
response_demux.write.mixed_transactions.static:
  w1
response_demux.write.static_id_overlap_policy:
  allowed_by_issue_order_queue
```

The same-ID policy report should mark:

```text
same_id_ordering.dynamic_id_reuse_policy.write.policy:
  issue_order_queue
same_id_ordering.dynamic_id_reuse_policy.write.implementation_status:
  generated_mixed_dynamic_static_write_bid_issue_order_queue
same_id_ordering.dynamic_id_reuse_policy.write.enforcement:
  generated_mixed_dynamic_static_issue_order_queue
same_id_ordering.dynamic_id_reuse_policy.write.accepted_same_id_reuse:
  true
same_id_ordering.dynamic_id_reuse_policy.write.generated_queue_behavior:
  true
same_id_ordering.dynamic_id_reuse_policy.write.generated_scoreboard_behavior:
  false
same_id_ordering.dynamic_id_reuse_policy.write.active_id_uniqueness_policy:
  not_required_for_issue_order_queue
same_id_ordering.dynamic_id_reuse_policy.write.static_id_conflict_policy:
  ordered_overlap_allowed
```

The covered family should clear the same-ID ordering residue for this exact
shape while leaving mixed read queues, broader mixed queue cardinalities,
scoreboards, arbitrary cardinality, direct backend behavior,
backend-language variants, external converter dependencies such as `sv2v`,
and VHDL as explicit residue.

## Assertion And Rule Expectations

The `.503` implementation should prove these generated boundaries:

- slot onehot0 checks for each queue slot;
- compact queue ordering;
- onehot0 admitted enqueue across `w0` and `w1`;
- enqueue requires free space or same-cycle selected dequeue;
- response requires a nonempty queue;
- response must have a selected stored-ID match;
- selected response match is onehot0;
- selected dequeue requires a nonempty queue;
- each transaction appears in at most one slot;
- an admitted transaction is not already present after selected dequeue; and
- each generated completion follows the selected queue match for its
  transaction.

The first implementation should not widen same-cycle request policy beyond
onehot0. It should not add mixed read `RID`, mixed read `RID && RLAST`,
multi-static, two-dynamic-plus-static, scoreboard, arbitrary-cardinality,
direct backend, backend-language, external converter, or VHDL behavior.

## Selected Next Leaf

`.503` should implement exactly this source shape:

```text
write transactions: w0 dynamic, w1 concrete static value 3
id_families.write width: 4
request ID signal: axi0_awid
response ID signal: axi0_bid
same-id-ordering.write: dynamic-id-reuse issue-order-queue
response-demux.write: generated BID completion
submit-policy: try
write-max-pending: 2
queue depth: 2
```

The likely support-accounted sample name is:

```text
ppif/axi_manager_capacity_status_write_mixed_dynamic_static_same_id_issue_order_queue.ppif
```

Focused validation should include Perl syntax checks for the generator,
parser/focused dynamic tests, support-catalog checks, RAM-guarded schedule
JSON for the new PPIF, strict check JSON, semantic JSON, generated IAL1/IAL0
inspection, and support-accounting validation where host memory permits.

## Deferred Alternatives

`.502` explicitly defers:

- implementation until `.503`;
- mixed dynamic/static read single-beat `RID` queues;
- mixed dynamic/static read burst-last `RID && RLAST` queues;
- one-dynamic plus multi-static queues;
- two-dynamic plus one-static queues;
- scoreboards;
- arbitrary queue cardinality;
- same-cycle enqueue widening beyond onehot0;
- verification-code generation;
- direct backend behavior;
- backend-language variants;
- external converter dependency selection, including `sv2v`; and
- VHDL.

## Validation

This audit used:

- source review of the `.501` selector, `.500` behavior, `.455` and `.482`
  dynamic write queue behavior records, `.272` mixed write demux behavior,
  `.295` and `.341` broader mixed write records, and `.446` mixed dynamic
  same-ID reject mapping;
- parser and generator code review in
  `perl/FSM/Adapter/IAL2/PPIF.pm` and
  `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`;
- a RAM-guarded temporary candidate probe under `/tmp`, which failed closed
  at the all-dynamic write issue-order queue diagnostic quoted above; and
- documentation and continuity gates.

No behavior validation is claimed for `.502` because it changes no behavior.

## Rollback

Rollback is documentation-only: revert this audit doc, the matching Knowledge
Map card/map entry, task-tree advancement, README/ROADMAP/mdBook sync, and
Memory pointer. No generated HDL or runtime artifact rollback is required.
