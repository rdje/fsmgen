# AXI IAL2 Manager Read Burst-Last Depth-3 Queue-Head Burst-Length Behavior

Status: shipped by `IAL2-FEATURE-COMPLETENESS-FRONTIER.162` on
2026-06-17.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.162`

## Public Sample

The runnable PPIF sample is:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_burst_length.ppif
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_burst_length.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_burst_length.ppif
./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_read_burst_last_depth3_same_id_queue_head_burst_length.sv ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_burst_length.ppif
```

The sample extends the generated read burst-last depth-3 queue-head read-data
shape with report-only raw-`ARLEN` burst-length metadata:

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
      (validation report-only))
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

FSMGen now accepts generated report-only raw-`ARLEN` burst-length capture for
exactly one read burst-last duplicate concrete read-ID group when that group
has three read transactions and computed depth `3`.

For each covered transaction, generation emits:

- generated `axi0_rid`, `axi0_rlast`, `axi0_rdata`, `axi0_rresp`, and
  `axi0_arlen` inputs;
- the generated read burst-last queue-head response-demux boundary
  `generated_read_burst_last_queue_head_demux`;
- generated last-beat completion pulses for `r0`, `r1`, and `r2`;
- scalar per-transaction last-beat `RDATA`/`RRESP` outputs;
- per-transaction raw-`ARLEN` storage:
  `axi0_r0_arlen_q`, `axi0_r1_arlen_q`, and `axi0_r2_arlen_q`;
- request-guarded burst-length capture rules:
  `axi0_r0_burst_length_capture`, `axi0_r1_burst_length_capture`, and
  `axi0_r2_burst_length_capture`;
- read-data capture rules guarded by generated queue-head last-beat
  completion pulses;
- SystemVerilog capture enables driven by each transaction request for
  raw-`ARLEN` capture and by the generated completion signal for scalar
  read-data capture;
- no expected-beat storage, matched-beat counters, or beat-count/`RLAST`
  runtime assertions.

The generated raw-`ARLEN` capture rule for `r2` is:

```lisp
(rule axi0_r2_burst_length_capture axi0_r2_request
  (axi0_r2_arlen_q axi0_arlen))
```

The generated scalar read-data rule for `r2` remains:

```lisp
(rule axi0_r2_read_data_capture axi0_r2_complete
  (axi0_r2_last_rdata axi0_rdata)
  (axi0_r2_last_rresp axi0_rresp))
```

The matching queue-head response-demux guard for `r2` remains:

```lisp
(rule axi0_r2_response_demux
  (& axi0_read_complete (== axi0_rid 4'd3) axi0_rlast
     axi0_read_id3_same_id_issue_order_slot0_r2_q)
  (pulse axi0_r2_complete))
```

## Report Contract

The schedule report marks:

```text
response_demux.read.generated_queue_behavior_boundary:
  generated_read_burst_last_queue_head_demux
response_demux.read.same_id_issue_order_queues:
  - concrete_id: 3
    transactions: [r0, r1, r2]
    depth: 3
read_data.read.completion_validity:
  generated_queue_head_response_demux_last_beat_completion_pulse
read_data.read.burst_length_source:
  arlen_signal
read_data.read.burst_length_signal:
  axi0_arlen
read_data.read.burst_length_signal_direction:
  generated_input
read_data.read.burst_length_signal_width:
  8
read_data.read.burst_length_encoding:
  axlen_plus_one
read_data.read.burst_length_capture:
  transaction_request
read_data.read.burst_length_validation:
  report_only
read_data.read.burst_length_generated_behavior:
  true
read_data.read.generated_inputs:
  axi0_rdata
  axi0_rresp
  axi0_arlen
read_data.read.generated_burst_length_storage:
  axi0_r0_arlen_q
  axi0_r1_arlen_q
  axi0_r2_arlen_q
read_data.read.generated_burst_length_rules:
  axi0_r0_burst_length_capture
  axi0_r1_burst_length_capture
  axi0_r2_burst_length_capture
read_data.residue:
  generated_beat_count_validation
  multi_beat_read_data_reassembly
  per_beat_outputs
  rresp_aggregation
```

`validation report-only` records and preserves the raw `ARLEN` value for
introspection and downstream review. It intentionally does not validate the
observed number of read beats against `ARLEN`; runtime validation remains a
separate owner.

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
  `validation report-only`;
- completion validity
  `generated_queue_head_response_demux_last_beat_completion_pulse`;
- no same-family `auto-id-lifecycle` demux.

The existing depth-2 burst-last queue-head report-only and runtime-validation
boundaries remain unchanged. This slice does not allow runtime validation or
multi-beat output-bank behavior over read burst-last depth-3 queue-head
read-data, multiple depth-3 groups, or mixed depth-2/depth-3 generated
read-data groups.

## Support Accounting And Semantic Introspection

The public sample is support-accounted as:

```text
intent.ppif_axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_burst_length
```

Strict check JSON and normalized semantic JSON report that entry, the
`supported_smoke` classification, the coverage bucket
`ial2_ppif_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_burst_length_pipeline_cli`,
and the generated module name `axi0_capacity_status`.

## Preserved Behavior

The no-`burst_length` depth-3 read-data sample remains generated without
`axi0_arlen`. The depth-3 response-demux-only sample remains generated without
`read_data`. The depth-3 single-beat read-data sibling remains generated
without `RLAST`. Depth-2 burst-last queue-head read-data, report-only
burst-length, runtime-validation, multi-beat output-bank, multi-group
report-only burst-length, read single-beat one-group and multi-group
read-data, and write-family queue-head response-demux samples remain within
their existing boundaries.

## Deferred Work

The following remain outside this slice:

- runtime beat-count/`RLAST` validation over read burst-last depth-3
  queue-head read-data;
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

Focused validation for `.162` included syntax checks for the touched Perl
module and tests, direct schedule/check/semantic/HDL probes for the new public
sample, regression-corpus accounting, focused generator regression, focused
PPIF/parser/CLI regression, supported-corpus path/check/semantic gates, and
final mdBook, Knowledge Map, memory
architecture, docs-path, README numbering, and diff-hygiene gates. The final
task-tree entry records the exact command list and results.
