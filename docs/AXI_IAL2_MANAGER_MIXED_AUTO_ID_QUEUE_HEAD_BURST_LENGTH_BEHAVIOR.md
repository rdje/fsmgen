# AXI IAL2 Manager Mixed Auto-ID Queue-Head Burst-Length Behavior

Status: shipped by `IAL2-FEATURE-COMPLETENESS-FRONTIER.200` on
2026-06-21.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.200`

## Public Sample

The runnable PPIF sample is:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_burst_length.ppif
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_burst_length.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_burst_length.ppif
./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_read_burst_last_mixed_auto_id_same_id_queue_head_burst_length.sv ppif/axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_burst_length.ppif
```

The sample extends the `.197` mixed read burst-last scalar read-data shape with
existing report-only raw-`ARLEN` burst-length metadata:

```lisp
(burst-length
  (source arlen)
  (signal axi0_arlen (width 8))
  (encoding axlen-plus-one)
  (capture request)
  (max-beats 16)
  (validation report-only))
```

The transaction shape is unchanged from the mixed read-data sample:

- `r0` is a read transaction with auto-ID allocation from pool `0, 1`;
- `r1` and `r2` are concrete read transactions with ID value `3`;
- `r1`/`r2` use a depth-2 same-ID issue-order queue;
- response demux is read `burst-last` with one-bit `axi0_rlast`;
- read-data capture is scalar last-beat `RDATA`/`RRESP`.

## Generated Behavior

Generation now accepts report-only raw-`ARLEN` capture for that exact mixed
auto-ID plus concrete queue-head read burst-last shape. For covered
transactions `r0`, `r1`, and `r2`, the generated contract emits:

- generated inputs `axi0_rdata`, `axi0_rresp`, `axi0_arlen`, `axi0_rid`, and
  `axi0_rlast`;
- generated request-ID output `axi0_arid` for the auto-ID transaction;
- mixed completion validity
  `generated_mixed_auto_id_queue_head_response_demux_last_beat_completion_pulse`;
- per-transaction scalar last-beat `RDATA`/`RRESP` outputs;
- per-transaction raw-`ARLEN` storage:
  `axi0_r0_arlen_q`, `axi0_r1_arlen_q`, and `axi0_r2_arlen_q`;
- request-guarded burst-length capture rules:
  `axi0_r0_burst_length_capture`, `axi0_r1_burst_length_capture`, and
  `axi0_r2_burst_length_capture`;
- no expected-beat storage, matched-beat counters, or beat-count/`RLAST`
  runtime assertions.

The generated `r2` raw-`ARLEN` capture rule is:

```lisp
(rule axi0_r2_burst_length_capture axi0_r2_request
  (axi0_r2_arlen_q axi0_arlen))
```

The generated `r2` scalar read-data rule remains:

```lisp
(rule axi0_r2_read_data_capture axi0_r2_complete
  (axi0_r2_last_rdata axi0_rdata)
  (axi0_r2_last_rresp axi0_rresp))
```

## Report Contract

The schedule report marks:

```text
response_demux.read.transaction_completion_source:
  generated_demux_and_queue_head_demux
response_demux.read.generated_queue_behavior_boundary:
  generated_read_burst_last_queue_head_demux
read_data.read.completion_validity:
  generated_mixed_auto_id_queue_head_response_demux_last_beat_completion_pulse
read_data.read.burst_length_source:
  arlen_signal
read_data.read.burst_length_signal:
  axi0_arlen
read_data.read.burst_length_validation:
  report_only
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

The public sample is support-accounted as:

```text
intent.ppif_axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_burst_length
ial2_ppif_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_burst_length_pipeline_cli
```

Strict check JSON and normalized semantic JSON report that entry, the
`supported_smoke` classification, and generated module `axi0_capacity_status`.

## Runtime Boundary

Runtime beat-count/`RLAST` validation over this mixed auto-ID plus concrete
queue-head shape remains separately owned. A PPIF that changes only this
sample's burst-length validation mode to `runtime-assertion` now fails closed
with a diagnostic naming the separately owned boundary.

Existing concrete queue-head runtime-validation samples remain supported. This
fail-closed guard is limited to the same-family mixed auto-ID plus concrete
queue-head response-demux shape.

## Deferred Work

The following remain outside this slice:

- mixed runtime beat-count/`RLAST` validation;
- mixed multi-beat output-bank behavior;
- single-beat burst-length behavior;
- group-local simultaneous enqueue widening;
- write-family read-data behavior;
- packed burst-vector outputs or alternate full burst payload assembly;
- direct backend, verification-output generation, VHDL, or backend-language
  variants.
