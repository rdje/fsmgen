# AXI IAL2 Manager Dynamic Read Burst-Last Depth-3 Same-ID Issue-Order Queue Read-Data Burst-Length Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.494`

Date: 2026-06-25

## Behavior

`IAL2-FEATURE-COMPLETENESS-FRONTIER.494` ships report-only raw-`ARLEN`
burst-length capture over the generated all-dynamic read burst-last
`RID && RLAST` same-ID `issue-order-queue` depth-3 scalar last-beat
read-data behavior shipped in `.491`.

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
read-data.read.burst-length.source: arlen
read-data.read.burst-length.signal: axi0_arlen, width 8
read-data.read.burst-length.encoding: axlen-plus-one
read-data.read.burst-length.capture: request
read-data.read.burst-length.max-beats: 16
read-data.read.burst-length.validation: report-only
queue depth: 3
```

The public support-accounted sample is:

```text
ppif/axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data_burst_length.ppif
```

It registers as:

```text
intent.ppif_axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data_burst_length
ial2_ppif_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data_burst_length_pipeline_cli
```

## Generated Capture

FSMGen keeps the queue-owned `RID && RLAST` completion source and the scalar
last-beat payload capture rules from `.491`:

```text
axi0_r0_read_data_capture: axi0_r0_complete -> axi0_r0_last_rdata, axi0_r0_last_rresp
axi0_r1_read_data_capture: axi0_r1_complete -> axi0_r1_last_rdata, axi0_r1_last_rresp
axi0_r2_read_data_capture: axi0_r2_complete -> axi0_r2_last_rdata, axi0_r2_last_rresp
```

The new behavior adds request-time raw-`ARLEN` storage and capture for all
three dynamic read transactions:

```text
axi0_r0_arlen_q: width 8
axi0_r1_arlen_q: width 8
axi0_r2_arlen_q: width 8
axi0_r0_burst_length_capture: axi0_r0_request -> axi0_r0_arlen_q = axi0_arlen
axi0_r1_burst_length_capture: axi0_r1_request -> axi0_r1_arlen_q = axi0_arlen
axi0_r2_burst_length_capture: axi0_r2_request -> axi0_r2_arlen_q = axi0_arlen
```

The representative `r2` generated IAL1 rule is:

```text
(rule axi0_r2_burst_length_capture axi0_r2_request
  (axi0_r2_arlen_q axi0_arlen))
```

Because validation is report-only, this slice does not generate
`expected_beats` storage, `read_beat_count` storage, runtime `RLAST`
assertions, multi-beat output banks, or RRESP aggregation.

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

The read-data report adds report-only raw-`ARLEN` metadata to the existing
scalar last-beat contract:

```text
mode: bounded_last_beat_read_data_contract
generated_behavior: true
capture_scope: last_beat
completion_source: response_demux
completion_validity: generated_dynamic_read_issue_order_queue_response_demux_last_beat_completion_pulse
burst_length_source: arlen_signal
burst_length_signal: axi0_arlen
burst_length_signal_direction: generated_input
burst_length_signal_width: 8
burst_length_encoding: axlen_plus_one
burst_length_capture: transaction_request
burst_length_validation: report_only
generated_burst_length_inputs: [axi0_arlen]
generated_burst_length_storage: [axi0_r0_arlen_q, axi0_r1_arlen_q, axi0_r2_arlen_q]
generated_burst_length_rules: [axi0_r0_burst_length_capture, axi0_r1_burst_length_capture, axi0_r2_burst_length_capture]
transactions: [r0, r1, r2]
```

Report-only residue remains explicit for runtime validation and broader
read-data behavior:

```text
generated_beat_count_validation
multi_beat_read_data_reassembly
per_beat_outputs
rresp_aggregation
```

## Preserved Behavior

The existing two-transaction dynamic issue-order queue raw-`ARLEN`,
runtime beat-count/`RLAST` validation, and multi-beat output-bank shapes
remain unchanged. The `.491` depth-3 scalar read-data sample without
`burst-length` metadata remains supported and unchanged.

Runtime validation over this depth-3 queue, multi-beat output banks over this
depth-3 queue, mixed dynamic/static queues, scoreboards, arbitrary queue
cardinality, direct backend behavior, backend-language variants, external
converter dependencies such as `sv2v`, and VHDL remain deferred. FSMGen-owned
generation/lowering remains the default.

## Validation

Passed:

- syntax checks for `AxiManagerCapacityStatus.pm`, `RegressionCorpus.pm`,
  `t/1436`, `t/1437`, `t/1438`, and `t/248`;
- RAM-guarded schedule JSON for the new PPIF sample;
- RAM-guarded adapter/report/generated IAL1/generated IAL0 probe for the new
  PPIF sample; and
- `t/248-regression-corpus-accounting.t`.

RAM-guarded full `t/1436`, full `t/1437`, filtered `t/1438`, and strict check
JSON attempts stopped when host memory reached the 88% RAM-guard cutoff. No
unguarded retry or cutoff increase was used.

## Rollback

Rollback removes the depth-3 dynamic issue-order queue report-only
`burst_length` coverage admission, the public PPIF sample, support-accounting
entry, focused parser/generator/dynamic/support-accounting tests, this
behavior record, and live docs/Knowledge Map/task-tree updates. Existing
two-transaction dynamic queue raw-`ARLEN` behavior and the `.491` depth-3
queue scalar read-data behavior remain independent.
