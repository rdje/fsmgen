# AXI IAL2 Manager Post Multi-Group Queue-Head Burst-Length Next Slice Selection

Status: selector for `IAL2-FEATURE-COMPLETENESS-FRONTIER.133` on
2026-06-15.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.133`

## Context

`IAL2-FEATURE-COMPLETENESS-FRONTIER.132` shipped generated report-only
raw-`ARLEN` burst-length capture for multi-group queue-head scalar last-beat
read-data.

The shipped support-accounted sample is:

- `ppif/axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_burst_length.ppif`

Live schedule JSON for that sample reports:

- `read_data.read.capture_scope: last_beat`
- `read_data.read.burst_length_validation: report_only`
- transactions `r0`, `r1`, `r2`, and `r3`
- generated raw-`ARLEN` capture rules for all four transactions
- `read_data.residue: generated_beat_count_validation, multi_beat_read_data_reassembly, per_beat_outputs, rresp_aggregation`

The current one-group queue-head runtime-validation sample proves the scalar
runtime assertion artifact family:

- `ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_burst_length_runtime_assertion.ppif`

Live report for that sample shows `validation runtime_assertion`, generated
expected-beat storage, beat counters, initialization/increment rules, and
four assertions per transaction:

- `*_arlen_within_max`
- `*_read_beat_before_expected_count`
- `*_rlast_on_expected_beat`
- `*_expected_final_beat_has_rlast`

The current multi-group multi-beat sample proves those runtime-validation
artifacts can already be generated across `r0`, `r1`, `r2`, and `r3` in the
per-beat output-bank shape:

- `ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_read_data.ppif`

That sample is not scalar last-beat; it is `capture_scope multi_beat` with
`output_shape per_beat_output_bank` and empty `read_data` residue. It is
therefore evidence for the state/assertion family and transaction naming, not
permission to widen scalar last-beat runtime validation without an audit.

## Selection

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.134`, readiness audit for generated
runtime-validation multi-group queue-head scalar last-beat read-data.

The selected audit must decide whether the next behavior slice can safely
combine:

- generated read burst-last concrete same-ID queue-head demux with two or more
  duplicate concrete read-ID groups;
- scalar `capture_scope last-beat` read-data;
- `burst_length` metadata with `validation runtime-assertion`;
- one generated last-beat completion signal per transaction;
- per-transaction raw-`ARLEN` capture from request events;
- per-transaction expected-beat storage, matched-beat counters, and
  beat-count/`RLAST` assertions; and
- preservation of `.132` report-only behavior and `.127` multi-beat behavior.

The audit is required before behavior changes because scalar last-beat runtime
validation is the first multi-group scalar shape that needs read-beat counting
while still producing only final scalar outputs. It must confirm that the
current matched-read-beat source, queue-head transaction identity, request
event guards, same-cycle request/response boundaries, report residue, and HDL
lowering all compose without accidentally enabling deeper queues, write-family
multi-group behavior, read single-beat multi-group behavior, or same-family
mixed auto-ID demux.

## Deferred Outside .133/.134

Still outside this selector and the selected audit:

- Direct runtime-validation behavior changes before `.134` completes.
- Deeper concrete same-ID queue groups.
- Same-family mixed `auto_id_lifecycle` plus concrete queue-head demux.
- Write-family multi-group queue-head behavior.
- Read single-beat multi-group queue-head behavior.
- Packed burst-vector outputs and alternate payload assembly.
- Direct backend lowering.
- VHDL backend and reroute behavior.

## Validation Gates For .134

The selected audit should include:

- code review of `_read_data_response_demux_transaction_coverage`,
  read-data normalization, raw matched-read-beat lookup, generated
  beat-count/RLAST validation helpers, report/static prose, and focused tests;
- compact schedule JSON probes for `.132`, `.119`, and `.127` samples;
- a temporary or fixture-backed runtime-validation multi-group scalar probe to
  confirm the current boundary before any behavior change;
- diagnostics and report-residue planning for preserving report-only `.132`;
- mdBook, README, roadmap, task-tree, Memory, and Knowledge Map sync; and
- standard continuity gates before commit.

## Rollback Boundary

This selector is documentation/task-tree state only. Rolling it back removes
this note, the `.133` task-tree/log updates, live-doc references, Memory, and
Knowledge Map updates. It does not change parser, generator, PPIF sample,
support-accounting, generated artifact, or HDL behavior.
