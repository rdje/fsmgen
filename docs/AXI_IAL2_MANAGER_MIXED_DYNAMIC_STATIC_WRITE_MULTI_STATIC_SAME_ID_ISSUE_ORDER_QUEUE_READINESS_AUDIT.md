# AXI IAL2 Manager Mixed Dynamic/Static Write Multi-Static Same-ID Issue-Order Queue Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.523`

Date: 2026-06-26

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.523` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.524`, direct bounded implementation of
generated mixed dynamic/static write `BID` same-ID `issue-order-queue`
behavior for exactly one dynamic write transaction plus two concrete static
write transactions.

No parser, IAL1, IAL0, SystemVerilog, backend, external converter, or VHDL
prerequisite is required first. The fail-closed boundary is local to the AXI
manager capacity/status generator's mixed write issue-order queue planner,
mixed queue materializer, report projection, focused tests, support accounting,
and public documentation.

This audit changes no parser, generator, PPIF sample, support-accounting
catalog, generated artifact, schedule/check/semantic JSON, test, HDL/runtime
behavior, backend behavior, verification-output generation, backend-language
variant, external converter dependency, scoreboard, group-local simultaneous
enqueue behavior, broader read queue, arbitrary cardinality, or VHDL behavior.

## Current Boundary

The shipped one-static mixed write queue sample is:

```text
ppif/axi_manager_capacity_status_write_mixed_dynamic_static_same_id_issue_order_queue.ppif
```

It covers:

```text
w0: dynamic write ID captured from axi0_awid
w1: concrete static write ID 4'd3
response ID signal: axi0_bid
same-id-ordering.write: dynamic-id-reuse issue-order-queue
response-demux.write: generated BID completion
queue depth: 2
```

The existing multi-static mixed write response-demux sample is:

```text
ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_static.ppif
```

It already covers one dynamic write transaction plus two pairwise-distinct
concrete static write transactions, but it intentionally has no same-ID
`issue-order-queue`. That response-demux-only path reserves static concrete
IDs away from dynamic capture. The queue path must instead allow dynamic/static
ID overlap and preserve completion order through the compact runtime-ID queue.

## Source Findings

Source inspection found the current blocker in two local guards:

- `_response_demux_dynamic_write_issue_order_queue_plan` accepts all-dynamic
  write queues with two or three dynamic transactions, and accepts mixed write
  queues only when the selected writes are exactly one dynamic plus one concrete
  static transaction.
- The shared same-ID issue-order queue materializer currently recognizes mixed
  dynamic/static queues only when queue depth is two and the transaction set is
  exactly one dynamic plus one static transaction.

The lower dynamic queue transition, assignment, assertion, storage, and report
helpers are already transaction-list driven. Mixed queues already use that
dynamic queue path with per-transaction enqueue IDs, so the next slice should
widen the bounded mixed queue admission rather than introduce a new queue
substrate.

## Probe Evidence

A temporary `/tmp` candidate copied the existing multi-static write
response-demux sample and added only:

```lisp
(same-id-ordering
  (write (dynamic-id-reuse issue-order-queue)))
```

The RAM-guarded strict check failed closed before artifact emission:

```text
AXI manager capacity/status IAL2 contract response_demux.write dynamic-id-reuse issue-order-queue requires exactly two or three all-dynamic write transactions, or exactly one dynamic plus one concrete static write transaction, in this slice
```

The probe emitted no generated output. That confirms `.524` can be scoped to
the mixed queue admission/report/test boundary without changing parser syntax
or lower IAL1/IAL0/SystemVerilog capabilities first.

## Selected `.524` Implementation Boundary

`.524` should add one public sample, with a likely stem:

```text
ppif/axi_manager_capacity_status_write_mixed_dynamic_static_same_id_issue_order_queue_multi_static.ppif
```

The selected source shape is:

```text
write transactions: w0, w1, w2
w0 transaction ID: dynamic
w1 transaction ID: 4'd3
w2 transaction ID: 4'd5
id_families.write width: 4
request ID signal: axi0_awid
response ID signal: axi0_bid
write-max-pending: at least 3
same-id-ordering.write: dynamic-id-reuse issue-order-queue
response-demux.write: generated BID completion
queue depth: 3 selected transactions
```

The implementation should:

- keep `response_demux.write.mode` as
  `bounded_mixed_dynamic_static_write_bid_issue_order_queue_demux_contract`
  unless implementation discovers a machine-readable compatibility reason for
  a new mode;
- make `dynamic_transactions`, `static_transactions`, generated completion
  signals, generated rules, and generated queues list-shaped for `w0`, `w1`,
  and `w2`;
- report `runtime_id_queue_key: captured_or_static_request_id`,
  `queue_state_representation: compact_runtime_id_issue_order_slots`, and
  `response_demux_strategy:
  mixed_dynamic_static_issue_order_earliest_matching_slot`;
- generate depth-3 slot storage for `w0`, `w1`, and `w2` plus one stored ID per
  slot;
- enqueue `w0` using `axi0_awid`, `w1` using `4'd3`, and `w2` using `4'd5`;
- require pairwise-distinct concrete static write IDs;
- require existing onehot0 admitted-request semantics across all selected write
  transactions;
- preserve `.503` one-dynamic plus one-static queue behavior and all-dynamic
  depth-2/depth-3 queue behavior; and
- keep same-ID ordering coverage scoped to write `BID`.

The same-ID policy report should continue to use:

```text
implementation_status: generated_mixed_dynamic_static_write_bid_issue_order_queue
enforcement: generated_mixed_dynamic_static_issue_order_queue
accepted_same_id_reuse: true
generated_queue_behavior: true
generated_scoreboard_behavior: false
active_id_uniqueness_policy: not_required_for_issue_order_queue
static_id_conflict_policy: ordered_overlap_allowed
```

The `first_generated_scope` should be refined to distinguish the new selected
boundary from `.503`, for example:

```text
write_bid_one_dynamic_two_static_transactions
```

## Validation Strategy

`.524` should run:

- syntax checks for touched Perl modules and focused tests;
- focused parser and generator coverage for the new public sample;
- preservation checks for the `.503` one-static mixed queue and all-dynamic
  depth-2/depth-3 write queues;
- support-accounting and capability-manifest checks if public surfaces change;
- guarded schedule/check/semantic/HDL probes for the new sample where host
  memory permits; and
- Knowledge Map generation/check, mdBook build, docs path audit, memory
  architecture check, diff check, and doctrine gate.

Broad or memory-heavy probes must stay behind `scripts/run_with_ram_guard.sh`
using the repository default host-memory policy unless the user explicitly
approves a different cutoff.

## Deferred

`.523` and `.524` do not select read queue cardinality widening, read-data,
raw-`ARLEN`, runtime-validation, multi-beat output banks, scoreboards,
arbitrary queue cardinality, group-local simultaneous enqueue widening, direct
backend behavior, verification-output generation, backend-language variants,
external converter dependencies, or VHDL.

## Rollback

Rollback for `.523` is documentation-only: remove this audit note, its
Knowledge Map fact, task-tree advancement, README/ROADMAP/mdBook sync, and
Memory pointer update. No generated HDL or runtime artifact rollback is
required because no behavior changed.
