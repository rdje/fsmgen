# AXI IAL2 Manager Read Burst-Last Depth-3 Queue-Head Runtime-Validation Behavior

Status: shipped by `IAL2-FEATURE-COMPLETENESS-FRONTIER.165` on
2026-06-17.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.165`

## Public Sample

The runnable PPIF sample is:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_burst_length_runtime_assertion.ppif
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_burst_length_runtime_assertion.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_burst_length_runtime_assertion.ppif
./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_read_burst_last_depth3_same_id_queue_head_burst_length_runtime_assertion.sv ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_burst_length_runtime_assertion.ppif
```

The sample extends the report-only depth-3 raw-`ARLEN` shape by changing only
the `burst-length` validation mode:

```lisp
(read-data
  (read
    (capture-scope last-beat)
    (completion-source response-demux)
    (data-signal axi0_rdata (width 32))
    (status-signal axi0_rresp (width 2))
    (status-policy last-beat)
    (interleaving last-beat-by-rid)
    (burst-length
      (source arlen)
      (signal axi0_arlen (width 8))
      (encoding axlen-plus-one)
      (capture request)
      (max-beats 16)
      (validation runtime-assertion))
    (transaction r0
      (data-output axi0_r0_last_rdata)
      (status-output axi0_r0_last_rresp))
    (transaction r1
      (data-output axi0_r1_last_rdata)
      (status-output axi0_r1_last_rresp))
    (transaction r2
      (data-output axi0_r2_last_rdata)
      (status-output axi0_r2_last_rresp))))
```

It has one duplicate concrete read-ID group: `r0`, `r1`, and `r2` share
concrete `RID` `3`. The computed read queue depth is `3`.

## Generated Behavior

FSMGen now accepts generated beat-count/`RLAST` runtime validation for exactly
one read burst-last duplicate concrete read-ID group when that group has three
read transactions and computed depth `3`.

For each covered transaction, generation emits:

- generated `axi0_rid`, `axi0_rlast`, `axi0_rdata`, `axi0_rresp`, and
  `axi0_arlen` inputs;
- the generated read burst-last queue-head response-demux boundary
  `generated_read_burst_last_queue_head_demux`;
- generated last-beat completion pulses for `r0`, `r1`, and `r2`;
- scalar per-transaction last-beat `RDATA`/`RRESP` outputs;
- per-transaction raw-`ARLEN` storage:
  `axi0_r0_arlen_q`, `axi0_r1_arlen_q`, and `axi0_r2_arlen_q`;
- per-transaction expected-beat storage:
  `axi0_r0_expected_beats_q`, `axi0_r1_expected_beats_q`, and
  `axi0_r2_expected_beats_q`;
- per-transaction read-beat counters:
  `axi0_r0_read_beat_count_q`, `axi0_r1_read_beat_count_q`, and
  `axi0_r2_read_beat_count_q`;
- request-time expected-beat/counter initialization rules:
  `axi0_r0_beat_count_init`, `axi0_r1_beat_count_init`, and
  `axi0_r2_beat_count_init`;
- raw matched read-beat counter increment rules:
  `axi0_r0_read_beat_count`, `axi0_r1_read_beat_count`, and
  `axi0_r2_read_beat_count`;
- four beat-count/`RLAST` assertions per transaction:
  request-time `ARLEN` bound, extra beat beyond expected count, early
  `RLAST`, and missing `RLAST` on the expected final beat.

The generated `r2` request path is:

```lisp
(rule axi0_r2_burst_length_capture axi0_r2_request
  (axi0_r2_arlen_q axi0_arlen))

(rule axi0_r2_beat_count_init axi0_r2_request
  (axi0_r2_expected_beats_q (+ axi0_arlen[4:0] 5'd1))
  (axi0_r2_read_beat_count_q 0))
```

The generated `r2` read-beat counter increments on the raw queue-head match,
not on the `RLAST`-qualified completion pulse:

```lisp
(rule axi0_r2_read_beat_count
  (& (& axi0_read_complete
        (& (== axi0_rid 4'd3)
           axi0_read_id3_same_id_issue_order_slot0_r2_q))
     (! axi0_r2_request))
  (axi0_r2_read_beat_count_q (+ axi0_r2_read_beat_count_q 5'd1)))
```

The scalar last-beat capture remains guarded by the generated completion pulse:

```lisp
(rule axi0_r2_read_data_capture axi0_r2_complete
  (axi0_r2_last_rdata axi0_rdata)
  (axi0_r2_last_rresp axi0_rresp))
```

## Report Contract

Schedule JSON marks:

```text
response_demux.read.generated_queue_behavior_boundary:
  generated_read_burst_last_queue_head_demux
response_demux.read.same_id_issue_order_queues:
  - concrete_id: 3
    transactions: [r0, r1, r2]
    depth: 3
read_data.read.completion_validity:
  generated_queue_head_response_demux_last_beat_completion_pulse
read_data.read.burst_length_validation:
  runtime_assertion
read_data.read.burst_length_generated_behavior:
  true
read_data.read.beat_count_validation_generated_behavior:
  true
read_data.read.expected_beat_count_encoding:
  arlen_plus_one
read_data.read.beat_count_match_source:
  response_demux_matched_read_beat
read_data.read.beat_count_width:
  5
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
  axi0_r0_arlen_within_max
  axi0_r0_read_beat_before_expected_count
  axi0_r0_rlast_on_expected_beat
  axi0_r0_expected_final_beat_has_rlast
  axi0_r1_arlen_within_max
  axi0_r1_read_beat_before_expected_count
  axi0_r1_rlast_on_expected_beat
  axi0_r1_expected_final_beat_has_rlast
  axi0_r2_arlen_within_max
  axi0_r2_read_beat_before_expected_count
  axi0_r2_rlast_on_expected_beat
  axi0_r2_expected_final_beat_has_rlast
read_data.residue:
  multi_beat_read_data_reassembly
  per_beat_outputs
  rresp_aggregation
```

`generated_beat_count_validation` is removed from `read_data.residue` only for
this bounded runtime-validation sample.

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
- `read-data.read.capture-scope last-beat`;
- `completion-source response-demux`;
- `status-policy last-beat`;
- `interleaving last-beat-by-rid`;
- scalar last-beat `RDATA`/`RRESP` capture bindings for every covered
  queue-head transaction;
- `burst-length` metadata with `source arlen`, `signal` width `8`,
  `encoding axlen-plus-one`, `capture request`, `max-beats 16`, and
  `validation runtime-assertion`;
- completion validity
  `generated_queue_head_response_demux_last_beat_completion_pulse`;
- no same-family `auto-id-lifecycle` demux.

## Support Accounting And Semantic Introspection

The public sample is support-accounted as:

```text
intent.ppif_axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_burst_length_runtime_assertion
```

Strict check JSON and normalized semantic JSON report that entry, the
`supported_smoke` classification, the coverage bucket
`ial2_ppif_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_burst_length_runtime_assertion_pipeline_cli`,
and the generated module name `axi0_capacity_status`.

## Preserved Behavior

The report-only depth-3 burst-length sample still captures raw `ARLEN` without
expected-beat storage, read-beat counters, or runtime assertions. The
no-`burst_length` depth-3 read-data sample remains generated without
`axi0_arlen`. The depth-3 response-demux-only sample remains generated without
`read_data`. Depth-2 one-group and multi-group runtime-validation samples,
multi-beat queue-head read-data samples, read single-beat depth-3 samples,
and write-family queue-head response-demux samples keep their existing
boundaries.

## Deferred Work

The following remain outside this slice:

- multi-beat output-bank behavior over read burst-last depth-3 queue-head
  read-data;
- write depth-3 response-demux;
- multiple independent depth-3 groups in one manager object;
- mixed depth-2/depth-3 generated groups;
- same-family mixed auto-ID plus concrete queue-head response demux;
- group-local simultaneous same-cycle enqueue widening beyond the current
  family-wide one-admitted-request boundary;
- packed burst-vector outputs and alternate payload assembly;
- direct backend lowering;
- VHDL.

## Validation

Focused validation for `.165` includes syntax checks for the touched Perl
module and tests, direct schedule/check/semantic/HDL probes for the new public
sample, regression-corpus accounting, focused generator regression, focused
PPIF/parser/CLI regression, supported-corpus path/check/semantic gates, and
final mdBook, Knowledge Map, memory architecture, docs-path, README
numbering, and diff-hygiene gates. The final task-tree entry records the
exact command list and results.
