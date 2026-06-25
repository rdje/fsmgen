# AXI IAL2 Manager Dynamic Read Burst-Last Depth-3 Same-ID Issue-Order Queue Read-Data Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.491`

Date: 2026-06-25

## Behavior

`IAL2-FEATURE-COMPLETENESS-FRONTIER.491` ships scalar last-beat
`RDATA`/`RRESP` capture over the generated all-dynamic read burst-last
`RID && RLAST` same-ID `issue-order-queue` depth-3 behavior shipped in
`.488`.

The supported public shape is intentionally exact:

```text
read transactions: r0, r1, r2
all transaction IDs: dynamic
same-id-ordering.read: dynamic-id-reuse issue-order-queue
response-demux.read: response-scope burst-last, generated RID/RLAST completion
response-demux.read.last-signal: axi0_rlast, width 1
read-data.read.capture-scope: last-beat
read-data.read.completion-source: response-demux
read-data.read.status-policy: last-beat
read-data.read.interleaving: last-beat-by-rid
queue depth: 3
```

The public support-accounted sample is:

```text
ppif/axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data.ppif
```

It registers as:

```text
intent.ppif_axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data
ial2_ppif_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data_pipeline_cli
```

## Generated Capture

FSMGen keeps the queue-owned `RID && RLAST` completion source and adds
scalar last-beat capture rules for all three dynamic read transactions:

```text
axi0_r0_read_data_capture: axi0_r0_complete -> axi0_r0_last_rdata, axi0_r0_last_rresp
axi0_r1_read_data_capture: axi0_r1_complete -> axi0_r1_last_rdata, axi0_r1_last_rresp
axi0_r2_read_data_capture: axi0_r2_complete -> axi0_r2_last_rdata, axi0_r2_last_rresp
```

The generated `r2` path is representative:

```text
(rule axi0_r2_read_data_capture axi0_r2_complete
  (axi0_r2_last_rdata axi0_rdata)
  (axi0_r2_last_rresp axi0_rresp))
```

The slice does not introduce `axi0_arlen`, beat-count storage, multi-beat
output banks, or RRESP aggregation.

## Report Surface

The response-demux report remains the `.488` queue contract:

```text
mode: bounded_dynamic_read_rid_rlast_issue_order_queue_demux_contract
transaction_completion_source: generated_dynamic_issue_order_queue_demux_last_beat
dynamic_transactions: [r0, r1, r2]
generated_completion_signals: [axi0_r0_complete, axi0_r1_complete, axi0_r2_complete]
first_generated_scope: read_rid_rlast_three_dynamic_transactions
generated_queues[0].depth: 3
```

The read-data report uses the existing scalar last-beat contract:

```text
mode: bounded_last_beat_read_data_contract
generated_behavior: true
capture_scope: last_beat
completion_source: response_demux
completion_validity: generated_dynamic_read_issue_order_queue_response_demux_last_beat_completion_pulse
data_signal: axi0_rdata
status_signal: axi0_rresp
status_policy: last_beat
interleaving_policy: last_beat_by_rid
transactions: [r0, r1, r2]
generated_rules: [axi0_r0_read_data_capture, axi0_r1_read_data_capture, axi0_r2_read_data_capture]
```

Read-data residue remains:

```text
multi_beat_read_data_reassembly
per_beat_outputs
rresp_aggregation
arlen_or_beat_count_validation
```

## Preserved Behavior

The existing two-transaction dynamic issue-order queue read-data, raw
`ARLEN`, runtime beat-count/`RLAST` validation, and multi-beat output-bank
shapes remain unchanged. The `.488` queue without read-data remains
unchanged. Parser syntax is unchanged.

Mixed dynamic/static queues, scoreboards, arbitrary queue cardinality,
direct backend behavior, backend-language variants, external converter
dependencies such as `sv2v`, and VHDL remain deferred. FSMGen-owned
generation/lowering remains the default.

## Validation

Passed:

- syntax checks for `AxiManagerCapacityStatus.pm`, `RegressionCorpus.pm`,
  `t/1436`, `t/1437`, `t/1438`, and `t/248`;
- RAM-guarded schedule JSON for the new PPIF sample;
- RAM-guarded adapter/report smoke for the new sample;
- RAM-guarded generated IAL1/IAL0 smoke for the new sample; and
- RAM-guarded `t/248-regression-corpus-accounting.t`.

RAM-guarded filtered `t/1438`, direct strict check JSON, and direct HDL
generation attempts stopped when host memory reached the 88% RAM-guard
cutoff. No unguarded retry or cutoff increase was used.

## Rollback

Rollback removes the depth-3 dynamic issue-order queue read-data coverage
admission, the public PPIF sample, support-accounting entry, focused tests,
this behavior record, and live docs/Knowledge Map/task-tree updates. Existing
two-transaction dynamic queue read-data and the `.488` depth-3 RLAST queue
remain unchanged.
