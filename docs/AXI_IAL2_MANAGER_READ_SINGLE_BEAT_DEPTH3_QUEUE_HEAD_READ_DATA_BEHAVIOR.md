# AXI IAL2 Manager Read Single-Beat Depth-3 Queue-Head Read-Data Behavior

Status: shipped by `IAL2-FEATURE-COMPLETENESS-FRONTIER.153` on
2026-06-17.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.153`

## Public Sample

The runnable PPIF sample is:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_single_beat_depth3_same_id_queue_head_read_data.ppif
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_read_single_beat_depth3_same_id_queue_head_read_data.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_single_beat_depth3_same_id_queue_head_read_data.ppif
./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_read_single_beat_depth3_same_id_queue_head_read_data.sv ppif/axi_manager_capacity_status_read_single_beat_depth3_same_id_queue_head_read_data.ppif
```

The sample extends the generated read single-beat depth-3 queue-head
response-demux shape with scalar read-data bindings:

```lisp
(response-demux
  (read
    (response-event axi0_read_complete)
    (response-scope single-beat)
    (transaction-completion generated)))
(read-data
  (read
    (capture-scope single-beat)
    (completion-source response-demux)
    (data-signal axi0_rdata (width 32))
    (status-signal axi0_rresp (width 2))
    (interleaving single-beat-by-rid)
    (transaction r0
      (data-output axi0_r0_rdata)
      (status-output axi0_r0_rresp))
    (transaction r1
      (data-output axi0_r1_rdata)
      (status-output axi0_r1_rresp))
    (transaction r2
      (data-output axi0_r2_rdata)
      (status-output axi0_r2_rresp))))
```

It has one duplicate concrete read-ID group: `r0`, `r1`, and `r2` share
concrete `RID` `3`. The computed read queue depth is `3`.

There is no `last-signal`, `RLAST`, `burst_length`, last-beat capture,
multi-beat output bank, packed output vector, or status aggregation in this
single-beat sample.

## Generated Behavior

FSMGen now accepts generated single-beat queue-head read-data capture for
exactly one duplicate concrete read-ID group when that group has three read
transactions and computed depth `3`.

For each covered transaction, generation emits:

- generated `axi0_rdata` and `axi0_rresp` inputs;
- scalar per-transaction `RDATA`/`RRESP` outputs;
- read-data capture rules guarded by generated queue-head completion pulses;
- SystemVerilog capture enables driven by the generated completion signal;
- no `RLAST`, `ARLEN`, beat-count, per-beat output-bank state, or packed
  payload output.

The generated rule for `r2` is:

```lisp
(rule axi0_r2_read_data_capture axi0_r2_complete
  (axi0_r2_rdata axi0_rdata)
  (axi0_r2_rresp axi0_rresp))
```

The matching queue-head response-demux guard for `r2` remains:

```lisp
(rule axi0_r2_response_demux
  (& axi0_read_complete (== axi0_rid 4'd3)
     axi0_read_id3_same_id_issue_order_slot0_r2_q)
  (pulse axi0_r2_complete))
```

The schedule report marks:

```text
response_demux.read.generated_queue_behavior_boundary:
  generated_read_single_beat_queue_head_demux
response_demux.read.same_id_issue_order_queues:
  - concrete_id: 3
    transactions: [r0, r1, r2]
    depth: 3
read_data.read.completion_validity:
  generated_queue_head_response_demux_completion_pulse
read_data.read.generated_inputs:
  axi0_rdata
  axi0_rresp
read_data.read.generated_rules:
  axi0_r0_read_data_capture
  axi0_r1_read_data_capture
  axi0_r2_read_data_capture
read_data.residue:
  rlast_completion
  bursts
  multi_beat_read_data_reassembly
```

## Admission Boundary

The generated behavior stays limited to:

- read family only;
- `response-demux.read.response-scope single-beat` only;
- generated queue-head response-demux boundary
  `generated_read_single_beat_queue_head_demux`;
- exactly one duplicate concrete read-ID group;
- exactly three read transactions in that group;
- computed queue depth `3`;
- selected `same-id-ordering.read concrete-id-reuse issue-order-queue`;
- scalar single-beat `RDATA`/`RRESP` capture bindings for every covered
  queue-head transaction;
- completion validity
  `generated_queue_head_response_demux_completion_pulse`;
- no same-family `auto-id-lifecycle` demux.

The existing depth-2 single-beat queue-head read-data boundary remains
one-or-more independent groups of exactly two read transactions. This slice
does not allow multiple depth-3 groups or mixed depth-2/depth-3 generated
read-data groups.

## Support Accounting And Semantic Introspection

The public sample is support-accounted as:

```text
intent.ppif_axi_manager_capacity_status_read_single_beat_depth3_same_id_queue_head_read_data
```

Strict check JSON and normalized semantic JSON report that entry, the
`supported_smoke` classification, the coverage bucket
`ial2_ppif_manager_capacity_status_read_single_beat_depth3_same_id_queue_head_read_data_pipeline_cli`,
and the generated module name `axi0_capacity_status`.

## Preserved Behavior

The depth-3 response-demux-only sample remains generated without `read_data`.
The depth-2 one-group and multi-group single-beat queue-head read-data samples
remain generated with the same completion validity. Read burst-last queue-head
scalar, raw-`ARLEN`, runtime-validation, and multi-beat read-data samples remain
within their previous depth-2 boundaries. Write-family queue-head
response-demux is unchanged.

## Deferred Work

The following remain outside this slice:

- read burst-last depth-3 response-demux;
- write depth-3 response-demux;
- multiple independent depth-3 groups in one manager object;
- mixed depth-2/depth-3 generated groups;
- same-family mixed auto-ID plus concrete queue-head response demux;
- group-local simultaneous same-cycle enqueue widening beyond the current
  family-wide one-admitted-request boundary;
- packed burst-vector outputs and alternate payload assembly;
- direct backend lowering;
- VHDL.
