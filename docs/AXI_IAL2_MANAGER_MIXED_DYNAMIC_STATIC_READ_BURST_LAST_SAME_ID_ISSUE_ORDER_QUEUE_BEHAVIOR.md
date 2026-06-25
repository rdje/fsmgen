# AXI IAL2 Manager Mixed Dynamic/Static Read Burst-Last Same-ID Issue-Order Queue Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.509`

Date: 2026-06-25

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.509` implements generated mixed
dynamic/static read burst-last `RID && RLAST` same-ID `issue-order-queue`
behavior for one dynamic read transaction and one concrete static read
transaction.

The supported public shape is deliberately narrow:

- `r0` is a read transaction with `(id dynamic)`;
- `r1` is a read transaction with a concrete static ID, currently `3` in the
  public sample;
- `same-id-ordering.read` selects `(dynamic-id-reuse issue-order-queue)`;
- `response-demux.read` owns generated burst-last `RID && RLAST`
  completions;
- `response-demux.read.response-scope` is `burst-last`;
- `response-demux.read.last-signal` is present and one bit wide;
- `read-max-pending` is at least `2`;
- read auto-ID lifecycle metadata is absent.

The implementation is FSMGen-owned. It does not depend on `sv2v` or any other
external SystemVerilog-to-Verilog converter.

## Public Sample

The support-accounted public sample is:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_burst_last_same_id_issue_order_queue.ppif
```

The core source shape is:

```lisp
(transactions
  (read r0
    (tag rd0)
    (request axi0_r0_request)
    (completion axi0_r0_complete)
    (id dynamic))
  (read r1
    (tag rd1)
    (request axi0_r1_request)
    (completion axi0_r1_complete)
    (id (value 3))))
(same-id-ordering
  (read (dynamic-id-reuse issue-order-queue)))
(response-demux
  (read
    (response-event axi0_read_complete)
    (response-scope burst-last)
    (last-signal axi0_rlast (width 1))
    (transaction-completion generated)))
```

The sample is registered as:

```text
intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_burst_last_same_id_issue_order_queue
```

with coverage bucket:

```text
ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_burst_last_same_id_issue_order_queue_pipeline_cli
```

It is a strict-supported `supported_smoke` PPIF entry.

## Queue State

The generated queue uses compact runtime-ID issue-order slots:

```text
queue_state_representation: compact_runtime_id_issue_order_slots
runtime_id_queue_key: captured_or_static_request_id
response_demux_strategy: mixed_dynamic_static_issue_order_earliest_matching_slot
last_signal: axi0_rlast
```

Each slot stores one-hot transaction identity plus a slot-local runtime ID.
Dynamic enqueues store `axi0_arid`; static enqueues store the sized concrete
literal, for example `4'd3`.

Generated IAL1 state for the public sample includes:

```text
axi0_read_mixed_dynamic_static_same_id_issue_order_slot0_r0_q
axi0_read_mixed_dynamic_static_same_id_issue_order_slot0_r1_q
axi0_read_mixed_dynamic_static_same_id_issue_order_slot0_id_q
axi0_read_mixed_dynamic_static_same_id_issue_order_slot1_r0_q
axi0_read_mixed_dynamic_static_same_id_issue_order_slot1_r1_q
axi0_read_mixed_dynamic_static_same_id_issue_order_slot1_id_q
```

The generated input set includes `axi0_arid`, `axi0_rid`, and `axi0_rlast`.
The queue path does not allocate legacy mixed response-demux selected-ID/busy
state such as `axi0_r0_dynamic_busy_q` or `axi0_r1_static_busy_q`.

## Response Semantics

Raw `RID` response matching selects the earliest valid queue slot whose stored
runtime ID equals `axi0_rid`. `RLAST` is deliberately not part of raw matching.
Non-final matching beats are valid for response ownership assertions, but they
do not generate a transaction completion and do not dequeue a queue slot.

Final selected matching adds `axi0_rlast`. If the dynamic and static requests
use the same runtime ID value, issue order decides which completion fires
first. If the earlier slot holds a different ID and the later slot matches
`RID`, the later slot may complete on its final beat, preserving per-ID order
without imposing global read response order.

The generated read response-demux report uses:

```text
response_demux.mode: bounded_response_demux_contract
response_demux.read.mode: bounded_mixed_dynamic_static_read_rid_rlast_issue_order_queue_demux_contract
response_event_role: raw_accepted_read_response_beat
response_scope: burst_last
last_signal: axi0_rlast
last_signal_width: 1
transaction_completion_source: generated_mixed_dynamic_static_issue_order_queue_demux_last_beat
transaction_completion_semantics: earliest_matching_captured_or_static_runtime_id_and_last_signal
beat_valid_output: none
burst_length_source: rlast_only
burst_length_validation: not_generated
generated_queue_behavior_boundary: generated_mixed_dynamic_static_read_rid_rlast_issue_order_queue
static_id_overlap_policy: allowed_by_issue_order_queue
```

The same-ID ordering report uses:

```text
implementation_status: generated_mixed_dynamic_static_read_rid_rlast_issue_order_queue
enforcement: generated_mixed_dynamic_static_issue_order_queue
accepted_same_id_reuse: true
generated_queue_behavior: true
generated_scoreboard_behavior: false
active_id_uniqueness_policy: not_required_for_issue_order_queue
static_id_conflict_policy: ordered_overlap_allowed
first_generated_scope: read_rid_rlast_one_dynamic_one_static_transaction
```

The generated assertions include selected-match ownership for both
transactions and a non-final no-dequeue assertion:

```text
axi0_read_mixed_dynamic_static_same_id_issue_order_nonlast_no_dequeue
axi0_read_mixed_dynamic_static_same_id_issue_order_r0_completion_selected_match
axi0_read_mixed_dynamic_static_same_id_issue_order_r1_completion_selected_match
```

## Deferred

Mixed read-data over this queue, raw `ARLEN`, runtime validation, multi-beat
output banks, multi-static mixed queues, two-dynamic-plus-static mixed queues,
scoreboards, arbitrary cardinality, same-cycle request widening beyond
onehot0, backend behavior, backend-language variants, verification-code
generation, external converter dependencies such as `sv2v`, and VHDL remain
future exact-owner work.
