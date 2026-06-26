# AXI IAL2 Manager Mixed Dynamic/Static Write Multi-Static Same-ID Issue-Order Queue Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.524`

Date: 2026-06-26

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.524` implements generated mixed
dynamic/static write `BID` same-ID `issue-order-queue` behavior for one
dynamic write transaction and two concrete static write transactions.

The supported public shape is deliberately narrow:

- `w0` is a write transaction with `(id dynamic)`;
- `w1` and `w2` are write transactions with pairwise-distinct concrete static
  IDs, currently `3` and `5` in the public sample;
- `same-id-ordering.write` selects `(dynamic-id-reuse issue-order-queue)`;
- `response-demux.write` owns generated `BID` completions;
- `write-max-pending` is at least `3`;
- write ID-family metadata is positive-width and names `axi0_awid` plus
  `axi0_bid`; and
- write auto-ID lifecycle metadata is absent.

The implementation is FSMGen-owned. It does not depend on `sv2v` or any other
external SystemVerilog-to-Verilog converter.

## Public Sample

The support-accounted public sample is:

```text
ppif/axi_manager_capacity_status_write_mixed_dynamic_static_same_id_issue_order_queue_multi_static.ppif
```

The sample is registered as:

```text
intent.ppif_axi_manager_capacity_status_write_mixed_dynamic_static_same_id_issue_order_queue_multi_static
```

with coverage bucket:

```text
ial2_ppif_manager_capacity_status_write_mixed_dynamic_static_same_id_issue_order_queue_multi_static_pipeline_cli
```

## Queue State

The generated queue uses compact runtime-ID issue-order slots:

```text
queue_state_representation: compact_runtime_id_issue_order_slots
runtime_id_queue_key: captured_or_static_request_id
response_demux_strategy: mixed_dynamic_static_issue_order_earliest_matching_slot
depth: 3
```

Each slot stores one-hot transaction identity plus a slot-local runtime ID.
Dynamic enqueues store `axi0_awid`; static enqueues store the sized concrete
literals `4'd3` and `4'd5`.

Generated IAL1 state for the public sample includes:

```text
axi0_write_mixed_dynamic_static_same_id_issue_order_slot0_w0_q
axi0_write_mixed_dynamic_static_same_id_issue_order_slot0_w1_q
axi0_write_mixed_dynamic_static_same_id_issue_order_slot0_w2_q
axi0_write_mixed_dynamic_static_same_id_issue_order_slot0_id_q
axi0_write_mixed_dynamic_static_same_id_issue_order_slot1_w0_q
axi0_write_mixed_dynamic_static_same_id_issue_order_slot1_w1_q
axi0_write_mixed_dynamic_static_same_id_issue_order_slot1_w2_q
axi0_write_mixed_dynamic_static_same_id_issue_order_slot1_id_q
axi0_write_mixed_dynamic_static_same_id_issue_order_slot2_w0_q
axi0_write_mixed_dynamic_static_same_id_issue_order_slot2_w1_q
axi0_write_mixed_dynamic_static_same_id_issue_order_slot2_w2_q
axi0_write_mixed_dynamic_static_same_id_issue_order_slot2_id_q
```

The queue path does not allocate legacy mixed response-demux selected-ID/busy
state such as `axi0_w0_dynamic_busy_q`, `axi0_w1_static_busy_q`, or
`axi0_w2_static_busy_q`.

## Response Semantics

Raw `BID` response matching selects the earliest valid queue slot whose stored
runtime ID equals `axi0_bid`. If dynamic and static requests use the same
runtime ID value, issue order decides which completion fires first.

The generated write response-demux report uses:

```text
mode: bounded_mixed_dynamic_static_write_bid_issue_order_queue_demux_contract
transaction_completion_source: generated_mixed_dynamic_static_issue_order_queue_demux
transaction_completion_semantics: earliest_matching_captured_or_static_runtime_id
dynamic_transactions: [w0]
static_transactions: [w1, w2]
mixed_transactions.static: [w1, w2]
generated_completion_signals: [axi0_w0_complete, axi0_w1_complete, axi0_w2_complete]
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
first_generated_scope: write_bid_one_dynamic_two_static_transactions
```

The existing `.503` one-dynamic plus one-concrete-static write queue behavior
and all-dynamic write depth-2/depth-3 queue behaviors remain supported.

## Deferred

Read queue cardinality widening, read-data, raw `ARLEN`, runtime validation,
multi-beat output banks, scoreboards, arbitrary mixed cardinality,
group-local simultaneous enqueue widening, backend behavior, verification
output, backend-language variants, external converter dependencies such as
`sv2v`, and VHDL remain future exact-owner work.
