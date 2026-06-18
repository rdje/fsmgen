# AXI IAL2 Manager Multiple/Mixed Depth-3 Queue-Head Burst-Length Behavior

Task owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.183`

Date: 2026-06-18

## Scope

FSMGen now generates report-only raw-`ARLEN` burst-length capture for read
burst-last queue-head scalar last-beat read-data when the concrete same-ID
queue-head groups have computed depth `2` or `3` and at least one selected
group has depth `3`.

This is the direct implementation selected by
`docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_BURST_LENGTH_READINESS_AUDIT.md`.
It extends the `.180` multiple/mixed depth-3 scalar last-beat read-data shape
only for report-only burst-length metadata:

```text
(burst-length
  (source arlen)
  (signal axi0_arlen (width 8))
  (encoding axlen-plus-one)
  (capture request)
  (max-beats 16)
  (validation report-only))
```

## Public Samples

Two public `.ppif` samples are support-accounted:

- `ppif/axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_burst_length.ppif`
- `ppif/axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_burst_length.ppif`

The first sample has two depth-3 read queue-head groups:

- concrete `RID` `3`: `r0`, `r1`, `r2`
- concrete `RID` `5`: `r3`, `r4`, `r5`

The second sample has a mixed depth-3/depth-2 shape:

- concrete `RID` `3`: `r0`, `r1`, `r2`
- concrete `RID` `5`: `r3`, `r4`

Both samples use read family metadata only, `response-scope burst-last`, a
one-bit `axi0_rlast`, `completion-source response-demux`, `capture-scope
last-beat`, `status-policy last-beat`, `interleaving last-beat-by-rid`, and
scalar per-transaction last-beat `RDATA`/`RRESP` outputs.

## Generated Behavior

Generation preserves the existing generated queue-head `RID`/`RLAST`
response-demux completion pulses. The scalar read-data capture rules remain
guarded by `generated_queue_head_response_demux_last_beat_completion_pulse`.

The new report-only burst-length behavior adds:

- generated input `axi0_arlen` with width `8`;
- per-transaction raw-`ARLEN` storage, for example `axi0_r5_arlen_q`;
- per-transaction request-guarded capture rules, for example
  `axi0_r5_burst_length_capture`;
- schedule-report fields for generated burst-length inputs, storage, and
  capture rules.

Because validation is `report-only`, no expected-beat storage, read-beat
counter, beat-count initialization, matched-beat increment, or
beat-count/`RLAST` assertion is generated.

The read-data report keeps the explicit residue:

- `generated_beat_count_validation`
- `multi_beat_read_data_reassembly`
- `per_beat_outputs`
- `rresp_aggregation`

## Support Accounting

Strict check JSON and normalized semantic JSON identify the samples as:

- `intent.ppif_axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_burst_length`
- `intent.ppif_axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_burst_length`

Their coverage buckets are:

- `ial2_ppif_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_burst_length_pipeline_cli`
- `ial2_ppif_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_burst_length_pipeline_cli`

## Preserved Boundaries

This slice does not enable runtime beat-count/`RLAST` validation, multi-beat
payload/output-bank behavior, write-family read-data, same-family mixed
auto-ID plus concrete queue-head demux, group-local simultaneous enqueue
widening, packed burst-vector outputs, alternate full burst assembly, direct
backend lowering, verification-output generation, VHDL, or backend-language
variants for the multiple/mixed depth-3 queue-head read-data shapes.
