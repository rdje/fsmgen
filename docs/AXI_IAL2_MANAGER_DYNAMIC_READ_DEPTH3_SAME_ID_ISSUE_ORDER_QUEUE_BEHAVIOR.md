# AXI IAL2 Manager Dynamic Read Depth-3 Same-ID Issue-Order Queue Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.485`

Date: 2026-06-25

## Behavior

`IAL2-FEATURE-COMPLETENESS-FRONTIER.485` ships a generated dynamic read
same-ID `issue-order-queue` widened to one bounded depth-3 single-beat shape:

```text
read transactions: r0, r1, r2
all transaction IDs: dynamic
same-id-ordering.read: dynamic-id-reuse issue-order-queue
response-demux.read: response-scope single-beat, generated RID completion
read-max-pending: at least 3
queue depth: 3
```

The checked-in public sample is
`ppif/axi_manager_capacity_status_dynamic_read_depth3_same_id_issue_order_queue.ppif`.
It remains an AXI manager capacity/status `.ppif` input and lowers through the
same generated IAL1/IAL0/SystemVerilog-backed path as the existing depth-2
dynamic read queue sample.

## Generated Queue State

The generated queue allocates three compact runtime-ID issue-order slots.
Each slot contains one one-hot-or-empty transaction bit for `r0`, `r1`, and
`r2`, plus a captured `ARID` register:

```text
axi0_read_dynamic_same_id_issue_order_slot0_r0_q
axi0_read_dynamic_same_id_issue_order_slot0_r1_q
axi0_read_dynamic_same_id_issue_order_slot0_r2_q
axi0_read_dynamic_same_id_issue_order_slot0_id_q
...
axi0_read_dynamic_same_id_issue_order_slot2_r2_q
axi0_read_dynamic_same_id_issue_order_slot2_id_q
```

The queue uses `dynamic_issue_order_earliest_matching_slot` for single-beat
`RID` completion. If more than one occupied slot has the same captured
`ARID`, the earliest slot wins; later matching slots remain queued until a
later accepted read response. Different captured IDs may complete out of
global issue order.

## Update Rules

The depth-3 queue reuses the generated dynamic queue update model:

- enqueue captures the current `axi0_arid`;
- selected dequeue removes the earliest matching slot for the accepted `RID`;
- retained transactions compact toward slot0 and retain or move their captured
  IDs;
- selected dequeue plus same-transaction enqueue refreshes the affected
  captured ID from current `axi0_arid`.

Depth-3 cross-transaction selected-dequeue-plus-enqueue rule names include
the selected dequeued transaction so generated names stay unique. Examples:

```text
axi0_read_dynamic_same_id_issue_order_r2_r1_r0_dequeue_enqueue_r0
axi0_read_dynamic_same_id_issue_order_r0_r1_dequeue_r0_enqueue_r2
```

The first example is a same-transaction tail-selected recapture and keeps the
existing `dequeue_enqueue_<transaction>` form. The second example is a
cross-transaction enqueue from a non-full depth-3 state and includes the
selected dequeued transaction.

## Report Surface

The response-demux report uses:

```text
mode: bounded_dynamic_read_rid_issue_order_queue_demux_contract
response_scope: single_beat
transaction_completion_source: generated_dynamic_issue_order_queue_demux
transaction_completion_semantics: earliest_matching_captured_runtime_id
queue_state_representation: compact_runtime_id_issue_order_slots
runtime_id_queue_key: captured_request_id
response_demux_strategy: dynamic_issue_order_earliest_matching_slot
```

For the depth-3 sample, `response_demux.read.dynamic_transactions`,
`generated_rules`, and `generated_completion_signals` list `r0`, `r1`, and
`r2`.

The same-ID ordering report keeps
`implementation_status: generated_dynamic_read_rid_issue_order_queue`,
`enforcement: generated_dynamic_issue_order_queue`,
`accepted_same_id_reuse: true`, `generated_queue_behavior: true`,
`dynamic_issue_order_queue_covered: true`, and
`active_id_uniqueness_policy: not_required_for_issue_order_queue`. For the
new shape it reports:

```text
first_generated_scope: read_rid_three_dynamic_transactions
covered_dynamic_transactions: [r0, r1, r2]
generated_queues[0].depth: 3
```

Each generated queue entry also keeps the queue-owned identity recapture
fields:

```text
same_transaction_recapture_policy: refresh_captured_request_id
same_transaction_recapture_rule_scope: state_key_preserving_selected_dequeue_enqueue
same_transaction_recapture_id_source: axi0_arid
```

## Preserved Behavior

The existing depth-2 dynamic write, depth-3 dynamic write, depth-2 dynamic
read single-beat, and depth-2 dynamic read burst-last same-ID issue-order
queues are unchanged. Read burst-last depth-3 queues, read-data over depth-3
dynamic queues, mixed dynamic/static queues, dynamic scoreboards, arbitrary
dynamic queue cardinality, direct backend behavior, backend-language
variants, external converter dependencies, and VHDL remain future exact
owners.

## Validation

Syntax checks passed for the generator module, regression-corpus catalog, and
focused `t/1436`, `t/1437`, `t/1438`, and `t/248` tests. A RAM-guarded
schedule JSON probe for
`ppif/axi_manager_capacity_status_dynamic_read_depth3_same_id_issue_order_queue.ppif`
passed and reported generated `r0`/`r1`/`r2` queue matching.

## Rollback

Rollback removes the depth-3 dynamic read single-beat admission, the new PPIF
sample/support-accounting entry, focused test expectations, this behavior
record, and the live docs/Knowledge Map/task-tree updates. The depth-2
generated dynamic read queues, depth-3 generated dynamic write queue, and
identity-recapture report fields remain unchanged.
