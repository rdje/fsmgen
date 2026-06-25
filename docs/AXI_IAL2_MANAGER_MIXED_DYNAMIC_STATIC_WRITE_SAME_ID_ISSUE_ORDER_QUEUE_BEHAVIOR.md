# AXI IAL2 Manager Mixed Dynamic/Static Write Same-ID Issue-Order Queue Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.503`

Date: 2026-06-25

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.503` implements generated mixed
dynamic/static write `BID` same-ID `issue-order-queue` behavior for one
dynamic write transaction and one concrete static write transaction.

The supported public shape is deliberately narrow:

- `w0` is a write transaction with `(id dynamic)`;
- `w1` is a write transaction with a concrete static ID, currently `3` in the
  public sample;
- `same-id-ordering.write` selects `(dynamic-id-reuse issue-order-queue)`;
- `response-demux.write` owns generated `BID` completions;
- `write-max-pending` is at least `2`;
- write auto-ID lifecycle metadata is absent.

The implementation is FSMGen-owned. It does not depend on `sv2v` or any other
external SystemVerilog-to-Verilog converter.

## Public Sample

The support-accounted public sample is:

```text
ppif/axi_manager_capacity_status_write_mixed_dynamic_static_same_id_issue_order_queue.ppif
```

The sample is registered as:

```text
intent.ppif_axi_manager_capacity_status_write_mixed_dynamic_static_same_id_issue_order_queue
```

with coverage bucket:

```text
ial2_ppif_manager_capacity_status_write_mixed_dynamic_static_same_id_issue_order_queue_pipeline_cli
```

## Queue State

The generated queue uses compact runtime-ID issue-order slots:

```text
queue_state_representation: compact_runtime_id_issue_order_slots
runtime_id_queue_key: captured_or_static_request_id
response_demux_strategy: mixed_dynamic_static_issue_order_earliest_matching_slot
```

Each slot stores one-hot transaction identity plus a slot-local runtime ID.
Dynamic enqueues store `axi0_awid`; static enqueues store the sized concrete
literal, for example `4'd3`.

Generated IAL1 state for the public sample includes:

```text
axi0_write_mixed_dynamic_static_same_id_issue_order_slot0_w0_q
axi0_write_mixed_dynamic_static_same_id_issue_order_slot0_w1_q
axi0_write_mixed_dynamic_static_same_id_issue_order_slot0_id_q
axi0_write_mixed_dynamic_static_same_id_issue_order_slot1_w0_q
axi0_write_mixed_dynamic_static_same_id_issue_order_slot1_w1_q
axi0_write_mixed_dynamic_static_same_id_issue_order_slot1_id_q
```

The queue path does not allocate legacy mixed response-demux selected-ID/busy
state such as `axi0_w0_dynamic_busy_q` or `axi0_w1_static_busy_q`.

## Response Semantics

Raw `BID` response matching selects the earliest valid queue slot whose stored
runtime ID equals `axi0_bid`. If both dynamic and static requests use the same
runtime ID value, issue order decides which completion fires first.

The generated write response-demux report uses:

```text
mode: bounded_mixed_dynamic_static_write_bid_issue_order_queue_demux_contract
transaction_completion_source: generated_mixed_dynamic_static_issue_order_queue_demux
transaction_completion_semantics: earliest_matching_captured_or_static_runtime_id
static_id_overlap_policy: allowed_by_issue_order_queue
```

The same-ID ordering report uses:

```text
implementation_status: generated_mixed_dynamic_static_write_bid_issue_order_queue
enforcement: generated_mixed_dynamic_static_issue_order_queue
accepted_same_id_reuse: true
generated_queue_behavior: true
generated_scoreboard_behavior: false
active_id_uniqueness_policy: not_required_for_issue_order_queue
static_id_conflict_policy: ordered_overlap_allowed
first_generated_scope: write_bid_one_dynamic_one_static_transaction
```

## Deferred

Mixed read queues, multi-static mixed queues, two-dynamic-plus-static mixed
queues, scoreboards, arbitrary cardinality, backend behavior, backend-language
variants, verification-code generation, external converter dependencies such
as `sv2v`, and VHDL remain future exact-owner work.
