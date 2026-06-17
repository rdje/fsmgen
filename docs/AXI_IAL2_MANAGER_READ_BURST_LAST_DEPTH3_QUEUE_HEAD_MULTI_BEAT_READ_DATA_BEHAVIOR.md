# AXI IAL2 Manager Read Burst-Last Depth-3 Queue-Head Multi-Beat Read-Data Behavior

Status: shipped by `IAL2-FEATURE-COMPLETENESS-FRONTIER.168` on
2026-06-17.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.168`

## Public Sample

The runnable PPIF sample is:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_multi_beat_read_data.ppif
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_multi_beat_read_data.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_multi_beat_read_data.ppif
./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_read_burst_last_depth3_same_id_queue_head_multi_beat_read_data.sv ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_multi_beat_read_data.ppif
```

The sample covers exactly one duplicate concrete read-ID group. Transactions
`r0`, `r1`, and `r2` share concrete `RID` `3`, and the computed read queue
depth is `3`.

The `read-data` contract uses:

```lisp
(read-data
  (read
    (capture-scope multi-beat)
    (completion-source response-demux)
    (data-signal axi0_rdata (width 32))
    (status-signal axi0_rresp (width 2))
    (status-policy per-beat)
    (status-aggregation (policy worst-observed))
    (interleaving multi-beat-by-rid)
    (burst-length
      (source arlen)
      (signal axi0_arlen (width 8))
      (encoding axlen-plus-one)
      (capture request)
      (max-beats 16)
      (validation runtime-assertion))
    (transaction r0
      (data-output-prefix axi0_r0_rdata)
      (status-output-prefix axi0_r0_rresp)
      (status-aggregate-output axi0_r0_rresp_agg)
      (valid-mask-output axi0_r0_beat_valid)
      (length-output axi0_r0_read_length))
    (transaction r1
      (data-output-prefix axi0_r1_rdata)
      (status-output-prefix axi0_r1_rresp)
      (status-aggregate-output axi0_r1_rresp_agg)
      (valid-mask-output axi0_r1_beat_valid)
      (length-output axi0_r1_read_length))
    (transaction r2
      (data-output-prefix axi0_r2_rdata)
      (status-output-prefix axi0_r2_rresp)
      (status-aggregate-output axi0_r2_rresp_agg)
      (valid-mask-output axi0_r2_beat_valid)
      (length-output axi0_r2_read_length))))
```

## Generated Behavior

FSMGen now accepts generated multi-beat output-bank read-data behavior for
exactly one read burst-last duplicate concrete read-ID group when that group
has three read transactions, computed depth `3`, and runtime-assertion
`ARLEN` burst-length metadata.

For each covered transaction, generation emits:

- generated `axi0_rid`, `axi0_rlast`, `axi0_rdata`, `axi0_rresp`, and
  `axi0_arlen` inputs;
- the generated read burst-last queue-head response-demux boundary
  `generated_read_burst_last_queue_head_demux`;
- generated last-beat completion pulses for `r0`, `r1`, and `r2`;
- raw `ARLEN` storage and request-time capture rules;
- expected-beat storage, read-beat counters, initialization rules, raw
  matched-read-beat counter rules, and beat-count/`RLAST` assertions;
- sixteen `RDATA` lanes and sixteen `RRESP` lanes per transaction;
- one valid-mask output and one length output per transaction;
- one scalar worst-observed `RRESP` aggregate output per transaction;
- one request-time output-bank clearing rule per transaction;
- forty-eight generated lane-capture rules across `r0`, `r1`, and `r2`;
- three scalar aggregate initialization/update paths.

Lane capture is guarded by the raw matched queue-head read beat and the
transaction's beat-count lane index, not only by the `RLAST` completion pulse.
The final completion pulse still owns generated transaction completion.

## Report Contract

Schedule JSON marks:

```text
response_demux.read.generated_queue_behavior_boundary:
  generated_read_burst_last_queue_head_demux
response_demux.read.same_id_issue_order_queues:
  - concrete_id: 3
    transactions: [r0, r1, r2]
    depth: 3
read_data.mode:
  bounded_multi_beat_read_data_contract
read_data.read.output_shape:
  per_beat_output_bank
read_data.read.completion_validity:
  generated_queue_head_response_demux_last_beat_completion_pulse
read_data.read.burst_length_validation:
  runtime_assertion
read_data.read.beat_count_match_source:
  response_demux_matched_read_beat
read_data.read.generated_multi_beat_capture_rules:
  48 entries
read_data.residue:
  []
response_demux.residue:
  []
```

The supported residue movement is intentionally narrow. For this sample,
`read_data_interleaving` and `bursts` are also removed for the covered
multi-beat-by-RID per-beat output-bank subset. `same_id_ordering` continues to
report the broader per-ID issue-order queue residue that is not part of this
read-data behavior slice.

## Admission Boundary

The generated behavior stays limited to:

- read family only;
- `response-demux.read.response-scope burst-last` only;
- one-bit `last-signal`/`RLAST` metadata;
- generated queue-head response-demux boundary
  `generated_read_burst_last_queue_head_demux`;
- exactly one duplicate concrete read-ID group;
- exactly three read transactions in that group;
- computed queue depth `3`;
- selected `same-id-ordering.read concrete-id-reuse issue-order-queue`;
- `read-data.read.capture-scope multi-beat`;
- `completion-source response-demux`;
- `status-policy per-beat`;
- `status-aggregation (policy worst-observed)`;
- `interleaving multi-beat-by-rid`;
- `burst-length` metadata with `source arlen`, `signal` width `8`,
  `encoding axlen-plus-one`, `capture request`, `max-beats 16`, and
  `validation runtime-assertion`;
- complete per-transaction `data-output-prefix`, `status-output-prefix`,
  `status-aggregate-output`, `valid-mask-output`, and `length-output`
  bindings for `r0`, `r1`, and `r2`;
- no same-family `auto-id-lifecycle` demux.

## Support Accounting And Semantic Introspection

The public sample is support-accounted as:

```text
intent.ppif_axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_multi_beat_read_data
```

Strict check JSON and normalized semantic JSON report that entry, the
`supported_smoke` classification, the coverage bucket
`ial2_ppif_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_multi_beat_read_data_pipeline_cli`,
and the generated module name `axi0_capacity_status`.

## Preserved Behavior

The `.165` runtime-validation scalar last-beat sample remains generated with
runtime beat-count/`RLAST` validation and scalar final `RDATA`/`RRESP`
outputs. The `.162` report-only raw-`ARLEN` sample still reports
`generated_beat_count_validation` residue. The `.159` no-`burst_length`
depth-3 read-data sample remains generated without burst-length metadata.

Depth-2 one-group and multi-group queue-head multi-beat samples remain
generated with their existing output-bank behavior. Write depth-3, multiple or
mixed depth-3 groups, mixed auto-ID plus concrete queue-head demux,
group-local simultaneous enqueue widening, packed burst-vector outputs,
alternate full burst payload assembly, direct backend lowering,
verification-output generation, VHDL, and other backend-language variants
remain deferred behind future owned leaves.

## Verification

The `.168` implementation was checked with focused syntax checks, direct
schedule/check/semantic/verify-HDL probes for the new PPIF sample, focused
generator and PPIF/CLI suites, regression-corpus accounting, supported-corpus
check JSON and normalized semantic JSON gates, Knowledge Map generation/check,
mdBook build, docs relative-path audit, memory-architecture check, diff
hygiene, README numbering, and stale/positive frontier scans.
