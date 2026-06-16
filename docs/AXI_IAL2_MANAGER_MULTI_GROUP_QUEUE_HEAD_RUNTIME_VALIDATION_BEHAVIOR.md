# AXI IAL2 Manager Multi-Group Queue-Head Runtime-Validation Behavior

Status: shipped by `IAL2-FEATURE-COMPLETENESS-FRONTIER.135` on
2026-06-15.

## Scope

This slice ships generated beat-count/`RLAST` runtime validation for bounded
generated read burst-last concrete same-ID queue-head shapes with more than
one duplicate concrete read-ID group and scalar last-beat read-data capture.

The public support-accounted sample is:

- `ppif/axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_burst_length_runtime_assertion.ppif`

The sample uses two generated depth-2 queue groups:

- `r0` / `r1` share concrete `RID` `3`.
- `r2` / `r3` share concrete `RID` `5`.

The accepted shape is intentionally narrow: generated read burst-last
queue-head demux, every group exactly two read transactions at computed depth
`2`, `read_data.read capture_scope last-beat`, `completion-source
response-demux`, `status-policy last-beat`, `interleaving last-beat-by-rid`,
`burst_length` metadata with `source arlen`, `signal` width `8`,
`encoding axlen-plus-one`, `capture request`, `validation
runtime-assertion`, and complete per-transaction scalar `data_output` /
`status_output` bindings.

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
      (validation runtime-assertion))
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
guarded by those completion pulses, captures raw `ARLEN` on each transaction
request, initializes expected-beat and read-beat-count state, increments the
matched-read-beat counter on raw queue-head `RID` matches, and emits runtime
assertions for the bounded beat-count contract.

Generated artifacts include:

- Generated `axi0_rdata`, `axi0_rresp`, `axi0_arlen`, `axi0_rid`, and
  `axi0_rlast` inputs.
- Per-transaction scalar last-beat data/status outputs.
- Per-transaction raw-`ARLEN` storage:
  `axi0_r0_arlen_q`, `axi0_r1_arlen_q`, `axi0_r2_arlen_q`, and
  `axi0_r3_arlen_q`.
- Per-transaction expected-beat storage:
  `axi0_r0_expected_beats_q`, `axi0_r1_expected_beats_q`,
  `axi0_r2_expected_beats_q`, and `axi0_r3_expected_beats_q`.
- Per-transaction read-beat counters:
  `axi0_r0_read_beat_count_q`, `axi0_r1_read_beat_count_q`,
  `axi0_r2_read_beat_count_q`, and `axi0_r3_read_beat_count_q`.
- Per-transaction request initialization and matched-beat increment rules:
  `axi0_r0_beat_count_init`, `axi0_r1_beat_count_init`,
  `axi0_r2_beat_count_init`, `axi0_r3_beat_count_init`,
  `axi0_r0_read_beat_count`, `axi0_r1_read_beat_count`,
  `axi0_r2_read_beat_count`, and `axi0_r3_read_beat_count`.
- Four beat-count/`RLAST` assertions per transaction: request-time
  `ARLEN` bound, extra beat beyond expected count, early `RLAST`, and
  missing `RLAST` on the expected final beat.

The generated `r2` path is representative:

```text
axi0_r2_request
  -> axi0_r2_burst_length_capture
  -> axi0_r2_arlen_q captures axi0_arlen
  -> axi0_r2_beat_count_init
  -> axi0_r2_expected_beats_q = axi0_arlen[4:0] + 5'd1
  -> axi0_r2_read_beat_count_q = 0

RID 5 raw queue-head beat match while r2 is queue head
  -> axi0_r2_read_beat_count increments

RID 5 queue-head last-beat match
  -> axi0_r2_complete
  -> axi0_r2_read_data_capture
  -> axi0_r2_last_rdata / axi0_r2_last_rresp
```

The matched-beat counter is intentionally driven by raw queue-head beat
validity, not by the generated completion pulse, so non-final beats are counted
before the final `RLAST` completion pulse captures scalar output data/status.

## Report Contract

The new sample reports:

- `read_data.mode: bounded_last_beat_read_data_contract`
- `read_data.read.capture_scope: last_beat`
- `read_data.read.completion_validity: generated_queue_head_response_demux_last_beat_completion_pulse`
- `read_data.read.burst_length_source: arlen_signal`
- `read_data.read.burst_length_signal: axi0_arlen`
- `read_data.read.burst_length_validation: runtime_assertion`
- `read_data.read.beat_count_validation_generated_behavior: true`
- `read_data.read.expected_beat_count_encoding: arlen_plus_one`
- `read_data.read.beat_count_match_source: response_demux_matched_read_beat`
- `read_data.read.transactions: r0, r1, r2, r3`
- `read_data.read.generated_burst_length_inputs: axi0_arlen`
- `read_data.read.generated_expected_beat_storage: axi0_r0_expected_beats_q, axi0_r1_expected_beats_q, axi0_r2_expected_beats_q, axi0_r3_expected_beats_q`
- `read_data.read.generated_beat_count_storage: axi0_r0_read_beat_count_q, axi0_r1_read_beat_count_q, axi0_r2_read_beat_count_q, axi0_r3_read_beat_count_q`
- `read_data.read.generated_beat_count_rules: axi0_r0_read_beat_count, axi0_r1_read_beat_count, axi0_r2_read_beat_count, axi0_r3_read_beat_count`
- `read_data.residue: multi_beat_read_data_reassembly, per_beat_outputs, rresp_aggregation`

`generated_beat_count_validation` is removed from `read_data.residue` only for
this bounded runtime-validation sample.

## Support Report Alignment

`IAL2-FEATURE-COMPLETENESS-FRONTIER.137` cleaned the static support report for
this shipped behavior. The AXI ID/order support detail now describes generated
runtime-validation multi-group queue-head scalar last-beat read-data as
supported, including runtime-assertion beat-count/`RLAST` validation metadata
for one or more independent queue-head groups.

The retired unsupported-residue wording for runtime-validation multi-group
scalar last-beat read-data is no longer emitted for this shipped shape. This
alignment changes only report prose and focused parser expectations; it does
not broaden parser syntax, generator admission, PPIF samples, support
accounting, generated artifacts, or HDL behavior.

## Preserved Behavior

The report-only raw-`ARLEN` multi-group scalar sample remains supported and
continues to omit expected-beat storage, read-beat counters, and runtime
assertions:

- `ppif/axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_burst_length.ppif`

The no-`burst_length` multi-group scalar last-beat sample remains supported and
continues to omit `axi0_arlen`:

- `ppif/axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_read_data.ppif`

The multi-group multi-beat sample remains residue-clean and still generates
output banks, raw `ARLEN` capture, beat-count/`RLAST` runtime validation,
valid masks, length outputs, and scalar `RRESP` aggregation:

- `ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_read_data.ppif`

The response-demux-only multi-group sample remains supported and still has no
`read_data` section:

- `ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_response_demux.ppif`

The one-group queue-head runtime-validation sample retains its existing
two-transaction behavior:

- `ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_burst_length_runtime_assertion.ppif`

## Deferred

Still deferred:

- Multi-beat reassembly for this scalar runtime-validation sample.
- Per-beat outputs and scalar `RRESP` aggregation for this scalar sample.
- Same-family mixed `auto_id_lifecycle` plus concrete queue-head demux.
- Deeper concrete same-ID queue groups.
- Write-family multi-group queue-head behavior.
- Read single-beat multi-group queue-head behavior.
- Packed burst-vector outputs and alternate payload assembly.
- Direct backend lowering.
- VHDL backend and reroute behavior.

## Validation

Focused validation for `.135` included syntax checks for the touched Perl
module and tests, direct schedule/check/semantic/HDL probes for the new public
sample, the generator regression, the PPIF/parser/CLI regression,
regression-corpus accounting, supported-corpus path/check/semantic gates,
mdBook, Knowledge Map, memory architecture, docs path audit, README numbering,
frontier scans, and diff hygiene gates. The final task-tree entry records the
exact command list and results.
