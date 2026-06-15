# AXI IAL2 Manager Multi-Group Queue-Head Read-Data Behavior

Status: shipped by `IAL2-FEATURE-COMPLETENESS-FRONTIER.127` on
2026-06-15.

## Scope

This slice ships generated multi-beat read-data output-bank behavior for a
bounded generated read burst-last concrete same-ID queue-head shape with more
than one duplicate concrete read-ID group.

The public support-accounted sample is:

- `ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_read_data.ppif`

The sample uses two generated depth-2 queue groups:

- `r0` / `r1` share concrete `RID` `3`.
- `r2` / `r3` share concrete `RID` `5`.

Each group must be generated read burst-last queue-head demux, exactly two read
transactions at computed depth `2`, with no same-family `auto_id_lifecycle`
demux. The behavior is accepted only for `read_data.read capture_scope
multi-beat` with `completion-source response-demux`, `interleaving
multi-beat-by-rid`, `status-policy per-beat`, runtime-assertion `ARLEN`
burst-length validation, per-transaction data/status output prefixes,
valid-mask outputs, length outputs, and scalar `RRESP` aggregate outputs.

## Generated Behavior

The generator now flattens all selected generated queue-head groups into the
read-data coverage list for the selected multi-beat output-bank shape. It keeps
one generated last-beat completion signal per covered transaction and uses the
transaction-specific queue-head matched-read-beat guard for lane capture and
beat-count updates.

Generated artifacts include:

- Generated `axi0_rdata`, `axi0_rresp`, and `axi0_arlen` inputs.
- Per-transaction expected-beat and beat-count storage.
- Per-transaction raw `ARLEN` capture rules.
- Request-time output-bank clearing rules for every covered read transaction.
- Sixteen generated `RDATA` lanes and sixteen generated `RRESP` lanes per
  transaction.
- Per-transaction valid masks and read-beat length outputs.
- Per-transaction scalar `RRESP` aggregate outputs, init rules, and update
  rules.
- Beat-count and `RLAST` runtime assertions for every covered transaction.
- SystemVerilog-visible ports for all generated outputs, including the second
  queue group (`axi0_r2_*` and `axi0_r3_*`).

The generated `r2` lane-0 capture path is representative:

```text
RID 5 queue-head match
  -> axi0_r2_read_beat_0_capture
  -> axi0_r2_beat_rdata_0 / axi0_r2_beat_rresp_0
  -> axi0_r2_beat_valid / axi0_r2_read_beats
  -> axi0_r2_rresp aggregate update
```

## Report Contract

The new sample reports:

- `read_data.mode: bounded_multi_beat_read_data_contract`
- `read_data.read.capture_scope: multi_beat`
- `read_data.read.completion_source: response_demux`
- `read_data.read.completion_validity: generated_queue_head_response_demux_last_beat_completion_pulse`
- `read_data.read.beat_match_source: response_demux_matched_read_beat`
- `read_data.read.output_shape: per_beat_output_bank`
- `read_data.read.transactions: r0, r1, r2, r3`
- `read_data.residue: []`
- `response_demux.residue: []`

The response-demux report lists both generated queue groups and generated
completion signals for `r0`, `r1`, `r2`, and `r3`.

## Preserved Behavior

The one-group queue-head multi-beat sample remains supported:

- `ppif/axi_manager_capacity_status_read_multi_beat_same_id_queue_head_read_data.ppif`

The response-demux-only multi-group sample remains supported and still has no
`read_data` section:

- `ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_response_demux.ppif`

Scalar last-beat read-data over multiple generated queue-head groups ships in
the later `.130` behavior note:

- `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_LAST_BEAT_READ_DATA_BEHAVIOR.md`

## Deferred

Still deferred:

- Report-only raw-`ARLEN` or runtime-validation scalar last-beat multi-group
  variants outside the selected no-`burst_length` scalar shape.
- Same-family mixed `auto_id_lifecycle` plus concrete queue-head demux.
- Deeper concrete same-ID queue groups.
- Write-family multi-group queue-head behavior.
- Read single-beat multi-group queue-head behavior.
- Packed burst-vector outputs and alternate payload assembly.
- Direct backend lowering.
- VHDL backend and reroute behavior.

## Validation

Focused validation for `.127` included syntax checks for the touched Perl
module and tests, direct schedule/check/semantic/HDL probes for the new sample,
the generator regression, the PPIF/parser/CLI regression, and supported-corpus
check/semantic gates. The final task-tree entry records the exact gate list
and runtimes.
