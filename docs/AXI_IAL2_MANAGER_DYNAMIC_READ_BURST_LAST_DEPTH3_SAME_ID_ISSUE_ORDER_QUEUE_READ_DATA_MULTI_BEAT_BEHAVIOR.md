# AXI IAL2 Manager Dynamic Read Burst-Last Depth-3 Same-ID Issue-Order Queue Read-Data Multi-Beat Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.500`

Date: 2026-06-25

## Behavior

`IAL2-FEATURE-COMPLETENESS-FRONTIER.500` ships multi-beat read-data output
banks over the generated all-dynamic read burst-last `RID && RLAST` same-ID
`issue-order-queue` depth-3 runtime-validation read-data behavior from `.497`.

The supported public shape is intentionally exact:

```text
read transactions: r0, r1, r2
all transaction IDs: dynamic
same-id-ordering.read: dynamic-id-reuse issue-order-queue
response-demux.read: response-scope burst-last, generated RID/RLAST completion
response-demux.read.last-signal: axi0_rlast, width 1
read-data.read.capture-scope: multi-beat
read-data.read.completion-source: response-demux
read-data.read.status-policy: per-beat
read-data.read.status-aggregation: worst-observed
read-data.read.interleaving: multi-beat-by-rid
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
ppif/axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data_multi_beat.ppif
```

It registers as:

```text
intent.ppif_axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data_multi_beat
ial2_ppif_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data_multi_beat_pipeline_cli
```

## Generated Output Banks

FSMGen keeps the `.497` queue-owned `RID && RLAST` completion source, raw
`ARLEN` capture, expected-beat storage, read-beat counters, six beat-count
rules, and twelve beat-count/`RLAST` runtime assertions. The multi-beat
output-bank layer adds per-transaction output-bank artifacts for all three
dynamic read transactions:

```text
axi0_r0_beat_rdata_0..15, axi0_r1_beat_rdata_0..15, axi0_r2_beat_rdata_0..15
axi0_r0_beat_rresp_0..15, axi0_r1_beat_rresp_0..15, axi0_r2_beat_rresp_0..15
axi0_r0_beat_valid, axi0_r1_beat_valid, axi0_r2_beat_valid
axi0_r0_read_beats, axi0_r1_read_beats, axi0_r2_read_beats
axi0_r0_rresp, axi0_r1_rresp, axi0_r2_rresp
```

For the default `max-beats 16` sample, the generated IAL1 surface includes 48
`RDATA` lane outputs, 48 `RRESP` lane outputs, three valid-mask outputs,
three length outputs, three scalar aggregate `RRESP` outputs, three output
initialization rules, 48 lane-capture rules, and three scalar aggregate
update rules. Lane captures are driven by matched raw read beats from the
generated response-demux queue, not by a final transaction-only pulse.

The representative final `r2` lane capture is:

```text
(rule axi0_r2_read_beat_15_capture
  (& (& axi0_read_complete
        <slot0/slot1/slot2 selected r2 match>)
     (! axi0_r2_request)
     (== axi0_r2_read_beat_count_q 5'd15))
  (axi0_r2_beat_rdata_15 axi0_rdata)
  (axi0_r2_beat_rresp_15 axi0_rresp)
  (axi0_r2_beat_valid 16'b1111111111111111)
  (axi0_r2_read_beats 5'd16))
```

## Report Surface

The response-demux report remains the `.488` depth-3 queue contract:

```text
mode: bounded_dynamic_read_rid_rlast_issue_order_queue_demux_contract
transaction_completion_source: generated_dynamic_issue_order_queue_demux_last_beat
dynamic_transactions: [r0, r1, r2]
generated_completion_signals: [axi0_r0_complete, axi0_r1_complete, axi0_r2_complete]
first_generated_scope: read_rid_rlast_three_dynamic_transactions
generated_queues[0].depth: 3
```

The read-data report now advertises bounded multi-beat output banks:

```text
mode: bounded_multi_beat_read_data_contract
generated_behavior: true
capture_scope: multi_beat
completion_source: response_demux
completion_validity: generated_dynamic_read_issue_order_queue_response_demux_last_beat_completion_pulse
beat_match_source: response_demux_matched_read_beat
beat_count_match_source: response_demux_matched_read_beat
output_shape: per_beat_output_bank
valid_output: per_transaction_valid_mask
length_output: per_transaction_beat_count
status_aggregation: worst_observed
status_aggregation_generated_behavior: true
multi_beat_reassembly_generated_behavior: true
burst_length_validation: runtime_assertion
generated_multi_beat_valid_outputs: [axi0_r0_beat_valid, axi0_r1_beat_valid, axi0_r2_beat_valid]
generated_multi_beat_length_outputs: [axi0_r0_read_beats, axi0_r1_read_beats, axi0_r2_read_beats]
transactions: [r0, r1, r2]
```

The generated read-data report contains 48 data outputs, 48 status outputs, 48
capture rules, three valid-mask outputs, three length outputs, three scalar
aggregate outputs, three aggregate update rules, and twelve beat-count/`RLAST`
assertions.

## Preserved Behavior

Existing two-transaction dynamic queue raw-`ARLEN`, runtime-validation, and
multi-beat output-bank samples remain unchanged. The `.494` report-only
depth-3 raw-`ARLEN` sample and the `.497` depth-3 scalar runtime-validation
sample remain supported.

Mixed dynamic/static queues, scoreboards, arbitrary queue cardinality,
verification-code generation, direct backend behavior, backend-language
variants, external converter dependencies such as `sv2v`, and VHDL remain
deferred. FSMGen-owned generation/lowering remains the default; `.500` does
not introduce `sv2v` or any other external converter dependency.

## Validation

Passed before closeout:

- syntax checks for `AxiManagerCapacityStatus.pm`, `RegressionCorpus.pm`,
  `t/1436`, `t/1437`, `t/1438`, and `t/248`;
- RAM-guarded schedule JSON for the new PPIF sample, confirming
  `bounded_multi_beat_read_data_contract`, `multi_beat`, generated
  dynamic read issue-order queue completion validity, `r0`/`r1`/`r2`, 48 data
  outputs, 48 status outputs, three valid-mask outputs, three length outputs,
  48 capture rules, and twelve beat-count/`RLAST` assertions; and
- RAM-guarded `t/248-regression-corpus-accounting.t`.

A RAM-guarded full `t/1436` run reached the new assertions, exposed only two
test-expectation mismatches, and then stopped later when host memory reached
the 88% cutoff. The expectations were updated and `t/1436` syntax was
rechecked. A RAM-guarded `t/1438` dynamic-ID focused attempt stopped before
TAP results when host memory reached 88.6% against the 88% cutoff. No
unguarded retry or cutoff increase was used.

## Rollback

Rollback removes the depth-3 dynamic issue-order queue multi-beat
runtime-assertion coverage admission, the public PPIF sample,
support-accounting entry, focused parser/generator/dynamic/support-accounting
tests, this behavior record, and live docs/Knowledge Map/task-tree updates.
Existing two-transaction dynamic queue multi-beat behavior and the `.497`
depth-3 scalar runtime-validation behavior remain independent.
