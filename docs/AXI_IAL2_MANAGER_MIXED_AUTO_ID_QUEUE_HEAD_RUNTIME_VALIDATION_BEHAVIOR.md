# AXI IAL2 Manager Mixed Auto-ID Queue-Head Runtime-Validation Behavior

Status: shipped by `IAL2-FEATURE-COMPLETENESS-FRONTIER.202` on
2026-06-21.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.202`

## Public Sample

The runnable PPIF sample is:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_burst_length_runtime_assertion.ppif
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_burst_length_runtime_assertion.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_burst_length_runtime_assertion.ppif
./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_read_burst_last_mixed_auto_id_same_id_queue_head_burst_length_runtime_assertion.sv ppif/axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_burst_length_runtime_assertion.ppif
```

The sample is the `.200` report-only mixed burst-length shape with only the
burst-length validation mode changed to runtime assertions:

```lisp
(burst-length
  (source arlen)
  (signal axi0_arlen (width 8))
  (encoding axlen-plus-one)
  (capture request)
  (max-beats 16)
  (validation runtime-assertion))
```

The covered transaction shape remains exact:

- `r0` is one read transaction with auto-ID allocation from pool `0, 1`;
- `r1` and `r2` are concrete read transactions with ID value `3`;
- `r1`/`r2` use one depth-2 same-ID issue-order queue;
- response demux is read `burst-last` with one-bit `axi0_rlast`;
- read-data capture is scalar last-beat `RDATA`/`RRESP`.

## Generated Behavior

Generation now accepts generated runtime beat-count/`RLAST` validation for
that exact same-family mixed auto-ID plus concrete queue-head read burst-last
shape. For covered transactions `r0`, `r1`, and `r2`, the generated contract
emits:

- generated input `axi0_arlen` with width 8;
- raw `ARLEN` storage `axi0_r0_arlen_q`, `axi0_r1_arlen_q`, and
  `axi0_r2_arlen_q`;
- request-guarded burst-length capture rules
  `axi0_r0_burst_length_capture`, `axi0_r1_burst_length_capture`, and
  `axi0_r2_burst_length_capture`;
- expected-beat storage `axi0_r0_expected_beats_q`,
  `axi0_r1_expected_beats_q`, and `axi0_r2_expected_beats_q`;
- read-beat counters `axi0_r0_read_beat_count_q`,
  `axi0_r1_read_beat_count_q`, and `axi0_r2_read_beat_count_q`;
- request-time beat-count initialization rules and matched-read-beat counter
  increment rules for every covered transaction;
- four beat-count/`RLAST` assertions per covered transaction, for twelve
  generated assertions total.

The generated `r2` matched-beat counter increments on the raw matched
queue-head read beat, without `RLAST` qualification:

```lisp
(rule axi0_r2_read_beat_count
  (& (& axi0_read_complete
        (& (== axi0_rid 4'd3)
           axi0_read_id3_same_id_issue_order_slot0_r2_q))
     (! axi0_r2_request))
  (axi0_r2_read_beat_count_q (+ axi0_r2_read_beat_count_q 5'd1)))
```

The generated `r2` expected-beat initialization is:

```lisp
(rule axi0_r2_beat_count_init axi0_r2_request
  (axi0_r2_expected_beats_q (+ axi0_arlen[4:0] 5'd1))
  (axi0_r2_read_beat_count_q 0))
```

The scalar last-beat `RDATA`/`RRESP` capture remains unchanged and still uses
the combined generated completion
`generated_mixed_auto_id_queue_head_response_demux_last_beat_completion_pulse`.

## Report Contract

The schedule report marks:

```text
read_data.read.burst_length_validation:
  runtime_assertion
read_data.read.beat_count_validation_generated_behavior:
  true
read_data.read.expected_beat_count_encoding:
  arlen_plus_one
read_data.read.beat_count_match_source:
  response_demux_matched_read_beat
read_data.read.generated_expected_beat_count_storage:
  axi0_r0_expected_beats_q
  axi0_r1_expected_beats_q
  axi0_r2_expected_beats_q
read_data.read.generated_beat_count_storage:
  axi0_r0_read_beat_count_q
  axi0_r1_read_beat_count_q
  axi0_r2_read_beat_count_q
read_data.read.generated_beat_count_rules:
  axi0_r0_beat_count_init
  axi0_r0_read_beat_count
  axi0_r1_beat_count_init
  axi0_r1_read_beat_count
  axi0_r2_beat_count_init
  axi0_r2_read_beat_count
read_data.read.generated_beat_count_assertions:
  12 entries
read_data.residue:
  multi_beat_read_data_reassembly
  per_beat_outputs
  rresp_aggregation
```

The `generated_beat_count_validation` residue is removed for this runtime
sample. The `.200` report-only sample remains support-accounted separately
and still keeps that residue.

The public runtime sample is support-accounted as:

```text
intent.ppif_axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_burst_length_runtime_assertion
ial2_ppif_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_burst_length_runtime_assertion_pipeline_cli
```

Strict check JSON and normalized semantic JSON report that entry, the
`supported_smoke` classification, strict support, and generated module
`axi0_capacity_status`.

## Preservation

This slice preserves:

- `.200` report-only mixed raw-`ARLEN` burst-length behavior and support
  identity;
- `.197` mixed scalar read-data behavior;
- `.194` mixed response-demux-only behavior;
- adjacent concrete queue-head report-only burst-length, runtime-validation,
  and multi-beat output-bank behavior;
- existing PPIF burst-length syntax;
- the `IAL2 -> IAL1 -> IAL0 -> SystemVerilog` lowering path.

## Deferred Work

The following remain outside this slice:

- mixed multi-beat output-bank behavior;
- single-beat burst-length behavior;
- group-local simultaneous enqueue widening;
- write-family read-data behavior;
- packed burst-vector outputs or alternate full burst payload assembly;
- direct backend, verification-output generation, VHDL, or backend-language
  variants.
