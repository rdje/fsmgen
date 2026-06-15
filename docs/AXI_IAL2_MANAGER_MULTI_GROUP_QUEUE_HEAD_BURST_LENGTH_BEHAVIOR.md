# AXI IAL2 Manager Multi-Group Queue-Head Burst-Length Behavior

Status: shipped by `IAL2-FEATURE-COMPLETENESS-FRONTIER.132` on
2026-06-15.

## Scope

This slice ships generated report-only raw-`ARLEN` capture for bounded
generated read burst-last concrete same-ID queue-head shapes with more than
one duplicate concrete read-ID group and scalar last-beat read-data capture.

The public support-accounted sample is:

- `ppif/axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_burst_length.ppif`

The sample uses two generated depth-2 queue groups:

- `r0` / `r1` share concrete `RID` `3`.
- `r2` / `r3` share concrete `RID` `5`.

The accepted shape is intentionally narrow: generated read burst-last
queue-head demux, every group exactly two read transactions at computed depth
`2`, `read_data.read capture_scope last-beat`, `completion-source
response-demux`, `status-policy last-beat`, `interleaving last-beat-by-rid`,
`burst_length` metadata with `source arlen`, `signal` width `8`,
`encoding axlen-plus-one`, `capture request`, `validation report-only`, and
complete per-transaction scalar `data_output` / `status_output` bindings.

## Public Source Shape

The relevant `read-data` shape is:

```text
(read-data
  (read
    (capture-scope last-beat)
    (completion-source response-demux)
    (status-policy last-beat)
    (interleaving last-beat-by-rid)
    (data-signal axi0_rdata (width 32))
    (status-signal axi0_rresp (width 2))
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
      (status-output axi0_r2_last_rresp))
    (transaction r3
      (data-output axi0_r3_last_rdata)
      (status-output axi0_r3_last_rresp))))
```

## Generated Behavior

The generator flattens all selected generated read queue-head groups into the
last-beat read-data coverage list. It preserves one generated last-beat
completion pulse per transaction, emits scalar `RDATA`/`RRESP` capture rules
guarded by those completion pulses, and adds request-time raw-`ARLEN` capture
for every covered transaction.

Generated artifacts include:

- Generated `axi0_rdata`, `axi0_rresp`, and `axi0_arlen` inputs.
- Per-transaction scalar last-beat data/status outputs.
- Per-transaction raw-`ARLEN` storage:
  `axi0_r0_arlen_q`, `axi0_r1_arlen_q`, `axi0_r2_arlen_q`, and
  `axi0_r3_arlen_q`.
- Per-transaction request-guarded raw-`ARLEN` capture rules:
  `axi0_r0_burst_length_capture`, `axi0_r1_burst_length_capture`,
  `axi0_r2_burst_length_capture`, and `axi0_r3_burst_length_capture`.
- Per-transaction scalar read-data capture rules guarded by generated
  queue-head last-beat completion pulses.

The generated `r2` path is representative:

```text
axi0_r2_request
  -> axi0_r2_burst_length_capture
  -> axi0_r2_arlen_q captures axi0_arlen

RID 5 queue-head last-beat match
  -> axi0_r2_complete
  -> axi0_r2_read_data_capture
  -> axi0_r2_last_rdata / axi0_r2_last_rresp
```

`validation report-only` does not generate expected-beat storage,
matched-beat counters, or beat-count/`RLAST` assertions.

## Report Contract

The new sample reports:

- `read_data.mode: bounded_last_beat_read_data_contract`
- `read_data.read.capture_scope: last_beat`
- `read_data.read.completion_validity: generated_queue_head_response_demux_last_beat_completion_pulse`
- `read_data.read.burst_length_source: arlen_signal`
- `read_data.read.burst_length_signal: axi0_arlen`
- `read_data.read.burst_length_validation: report_only`
- `read_data.read.transactions: r0, r1, r2, r3`
- `read_data.read.generated_burst_length_inputs: axi0_arlen`
- `read_data.read.generated_burst_length_storage: axi0_r0_arlen_q, axi0_r1_arlen_q, axi0_r2_arlen_q, axi0_r3_arlen_q`
- `read_data.read.generated_burst_length_rules: axi0_r0_burst_length_capture, axi0_r1_burst_length_capture, axi0_r2_burst_length_capture, axi0_r3_burst_length_capture`
- `read_data.residue: generated_beat_count_validation, multi_beat_read_data_reassembly, per_beat_outputs, rresp_aggregation`

The static report prose now names multi-group queue-head last-beat capture with
report-only raw-`ARLEN` metadata as supported. It keeps runtime-validation
last-beat read-data over multiple queue groups outside this report-only
sample's boundary; the runtime-validation sibling is shipped by
`IAL2-FEATURE-COMPLETENESS-FRONTIER.135`.

## Preserved Behavior

The no-`burst_length` multi-group scalar last-beat sample remains supported and
continues to omit `axi0_arlen`:

- `ppif/axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_read_data.ppif`

The multi-group multi-beat sample remains residue-clean and still generates
output banks, raw `ARLEN` capture, beat-count/`RLAST` runtime validation,
valid masks, length outputs, and scalar `RRESP` aggregation:

- `ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_read_data.ppif`

The one-group queue-head report-only raw-`ARLEN` and runtime-validation
samples retain their existing behavior:

- `ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_burst_length.ppif`
- `ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_burst_length_runtime_assertion.ppif`

## Deferred

Still deferred:

- Same-family mixed `auto_id_lifecycle` plus concrete queue-head demux.
- Deeper concrete same-ID queue groups.
- Write-family multi-group queue-head behavior.
- Read single-beat multi-group queue-head behavior.
- Packed burst-vector outputs and alternate payload assembly.
- Direct backend lowering.
- VHDL backend and reroute behavior.

## Validation

Focused validation for `.132` included syntax checks for the touched Perl
module and tests, direct schedule/check/semantic/HDL probes for the new public
sample, the generator regression, the PPIF/parser/CLI regression,
regression-corpus accounting, supported-corpus check/semantic gates, mdBook,
Knowledge Map, memory architecture, and diff hygiene gates. The final
task-tree entry records the exact command list and results.
