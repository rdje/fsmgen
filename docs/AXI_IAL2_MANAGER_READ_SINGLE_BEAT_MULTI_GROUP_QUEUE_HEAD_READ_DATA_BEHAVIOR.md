# AXI IAL2 Manager Read Single-Beat Multi-Group Queue-Head Read-Data Behavior

Status: shipped by `IAL2-FEATURE-COMPLETENESS-FRONTIER.146` on
2026-06-16.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.146`

## Public Sample

The runnable PPIF sample is:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_single_beat_multi_group_same_id_queue_head_read_data.ppif
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_read_single_beat_multi_group_same_id_queue_head_read_data.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_single_beat_multi_group_same_id_queue_head_read_data.ppif
./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_read_single_beat_multi_group_same_id_queue_head_read_data.sv ppif/axi_manager_capacity_status_read_single_beat_multi_group_same_id_queue_head_read_data.ppif
```

The sample extends the generated read single-beat multi-group queue-head
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
    (transaction r0
      (data-output axi0_r0_rdata)
      (status-output axi0_r0_rresp))
    (transaction r1
      (data-output axi0_r1_rdata)
      (status-output axi0_r1_rresp))
    (transaction r2
      (data-output axi0_r2_rdata)
      (status-output axi0_r2_rresp))
    (transaction r3
      (data-output axi0_r3_rdata)
      (status-output axi0_r3_rresp))))
```

It has two duplicate concrete read-ID groups:

- `r0` and `r1` share concrete `RID` `3`;
- `r2` and `r3` share concrete `RID` `5`.

There is no `last-signal`, `RLAST`, `burst_length`, last-beat capture, or
multi-beat output bank in this single-beat sample.

## Generated Behavior

FSMGen now accepts generated single-beat queue-head read-data capture for one
or more independent duplicate concrete read-ID groups when every generated
group has exactly two read transactions and computed depth `2`.

For each covered transaction, generation emits:

- generated `axi0_rdata` and `axi0_rresp` inputs;
- scalar per-transaction `RDATA`/`RRESP` outputs;
- read-data capture rules guarded by generated queue-head completion pulses;
- SystemVerilog capture enables driven by the generated completion signal;
- no `RLAST`, `ARLEN`, beat-count, or per-beat output-bank state.

The generated rule for `r3` is:

```lisp
(rule axi0_r3_read_data_capture axi0_r3_complete
  (axi0_r3_rdata axi0_rdata)
  (axi0_r3_rresp axi0_rresp))
```

The matching queue-head response-demux guard for `r3` remains:

```lisp
(rule axi0_r3_response_demux
  (& axi0_read_complete (== axi0_rid 4'd5)
     axi0_read_id5_same_id_issue_order_slot0_r3_q)
  (pulse axi0_r3_complete))
```

The schedule report marks:

```text
response_demux.read.generated_queue_behavior_boundary:
  generated_read_single_beat_queue_head_demux
response_demux.read.generated_completion_signals:
  axi0_r0_complete
  axi0_r1_complete
  axi0_r2_complete
  axi0_r3_complete
read_data.read.completion_validity:
  generated_queue_head_response_demux_completion_pulse
read_data.read.generated_inputs:
  axi0_rdata
  axi0_rresp
read_data.read.generated_rules:
  axi0_r0_read_data_capture
  axi0_r1_read_data_capture
  axi0_r2_read_data_capture
  axi0_r3_read_data_capture
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
- one or more duplicate concrete read-ID groups;
- exactly two read transactions per covered group;
- computed queue depth `2`;
- selected `same-id-ordering.read concrete-id-reuse issue-order-queue`;
- scalar single-beat `RDATA`/`RRESP` capture bindings for every covered
  queue-head transaction;
- completion validity
  `generated_queue_head_response_demux_completion_pulse`;
- no same-family `auto-id-lifecycle` demux;
- no `RLAST`, `burst_length`, last-beat widening, multi-beat widening, packed
  outputs, direct backend, or VHDL.

The family-wide admitted-request onehot boundary is preserved. This slice does
not claim group-local simultaneous same-cycle enqueue support for different
concrete read IDs.

## Support Accounting And Semantic Introspection

The public sample is support-accounted as:

```text
intent.ppif_axi_manager_capacity_status_read_single_beat_multi_group_same_id_queue_head_read_data
```

Strict check JSON and normalized semantic JSON report that entry, the
`supported_smoke` classification, the coverage bucket
`ial2_ppif_manager_capacity_status_read_single_beat_multi_group_same_id_queue_head_read_data_pipeline_cli`,
and the generated module name `axi0_capacity_status`.

## Preserved Behavior

The existing read single-beat response-demux-only multi-group sample remains
generated without `read_data`. The one-group single-beat queue-head read-data
sample remains generated with the same completion validity. Read burst-last
multi-group queue-head scalar, raw-`ARLEN`, runtime-validation, and multi-beat
read-data samples remain within their previous boundaries. Write-family
multi-group queue-head response-demux is unchanged.

## Deferred Work

The following remain outside this slice:

- queue depths greater than two slots;
- same-family mixed auto-ID plus concrete queue-head response demux;
- group-local simultaneous same-cycle enqueue widening;
- packed burst-vector outputs and alternate payload assembly;
- direct backend lowering;
- VHDL.
