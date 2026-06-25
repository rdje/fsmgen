# AXI IAL2 Manager Dynamic Write Depth-3 Same-ID Issue-Order Queue Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.482`

Date: 2026-06-25

## Behavior

`IAL2-FEATURE-COMPLETENESS-FRONTIER.482` ships a second generated dynamic
write same-ID `issue-order-queue` shape:

```text
write transactions: w0, w1, w2
all transaction IDs: dynamic
same-id-ordering.write: dynamic-id-reuse issue-order-queue
response-demux.write: generated BID completion
write-max-pending: at least 3
queue depth: 3
```

The checked-in public sample is
`ppif/axi_manager_capacity_status_dynamic_write_depth3_same_id_issue_order_queue.ppif`.
It remains an AXI manager capacity/status `.ppif` input and lowers through the
same generated IAL1/IAL0/SystemVerilog-backed path as the existing depth-2
dynamic write queue sample.

## Generated Queue State

The generated queue allocates three compact runtime-ID issue-order slots.
Each slot contains one one-hot-or-empty transaction bit for `w0`, `w1`, and
`w2`, plus a captured `AWID` register:

```text
axi0_write_dynamic_same_id_issue_order_slot0_w0_q
axi0_write_dynamic_same_id_issue_order_slot0_w1_q
axi0_write_dynamic_same_id_issue_order_slot0_w2_q
axi0_write_dynamic_same_id_issue_order_slot0_id_q
...
axi0_write_dynamic_same_id_issue_order_slot2_w2_q
axi0_write_dynamic_same_id_issue_order_slot2_id_q
```

The queue uses `dynamic_issue_order_earliest_matching_slot` for `BID`
completion. If more than one occupied slot has the same captured `AWID`, the
earliest slot wins; later matching slots remain queued until a later accepted
write response.

## Update Rules

The depth-3 queue reuses the existing generated dynamic queue update model:

- enqueue captures the current `axi0_awid`;
- selected dequeue removes the earliest matching slot for the accepted `BID`;
- retained transactions compact toward slot0 and retain or move their captured
  IDs;
- selected dequeue plus same-transaction enqueue refreshes the affected
  captured ID from current `axi0_awid`.

Depth-3 introduces ambiguous cross-transaction selected-dequeue-plus-enqueue
rule names. Those names now include the selected dequeued transaction only
for the ambiguous dynamic cross-transaction cases. Existing depth-2 and
same-transaction refresh rule names stay stable. Examples:

```text
axi0_write_dynamic_same_id_issue_order_w2_w1_w0_dequeue_enqueue_w0
axi0_write_dynamic_same_id_issue_order_w0_w1_dequeue_w0_enqueue_w2
```

The first example is a same-transaction tail-selected recapture and keeps the
existing `dequeue_enqueue_<transaction>` form. The second example is a
cross-transaction enqueue from a non-full depth-3 state and includes the
selected dequeued transaction to keep generated rule names unique.

## Report Surface

The response-demux report continues to use
`bounded_dynamic_write_bid_issue_order_queue_demux_contract`,
`generated_dynamic_issue_order_queue_demux`,
`earliest_matching_captured_runtime_id`,
`compact_runtime_id_issue_order_slots`, and
`dynamic_issue_order_earliest_matching_slot`.

For the depth-3 sample, `response_demux.write.dynamic_transactions`,
`generated_rules`, and `generated_completion_signals` list `w0`, `w1`, and
`w2`.

The same-ID ordering report keeps
`implementation_status: generated_dynamic_write_bid_issue_order_queue`,
`enforcement: generated_dynamic_issue_order_queue`,
`accepted_same_id_reuse: true`, `generated_queue_behavior: true`,
`active_id_uniqueness_policy: not_required_for_issue_order_queue`, and
`request_conflict_policy: generated_issue_order_queue_onehot0_enqueue`.
For the new shape it reports:

```text
first_generated_scope: write_bid_three_dynamic_transactions
covered_dynamic_transactions: [w0, w1, w2]
generated_queues[0].depth: 3
```

Each generated queue entry also keeps the queue-owned identity recapture
fields shipped earlier:

```text
same_transaction_recapture_policy: refresh_captured_request_id
same_transaction_recapture_rule_scope: state_key_preserving_selected_dequeue_enqueue
same_transaction_recapture_id_source: axi0_awid
```

## Preserved Behavior

The existing depth-2 dynamic write, read single-beat, and read burst-last
same-ID issue-order queues are unchanged. Read depth-3 queues, read-data,
mixed dynamic/static queues, dynamic scoreboards, arbitrary dynamic queue
cardinality, direct backend behavior, backend-language variants, and VHDL
remain future exact owners.

## Validation

Syntax checks passed for the generator module, regression-corpus catalog, and
focused `t/1436`, `t/1437`, and `t/1438` tests. A lightweight private helper
probe for the depth-3 dynamic write queue produced 99 transition rules, 19
assertions, zero duplicate rule names, the tail-selected refresh rule, and
the disambiguated cross-transaction enqueue rule.

RAM-guarded probes passed for
`fsmgen --emit-schedule-json
ppif/axi_manager_capacity_status_dynamic_write_depth3_same_id_issue_order_queue.ppif`
and `prove -Iperl t/248-regression-corpus-accounting.t`.

## Rollback

Rollback removes the depth-3 dynamic write admission, rule-name
disambiguation, the new PPIF sample/support-accounting entry, focused test
expectations, this behavior record, and the live docs/Knowledge Map/task-tree
updates. The depth-2 generated dynamic queue behavior and identity-recapture
report fields remain unchanged.
