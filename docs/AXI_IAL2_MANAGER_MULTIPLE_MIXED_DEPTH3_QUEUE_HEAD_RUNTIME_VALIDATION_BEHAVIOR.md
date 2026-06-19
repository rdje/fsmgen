# AXI IAL2 Manager Multiple/Mixed Depth-3 Queue-Head Runtime-Validation Behavior

Task owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.186`

Date: 2026-06-19

## Scope

FSMGen now generates runtime beat-count/`RLAST` validation for read
burst-last queue-head scalar last-beat read-data when the concrete same-ID
queue-head groups have computed depth `2` or `3`, at least one selected group
has depth `3`, and the read-data contract already uses request-captured
raw-`ARLEN` burst-length metadata.

This is the direct implementation selected by
`docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_READINESS_AUDIT.md`.
It extends the `.183` multiple/mixed depth-3 scalar last-beat read-data
burst-length shape from report-only metadata to runtime validation:

```text
(burst-length
  (source arlen)
  (signal axi0_arlen (width 8))
  (encoding axlen-plus-one)
  (capture request)
  (max-beats 16)
  (validation runtime-assertion))
```

## Public Samples

Two public `.ppif` samples are support-accounted:

- `ppif/axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_burst_length_runtime_assertion.ppif`
- `ppif/axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_burst_length_runtime_assertion.ppif`

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

Generation preserves the generated queue-head `RID`/`RLAST` response-demux
completion pulses, scalar last-beat `RDATA`/`RRESP` capture, generated
`axi0_arlen` input, per-transaction raw-`ARLEN` storage, and
request-guarded raw-`ARLEN` capture rules from the report-only burst-length
shape.

The runtime-validation behavior adds, per covered read transaction:

- expected-beat storage using the `ARLEN + 1` encoding;
- read-beat counter storage;
- request-time expected-beat/counter initialization;
- matched-read-beat counter increment sourced from the generated queue-head
  response-demux matched read beat;
- beat-count/`RLAST` assertions for request-time bounds, over-count/extra
  beats, early `RLAST`, and missing final `RLAST`.

The two-depth-3 sample emits six expected-beat storage signals, six read-beat
counters, twelve beat-count rules, and 24 beat-count/`RLAST` assertions. The
mixed depth-3/depth-2 sample emits five expected-beat storage signals, five
read-beat counters, ten beat-count rules, and 20 beat-count/`RLAST`
assertions.

The read-data report sets `burst_length_validation: runtime_assertion`,
`beat_count_validation_generated_behavior: true`,
`expected_beat_count_encoding: arlen_plus_one`,
`beat_count_match_source: response_demux_matched_read_beat`, and
`beat_count_width: 5`.

Because beat-count validation is generated, `generated_beat_count_validation`
is no longer present in `read_data.residue` for these two samples. The report
continues to preserve explicit residue for:

- `multi_beat_read_data_reassembly`
- `per_beat_outputs`
- `rresp_aggregation`

## Support Accounting

Strict check JSON and normalized semantic JSON identify the samples as:

- `intent.ppif_axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_burst_length_runtime_assertion`
- `intent.ppif_axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_burst_length_runtime_assertion`

Their coverage buckets are:

- `ial2_ppif_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_burst_length_runtime_assertion_pipeline_cli`
- `ial2_ppif_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_burst_length_runtime_assertion_pipeline_cli`

## Preserved Boundaries

This slice does not enable multi-beat payload/output-bank behavior,
write-family read-data, same-family mixed auto-ID plus concrete queue-head
demux, group-local simultaneous enqueue widening, packed burst-vector
outputs, alternate full burst assembly, direct backend lowering,
verification-output generation, VHDL, or backend-language variants for the
multiple/mixed depth-3 queue-head read-data shapes.
