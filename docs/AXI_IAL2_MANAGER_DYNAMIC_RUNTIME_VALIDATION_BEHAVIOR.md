# AXI IAL2 Manager Dynamic Runtime Validation Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.240`

Date: 2026-06-22

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.240` ships generated runtime
beat-count/`RLAST` validation for the selected single-active dynamic read
last-beat read-data shape.

The support-accounted public sample is
`ppif/axi_manager_capacity_status_dynamic_read_data_burst_length_runtime_assertion.ppif`.
It extends the `.238` report-only dynamic raw-`ARLEN` sample by changing only
the `burst-length` validation mode to `runtime-assertion`.

## Public Shape

The selected shape remains intentionally narrow:

- exactly one read transaction uses `(id dynamic)`;
- `response-demux.read` uses `(response-scope burst-last)`, a one-bit
  `last-signal`, and generated transaction completion;
- `read-data.read` uses `capture-scope last-beat`, `completion-source
  response-demux`, `status-policy last-beat`, and `interleaving
  last-beat-by-rid`;
- `burst-length` uses `source arlen`, a width-8 `signal`, `encoding
  axlen-plus-one`, `capture request`, `max-beats` in `1..256`, and
  `validation runtime-assertion`.

## Generated Behavior

The generated path now emits:

- width-8 `axi0_arlen` input metadata;
- per-transaction raw `ARLEN` storage, for the public sample
  `axi0_r0_arlen_q`;
- request-guarded raw `ARLEN` capture through
  `axi0_r0_burst_length_capture`;
- expected-beat storage `axi0_r0_expected_beats_q`, initialized from
  `axi0_arlen[4:0] + 5'd1`;
- read-beat counter storage `axi0_r0_read_beat_count_q`, initialized on the
  request and incremented on every raw accepted dynamic `RID == captured_id`
  read beat while not also accepting a new request;
- four generated runtime assertions:
  `axi0_r0_arlen_within_max`,
  `axi0_r0_read_beat_before_expected_count`,
  `axi0_r0_rlast_on_expected_beat`, and
  `axi0_r0_expected_final_beat_has_rlast`; and
- scalar last-beat `RDATA`/`RRESP` capture still guarded only by the generated
  dynamic `RID && RLAST` completion pulse.

Schedule JSON reports `burst_length_validation: runtime_assertion`,
`beat_count_validation_generated_behavior: true`,
`expected_beat_count_encoding: arlen_plus_one`,
`beat_count_match_source: response_demux_matched_read_beat`, and removes the
report-only `generated_beat_count_validation` residue for the selected sample.

## Preserved Boundaries

The `.238` report-only sample remains unchanged and keeps
`generated_beat_count_validation` in its read-data residue.

Dynamic single-beat read-data with burst-length metadata, dynamic multi-beat
output banks, multiple or mixed dynamic response demux, same-cycle recapture,
dynamic same-ID ordering, queues, scoreboards, direct backend behavior,
backend-language variants outside the selected SystemVerilog path, and VHDL
remain fail-closed.

## Validation

Closeout validation covered syntax checks for touched modules/tests, direct
schedule JSON, strict check JSON, semantic JSON, default HDL, and `--verify-hdl`
probes for the new runtime sample, preservation probes for the `.238`
report-only sample, focused in-memory negative probes for unsupported dynamic
single-beat burst-length, multiple dynamic read demux, and malformed
`max-beats`, guarded focused dynamic validation through
`t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t`, and guarded
support-accounting validation through `t/248-regression-corpus-accounting.t`.

Full `t/1436`/`t/1437` remains too large for routine dynamic closeout on this
host; their expectations were kept current, and the bounded dynamic suite owns
routine proof for this family.

## Rollback

Rollback is the `.240` implementation commit. Reverting it removes the public
runtime dynamic PPIF sample, support-accounting entry, dynamic coverage gate
widening, focused runtime validation, report/residue wording, and docs/facts,
restoring `.240` as the active frontier.
