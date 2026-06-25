# AXI IAL2 Manager Mixed Dynamic/Static Read Same-ID Issue-Order Queue Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.505`

Date: 2026-06-25

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.505` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.506`, direct bounded implementation of
generated mixed dynamic/static read single-beat `RID` same-ID
`issue-order-queue` behavior for exactly one dynamic read transaction and one
concrete static read transaction.

No parser, IAL1, IAL0, SystemVerilog, support-accounting, backend-language,
external converter, verification-output, or VHDL prerequisite is required
first. The current fail-closed boundary is local to the AXI manager
capacity/status generator's read issue-order queue planner, read
response-demux normalization/report projection, and the mixed queue coverage
gate that currently enables mixed dynamic/static queues for `write` only.

This audit changes no parser, generator, PPIF sample, support-accounting
catalog, generated artifact, report JSON, test, HDL/runtime behavior, external
converter dependency, mixed read burst-last queue behavior,
arbitrary-cardinality queue behavior, direct backend behavior,
backend-language variant, verification-code output, or VHDL behavior.

## Current Boundary

The public parser already accepts the read-side policy syntax:

```lisp
(same-id-ordering
  (read (dynamic-id-reuse issue-order-queue)))
```

The existing one-dynamic plus one-static mixed read response-demux sample:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux.ppif
```

ships generated single-beat `RID` matching for:

```text
r0: dynamic ID captured from axi0_arid
r1: concrete static ID 3
response ID signal: axi0_rid
read-max-pending: 4 in the existing response-demux sample
```

That mixed demux intentionally requires no `same_id_ordering.read`, reserves
the concrete static ID away from dynamic capture, and emits static-ID
exclusion assertions. That remains correct for response-demux-only mixed
matching, but it is not the desired same-ID issue-order queue semantics. The
queue-owned shape must allow the dynamic request to use the static concrete ID
and preserve completion order by the compact queue slot selected for the raw
`RID`.

The existing all-dynamic read queue samples:

```text
ppif/axi_manager_capacity_status_dynamic_read_same_id_issue_order_queue.ppif
ppif/axi_manager_capacity_status_dynamic_read_depth3_same_id_issue_order_queue.ppif
```

ship compact runtime-ID issue-order slots for two or three all-dynamic read
single-beat transactions. Each occupied slot stores one transaction identity
bit and one captured `ARID`; raw `RID` response matching selects the earliest
occupied slot whose captured ID equals `axi0_rid`. This is the right queue
model for the mixed read single-beat shape, provided a static transaction
enqueue stores the concrete literal in the slot ID field instead of capturing
`axi0_arid`.

The existing all-dynamic read burst-last queue:

```text
ppif/axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue.ppif
```

proves the same queue substrate can gate read completion by `RLAST`, but that
is intentionally outside the `.506` first mixed read queue slice. `.506`
should remain single-beat and avoid `RLAST`, read-data, raw `ARLEN`, runtime
beat-count validation, and multi-beat output banks.

## Probe Evidence

A temporary `/tmp` candidate was derived from the existing mixed read
single-beat PPIF by adding:

```lisp
(same-id-ordering
  (read (dynamic-id-reuse issue-order-queue)))
```

A RAM-guarded run required process-inspection approval because the sandbox
blocked the RAM guard's process-tree inspection. The approved RAM-guarded run
then failed closed before generated artifacts were emitted:

```text
AXI manager capacity/status IAL2 contract response_demux.read dynamic-id-reuse issue-order-queue requires exactly two all-dynamic read transactions, or exactly three all-dynamic read transactions with response_scope single-beat or burst-last in this slice
```

The failure occurs in
`_response_demux_dynamic_read_issue_order_queue_plan`. That planner recognizes
`dynamic-id-reuse issue-order-queue` before the mixed dynamic/static demux
planner, then requires all selected read transactions to be dynamic and the
dynamic count to be exactly two, or exactly three with an explicit
single-beat/burst-last scope. Because the candidate has one dynamic and one
concrete static read transaction, it fails closed there.

The older generic mixed read response-demux helper remains intentionally
closed for queue semantics. `_response_demux_mixed_dynamic_static_read_transaction`
can build response-demux-only selected-ID/busy state, but that state uses
`static_concrete_ids_reserved` plus static-ID exclusion. The `.506` behavior
must use queue-owned accepted overlap, not static-ID reservation.

## Implementation Readiness

Direct implementation is ready as a narrow local generator slice:

- add a mixed dynamic/static read issue-order queue plan for exactly one
  dynamic read transaction plus one concrete static read transaction;
- require `read-max-pending >= 2`, read ID-family metadata, explicit
  `response-demux.read` with `response-scope single-beat`, and
  `same-id-ordering.read (dynamic-id-reuse issue-order-queue)`;
- reject `read auto_id_lifecycle` for this shape, matching the all-dynamic
  read queue boundary;
- reuse compact runtime-ID slot representation, with transaction identity bits
  plus one slot ID register per slot;
- enqueue the dynamic transaction with slot ID assigned from `axi0_arid`;
- enqueue the static transaction with slot ID assigned from the concrete sized
  literal such as `4'd3`;
- match `axi0_rid` against the earliest occupied slot's stored ID, preserving
  same-ID order and allowing different IDs to complete out of global order;
- preserve onehot0 enqueue policy across the dynamic and static request events;
- keep same-cycle selected dequeue plus one enqueue semantics aligned with the
  existing all-dynamic queue transition generator and `.503` mixed write queue;
- report accepted same-ID reuse through generated queue behavior, not through
  static-ID exclusion reject mapping; and
- keep generated behavior bounded to the exact one-dynamic plus one-static
  read single-beat `RID` shape.

The shared queue builder already has most of the required substrate. It can
store per-transaction queue ID sources, including a dynamic request-ID signal
or a static concrete literal, and `_mixed_dynamic_static_same_id_issue_order_queue_group_prefix`
is family-parameterized. The known local gaps are:

- `_response_demux_dynamic_read_issue_order_queue_plan` has no mixed
  dynamic/static branch;
- `_normalize_response_demux_read` does not yet project static and mixed
  transaction fields for read issue-order queue plans;
- `_build_dynamic_same_id_issue_order_queue_behavior` currently enables
  `generated_mixed_dynamic_static_issue_order_queue_demux` only when the
  family is `write`; and
- the read same-ID policy report should use a read-specific first generated
  scope for one dynamic plus one static single-beat `RID`.

The implementation should not reuse the mixed response-demux selected-ID/busy
state directly. It should not emit dynamic request static-ID reservation
assertions or dynamic active-not-static-ID assertions for this queue shape,
because dynamic/static same-ID overlap is the behavior being accepted and
ordered.

## Report Contract For `.506`

The implementation should introduce a distinct mixed read queue report surface
rather than overloading the all-dynamic read queue or mixed response-demux-only
surfaces:

```text
response_demux.read.mode:
  bounded_mixed_dynamic_static_read_rid_issue_order_queue_demux_contract
response_demux.read.transaction_completion_source:
  generated_mixed_dynamic_static_issue_order_queue_demux
response_demux.read.transaction_completion_semantics:
  earliest_matching_captured_or_static_runtime_id
response_demux.read.response_scope:
  single_beat
response_demux.read.queue_state_representation:
  compact_runtime_id_issue_order_slots
response_demux.read.runtime_id_queue_key:
  captured_or_static_request_id
response_demux.read.response_demux_strategy:
  mixed_dynamic_static_issue_order_earliest_matching_slot
response_demux.read.mixed_transactions.dynamic:
  r0
response_demux.read.mixed_transactions.static:
  r1
response_demux.read.static_id_overlap_policy:
  allowed_by_issue_order_queue
```

The same-ID policy report should mark:

```text
same_id_ordering.dynamic_id_reuse_policy.read.policy:
  issue_order_queue
same_id_ordering.dynamic_id_reuse_policy.read.implementation_status:
  generated_mixed_dynamic_static_read_rid_issue_order_queue
same_id_ordering.dynamic_id_reuse_policy.read.enforcement:
  generated_mixed_dynamic_static_issue_order_queue
same_id_ordering.dynamic_id_reuse_policy.read.accepted_same_id_reuse:
  true
same_id_ordering.dynamic_id_reuse_policy.read.generated_queue_behavior:
  true
same_id_ordering.dynamic_id_reuse_policy.read.generated_scoreboard_behavior:
  false
same_id_ordering.dynamic_id_reuse_policy.read.active_id_uniqueness_policy:
  not_required_for_issue_order_queue
same_id_ordering.dynamic_id_reuse_policy.read.static_id_conflict_policy:
  ordered_overlap_allowed
same_id_ordering.dynamic_id_reuse_policy.read.first_generated_scope:
  read_rid_one_dynamic_one_static_transaction
```

The covered family should clear the same-ID ordering residue for this exact
shape while leaving mixed read burst-last queues, read-data over mixed queues,
broader mixed queue cardinalities, scoreboards, arbitrary cardinality, direct
backend behavior, backend-language variants, external converter dependencies
such as `sv2v`, verification-code generation, and VHDL as explicit residue.

## Assertion And Rule Expectations

The `.506` implementation should prove these generated boundaries:

- slot onehot0 checks for each queue slot;
- compact queue ordering;
- onehot0 admitted enqueue across `r0` and `r1`;
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
onehot0. It should not add mixed read `RID && RLAST`, read-data, raw `ARLEN`,
runtime validation, multi-beat output banks, multi-static,
two-dynamic-plus-static, scoreboard, arbitrary-cardinality, direct backend,
backend-language, external converter, verification-code, or VHDL behavior.

## Selected Next Leaf

`.506` should implement exactly this source shape:

```text
read transactions: r0 dynamic, r1 concrete static value 3
id_families.read width: 4
request ID signal: axi0_arid
response ID signal: axi0_rid
same-id-ordering.read: dynamic-id-reuse issue-order-queue
response-demux.read: generated single-beat RID completion
submit-policy: try
read-max-pending: at least 2
queue depth: 2
```

The likely public sample name is:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_same_id_issue_order_queue.ppif
```

## Generated Boundary

The generated path remains the standard contract chain:

```text
.ppif IAL2 -> generated .isf IAL1 -> generated .fsm IAL0 -> SystemVerilog
```

The implementation should generate reviewable IAL1 queue storage/rules and
IAL0 scheduled artifacts before HDL generation. No direct IAL2-to-HDL path,
direct backend behavior, backend-language-specific shortcut, VHDL reroute, or
external converter dependency should be introduced.

## Diagnostics

`.506` should keep unsupported shapes fail-closed with focused diagnostics:

- mixed read issue-order queue with no read ID-family metadata;
- `read-max-pending < 2`;
- `response-demux.read.response-scope` other than `single-beat`;
- multiple dynamic read transactions in the mixed branch;
- multiple concrete static read transactions in the mixed branch;
- static transaction without a concrete ID value;
- missing or mismatched `same-id-ordering.read
  (dynamic-id-reuse issue-order-queue)`;
- attempted combination with read auto-ID lifecycle in the first slice; and
- broader burst-last/read-data/runtime/multi-beat behavior routed to future
  owners.

## Validation

The `.506` implementation should run focused parser/generator/dynamic-ID and
support-accounting checks where RAM permits. The minimum closeout should also
include direct schedule/report probes for the new sample, Knowledge Map
generation/check, mdBook build, docs path audit, memory architecture check,
diff whitespace check, and doctrine gate.

Any broad `prove`, strict check, or sample-support command that may exceed
memory limits must run through `scripts/run_with_ram_guard.sh` or an
equivalent monitor. If RAM guard stops a broad run at the documented cutoff,
record the caveat and do not retry unguarded.

## Documentation And Knowledge Map

`.506` should update README, ROADMAP_V2, mdBook, behavior docs, task tree,
MEMORY.md, the regression-corpus docs if a new support-accounted sample lands,
and Knowledge Map fact cards in the same commit as the behavior. The mdBook
should describe both the shipped user-facing sample and the exact report keys,
and it should keep burst-last/read-data/VHDL residue explicit.

## Rollback

Rollback for this audit is this documentation/task-tree commit. Reverting it
restores `.505` as pending and removes the `.506` implementation selection
without changing implementation behavior.

Rollback for `.506` should be the implementation commit, including any new
sample, support-accounting entry, generated report behavior, tests, docs,
mdBook, Memory, and Knowledge Map updates.
