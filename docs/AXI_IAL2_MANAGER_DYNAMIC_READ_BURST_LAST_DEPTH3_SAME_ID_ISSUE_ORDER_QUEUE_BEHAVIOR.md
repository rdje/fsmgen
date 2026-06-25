# AXI IAL2 Manager Dynamic Read Burst-Last Depth-3 Same-ID Issue-Order Queue Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.488`

Date: 2026-06-25

## Behavior

`IAL2-FEATURE-COMPLETENESS-FRONTIER.488` ships generated support for one
bounded all-dynamic read burst-last `RID && RLAST` same-ID
`issue-order-queue` shape:

```text
read transactions: r0, r1, r2
all transaction IDs: dynamic
same-id-ordering.read: dynamic-id-reuse issue-order-queue
response-demux.read: response-scope burst-last, generated RID/RLAST completion
response-demux.read.last-signal: axi0_rlast, width 1
read-max-pending: at least 3
queue depth: 3
```

The public support-accounted sample is:

```text
ppif/axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue.ppif
```

It registers as
`intent.ppif_axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue`
with coverage bucket
`ial2_ppif_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_pipeline_cli`.

## Generated Queue

FSMGen generates three compact runtime-ID issue-order slots. Each slot stores
one one-hot-or-empty transaction bit for `r0`, `r1`, and `r2`, plus a captured
`ARID` register:

```text
axi0_read_dynamic_same_id_issue_order_slot0_r0_q
axi0_read_dynamic_same_id_issue_order_slot0_r1_q
axi0_read_dynamic_same_id_issue_order_slot0_r2_q
axi0_read_dynamic_same_id_issue_order_slot0_id_q
...
axi0_read_dynamic_same_id_issue_order_slot2_r2_q
axi0_read_dynamic_same_id_issue_order_slot2_id_q
```

The queue path does not allocate the legacy per-transaction dynamic selected-ID
or busy state such as `axi0_r2_dynamic_id_q` or `axi0_r2_dynamic_busy_q`.

## Response Semantics

Raw read response ownership uses the earliest occupied queue slot whose
captured `ARID` equals `axi0_rid`. `RLAST` is not part of raw ownership. A
matching non-final beat proves response ownership but does not generate a
transaction completion and does not dequeue the queue.

Final selected completion adds the one-bit `axi0_rlast` gate:

```text
slotN_final_selected_match = slotN_selected_match && axi0_rlast
```

If multiple occupied slots hold the same captured ID, the earliest matching
slot wins and same-ID issue order is preserved. A later slot with a different
captured ID may complete first when its `RID && RLAST` arrives, matching AXI
per-ID ordering semantics.

## Report Surface

The response-demux report uses:

```text
mode: bounded_dynamic_read_rid_rlast_issue_order_queue_demux_contract
response_scope: burst_last
last_signal: axi0_rlast
last_signal_width: 1
transaction_completion_source: generated_dynamic_issue_order_queue_demux_last_beat
transaction_completion_semantics: earliest_matching_captured_runtime_id_and_last_signal
queue_state_representation: compact_runtime_id_issue_order_slots
runtime_id_queue_key: captured_request_id
response_demux_strategy: dynamic_issue_order_earliest_matching_slot
dynamic_transactions: [r0, r1, r2]
generated_rules: [axi0_r0_response_demux, axi0_r1_response_demux, axi0_r2_response_demux]
generated_completion_signals: [axi0_r0_complete, axi0_r1_complete, axi0_r2_complete]
```

The same-ID ordering policy reports:

```text
implementation_status: generated_dynamic_read_rid_rlast_issue_order_queue
enforcement: generated_dynamic_issue_order_queue
accepted_same_id_reuse: true
dynamic_issue_order_queue_covered: true
first_generated_scope: read_rid_rlast_three_dynamic_transactions
covered_dynamic_transactions: [r0, r1, r2]
generated_queues[0].depth: 3
```

Each generated queue report keeps the queue-owned identity-recapture fields:

```text
same_transaction_recapture_policy: refresh_captured_request_id
same_transaction_recapture_rule_scope: state_key_preserving_selected_dequeue_enqueue
same_transaction_recapture_id_source: axi0_arid
```

Depth-3 RLAST queues also report the slot2 onehot assertion, the non-final
no-dequeue assertion, the `r2` completion-selected-match assertion, the
tail-selected recapture rule, and the disambiguated cross-transaction enqueue
rule:

```text
axi0_read_dynamic_same_id_issue_order_slot2_onehot0
axi0_read_dynamic_same_id_issue_order_nonlast_no_dequeue
axi0_read_dynamic_same_id_issue_order_r2_completion_selected_match
axi0_read_dynamic_same_id_issue_order_r2_r1_r0_dequeue_enqueue_r0
axi0_read_dynamic_same_id_issue_order_r0_r1_dequeue_r0_enqueue_r2
```

## Preserved Behavior

The existing depth-2 dynamic write, depth-3 dynamic write, depth-2 dynamic
read single-beat, depth-3 dynamic read single-beat, and depth-2 dynamic read
burst-last same-ID issue-order queues remain unchanged.

Read-data over depth-3 dynamic queues, raw `ARLEN`, runtime beat-count/`RLAST`
validation, multi-beat output banks, mixed dynamic/static queues, dynamic
scoreboards, arbitrary dynamic queue cardinality, direct backend behavior,
backend-language variants, external converter dependencies such as `sv2v`,
and VHDL remain future exact-owner work. FSMGen-owned generation/lowering
remains the default.

## Validation

Syntax checks passed for the generator module, regression-corpus catalog, and
focused `t/1436`, `t/1437`, `t/1438`, and `t/248` tests. RAM-guarded
`t/248-regression-corpus-accounting.t` passed. A RAM-guarded schedule JSON
smoke and a RAM-guarded one-sample adapter/report smoke passed for
`ppif/axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue.ppif`
and reported the new three-transaction RLAST queue contract. A full
RAM-guarded `t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t` attempt
stopped before TAP results when host memory reached 89.0% against the 88%
cutoff; no unguarded retry or cutoff raise was used. Knowledge Map
generation/check, mdBook build, docs path audit, memory architecture check,
diff check, and doctrine gate passed.

## Rollback

Rollback removes the depth-3 burst-last dynamic read queue admission, the
support-accounted PPIF sample, focused test expectations, this behavior
record, and the live docs/Knowledge Map/task-tree updates. The shipped
depth-2 RLAST queue, depth-3 single-beat read queue, and depth-3 write queue
remain unchanged.
