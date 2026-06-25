# AXI IAL2 Manager Dynamic Read Burst-Last Depth-3 Same-ID Issue-Order Queue Read-Data Runtime Validation Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.497`

Date: 2026-06-25

## Behavior

`IAL2-FEATURE-COMPLETENESS-FRONTIER.497` ships runtime
beat-count/`RLAST` validation over the generated all-dynamic read burst-last
`RID && RLAST` same-ID `issue-order-queue` depth-3 scalar last-beat
read-data raw-`ARLEN` behavior from `.494`.

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
read-data.read.burst-length.validation: runtime-assertion
queue depth: 3
```

The public support-accounted sample is:

```text
ppif/axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data_burst_length_runtime_assertion.ppif
```

It registers as:

```text
intent.ppif_axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data_burst_length_runtime_assertion
ial2_ppif_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data_burst_length_runtime_assertion_pipeline_cli
```

## Generated Runtime Validation

FSMGen keeps the `.494` queue-owned `RID && RLAST` completion source,
scalar last-beat payload capture, generated `axi0_arlen` input, and
per-transaction raw-`ARLEN` storage/capture rules. Runtime validation adds
expected-beat storage, read-beat counter storage, init/increment rules, and
beat-count/`RLAST` assertions for all three dynamic read transactions:

```text
axi0_r0_expected_beats_q, axi0_r1_expected_beats_q, axi0_r2_expected_beats_q
axi0_r0_read_beat_count_q, axi0_r1_read_beat_count_q, axi0_r2_read_beat_count_q
axi0_r0_beat_count_init, axi0_r0_read_beat_count
axi0_r1_beat_count_init, axi0_r1_read_beat_count
axi0_r2_beat_count_init, axi0_r2_read_beat_count
```

The representative `r2` generated IAL1 initialization rule is:

```text
(rule axi0_r2_beat_count_init axi0_r2_request
  (axi0_r2_expected_beats_q (+ axi0_arlen[4:0] 5'd1))
  (axi0_r2_read_beat_count_q 0))
```

The representative `r2` increment rule counts matched raw read beats from
any of the three queue slots while not also accepting a new `r2` request:

```text
(rule axi0_r2_read_beat_count
  (& (& axi0_read_complete
        <slot0/slot1/slot2 selected r2 match>)
     (! axi0_r2_request))
  (axi0_r2_read_beat_count_q (+ axi0_r2_read_beat_count_q 5'd1)))
```

For each of `r0`, `r1`, and `r2`, FSMGen emits four runtime assertions:

```text
axi0_r*_arlen_within_max
axi0_r*_read_beat_before_expected_count
axi0_r*_rlast_on_expected_beat
axi0_r*_expected_final_beat_has_rlast
```

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

The read-data report now advertises runtime validation:

```text
mode: bounded_last_beat_read_data_contract
generated_behavior: true
capture_scope: last_beat
completion_source: response_demux
completion_validity: generated_dynamic_read_issue_order_queue_response_demux_last_beat_completion_pulse
burst_length_validation: runtime_assertion
beat_count_validation_generated_behavior: true
expected_beat_count_encoding: arlen_plus_one
beat_count_match_source: response_demux_matched_read_beat
beat_count_width: 5
generated_expected_beat_count_storage: [axi0_r0_expected_beats_q, axi0_r1_expected_beats_q, axi0_r2_expected_beats_q]
generated_beat_count_storage: [axi0_r0_read_beat_count_q, axi0_r1_read_beat_count_q, axi0_r2_read_beat_count_q]
generated_beat_count_rules: [axi0_r0_beat_count_init, axi0_r0_read_beat_count, axi0_r1_beat_count_init, axi0_r1_read_beat_count, axi0_r2_beat_count_init, axi0_r2_read_beat_count]
generated_beat_count_assertions: 12 entries, four per transaction
transactions: [r0, r1, r2]
```

Runtime-validation residue removes `generated_beat_count_validation` and keeps
the still-deferred read-data behaviors explicit:

```text
multi_beat_read_data_reassembly
per_beat_outputs
rresp_aggregation
```

## Preserved Behavior

The `.494` report-only depth-3 raw-`ARLEN` sample remains supported and
continues to omit expected-beat storage, read-beat counters, and runtime
`RLAST` assertions. Existing two-transaction dynamic queue raw-`ARLEN`,
runtime-validation, and multi-beat output-bank samples remain unchanged.

Multi-beat output banks over this depth-3 queue, mixed dynamic/static queues,
scoreboards, arbitrary queue cardinality, verification-code generation,
direct backend behavior, backend-language variants, external converter
dependencies such as `sv2v`, and VHDL remain deferred. FSMGen-owned
generation/lowering remains the default.

## Validation

Passed:

- syntax checks for `AxiManagerCapacityStatus.pm`, `RegressionCorpus.pm`,
  `t/1436`, `t/1437`, `t/1438`, and `t/248`;
- RAM-guarded schedule JSON for the new PPIF sample, confirming
  `runtime_assertion`, three expected-beat storage registers, three beat
  counters, six beat-count rules, and twelve beat-count/`RLAST` assertions;
  and
- RAM-guarded `t/248-regression-corpus-accounting.t`.

RAM-guarded full `t/1436` stopped while active when host memory reached the
88% cutoff. RAM-guarded strict check JSON for the new sample also stopped at
the same host-memory cutoff. No unguarded retry or cutoff increase was used.

## Rollback

Rollback removes the depth-3 dynamic issue-order queue runtime-assertion
`burst_length` coverage admission, the public PPIF sample, support-accounting
entry, focused parser/generator/dynamic/support-accounting tests, this
behavior record, and live docs/Knowledge Map/task-tree updates. Existing
two-transaction dynamic queue runtime-validation behavior and the `.494`
depth-3 report-only raw-`ARLEN` behavior remain independent.
