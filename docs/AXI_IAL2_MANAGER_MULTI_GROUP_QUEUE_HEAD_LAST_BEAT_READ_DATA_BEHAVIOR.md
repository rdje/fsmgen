# AXI IAL2 Manager Multi-Group Queue-Head Last-Beat Read-Data Behavior

Status: shipped by `IAL2-FEATURE-COMPLETENESS-FRONTIER.130` on
2026-06-15.

## Scope

This slice ships generated scalar last-beat read-data capture for bounded
generated read burst-last concrete same-ID queue-head shapes with more than
one duplicate concrete read-ID group.

The public support-accounted sample is:

- `ppif/axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_read_data.ppif`

The sample uses two generated depth-2 queue groups:

- `r0` / `r1` share concrete `RID` `3`.
- `r2` / `r3` share concrete `RID` `5`.

The accepted shape is intentionally narrow: generated read burst-last
queue-head demux, every group exactly two read transactions at computed depth
`2`, `read_data.read capture_scope last-beat`, `completion-source
response-demux`, `status-policy last-beat`, `interleaving last-beat-by-rid`,
no `burst_length` metadata, and complete per-transaction scalar
`data_output` / `status_output` bindings.

## Generated Behavior

The generator flattens all selected generated read queue-head groups into the
last-beat read-data coverage list. It keeps one generated last-beat completion
signal per covered transaction, then emits scalar `RDATA`/`RRESP` capture rules
guarded by those generated completion pulses.

Generated artifacts include:

- Generated `axi0_rdata` and `axi0_rresp` inputs.
- Per-transaction scalar last-beat data/status outputs.
- Per-transaction scalar capture rules for `r0`, `r1`, `r2`, and `r3`.
- SystemVerilog-visible scalar outputs for the second group, including
  `axi0_r2_last_rdata`, `axi0_r2_last_rresp`, `axi0_r3_last_rdata`, and
  `axi0_r3_last_rresp`.

No `axi0_arlen`, raw-`ARLEN` storage, expected-beat storage, beat counters, or
per-beat output banks are generated for this scalar no-`burst_length` shape.

The generated `r2` scalar capture path is representative:

```text
RID 5 queue-head last-beat match
  -> axi0_r2_complete
  -> axi0_r2_read_data_capture
  -> axi0_r2_last_rdata / axi0_r2_last_rresp
```

## Report Contract

The new sample reports:

- `response_demux.read.generated_queue_behavior_boundary: generated_read_burst_last_queue_head_demux`
- `response_demux.read.same_id_issue_order_queues: RID 3 [r0, r1], RID 5 [r2, r3]`
- `read_data.mode: bounded_last_beat_read_data_contract`
- `read_data.read.capture_scope: last_beat`
- `read_data.read.completion_source: response_demux`
- `read_data.read.completion_validity: generated_queue_head_response_demux_last_beat_completion_pulse`
- `read_data.read.burst_length_source: rlast_only`
- `read_data.read.burst_length_validation: not_generated`
- `read_data.read.transactions: r0, r1, r2, r3`
- `read_data.read.generated_outputs: 8`
- `read_data.read.generated_rules: 4`
- `response_demux.residue: read_data_interleaving, bursts`
- `read_data.residue: multi_beat_read_data_reassembly, per_beat_outputs, rresp_aggregation, arlen_or_beat_count_validation`

## Preserved Behavior

The existing multi-group multi-beat sample remains residue-clean and still
generates output banks, raw `ARLEN` capture, beat-count/`RLAST` runtime
validation, valid masks, length outputs, and scalar `RRESP` aggregation:

- `ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_read_data.ppif`

The one-group scalar last-beat sample remains supported and keeps the same
scalar residue set:

- `ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_read_data.ppif`

The multi-group response-demux-only sample remains supported and still has no
`read_data` section:

- `ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_response_demux.ppif`

## Deferred

Still deferred:

- Report-only raw-`ARLEN` multi-group scalar last-beat variants.
- Runtime beat-count/`RLAST` multi-group scalar last-beat variants.
- Same-family mixed `auto_id_lifecycle` plus concrete queue-head demux.
- Deeper concrete same-ID queue groups.
- Write-family multi-group queue-head behavior.
- Read single-beat multi-group queue-head behavior.
- Packed burst-vector outputs and alternate payload assembly.
- Direct backend lowering.
- VHDL backend and reroute behavior.

## Validation

Focused validation for `.130` included syntax checks for the touched Perl
module and tests, direct schedule/check/semantic/HDL probes for the new sample,
negative report-only/runtime-validation multi-group scalar probes, preservation
probes for the one-group scalar last-beat and multi-group multi-beat samples,
the generator regression, the PPIF/parser/CLI regression, regression-corpus
accounting, supported-corpus check/semantic gates, mdBook, Knowledge Map,
memory architecture, and diff hygiene gates. The final task-tree entry records
the exact command list and results.
