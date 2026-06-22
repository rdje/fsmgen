# AXI IAL2 Manager Dynamic Multi-Beat Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.243`

Date: 2026-06-22

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.243` ships generated dynamic
multi-beat read-data output-bank behavior over the selected single-active
dynamic read runtime-validation boundary.

The support-accounted public sample is
`ppif/axi_manager_capacity_status_dynamic_read_data_multi_beat.ppif`. It
extends the `.240` dynamic runtime-validation shape by using multi-beat
read-data capture and explicit per-transaction output-bank bindings.

## Public Shape

The selected shape remains bounded:

- exactly one read transaction uses `(id dynamic)`;
- `response-demux.read` uses `(response-scope burst-last)`, a one-bit
  `last-signal`, generated transaction completion, and
  `generated_dynamic_demux_last_beat` as the transaction-completion source;
- `read-data.read` uses `capture-scope multi-beat`, `completion-source
  response-demux`, `status-policy per-beat`, `status-aggregation
  worst-observed`, and `interleaving multi-beat-by-rid`;
- `burst-length` uses `source arlen`, width-8 `signal`, `encoding
  axlen-plus-one`, `capture request`, bounded `max-beats`, and `validation
  runtime-assertion`; and
- the dynamic read transaction provides `data-output-prefix`,
  `status-output-prefix`, `status-aggregate-output`, `valid-mask-output`, and
  `length-output` bindings.

## Generated Behavior

The generated path now emits, for the public 16-beat sample:

- width-8 `axi0_arlen` input metadata;
- per-transaction raw `ARLEN` storage plus expected-beat and read-beat count
  storage;
- request-time output-bank initialization for all generated data lanes,
  status lanes, the valid mask, the length output, and the scalar aggregate
  status output;
- sixteen `RDATA` lane outputs named `axi0_r0_beat_rdata_0` through
  `axi0_r0_beat_rdata_15`;
- sixteen `RRESP` lane outputs named `axi0_r0_beat_rresp_0` through
  `axi0_r0_beat_rresp_15`;
- the valid-mask output `axi0_r0_beat_valid`;
- the length output `axi0_r0_read_beats`;
- the scalar worst-observed status aggregate output `axi0_r0_rresp`;
- one per-lane capture rule for each bounded beat; and
- four generated beat-count/`RLAST` runtime assertions inherited from the
  dynamic runtime-validation boundary.

Lane capture uses the raw accepted dynamic read beat whose `RID` matches the
captured dynamic ID while the transaction is busy. It does not wait for the
final `RID && RLAST` completion pulse; that pulse still defines the generated
transaction-completion validity for the response-demux boundary.

## Report Contract

Schedule JSON reports the selected dynamic output-bank shape with:

- `read_data.mode: bounded_multi_beat_read_data_contract`;
- `read_data.read.completion_validity:
  generated_dynamic_read_response_demux_last_beat_completion_pulse`;
- `read_data.read.beat_match_source: response_demux_matched_read_beat`;
- `read_data.read.beat_count_match_source: response_demux_matched_read_beat`;
- `read_data.read.output_shape: per_beat_output_bank`;
- `read_data.read.status_aggregation: worst_observed`;
- `read_data.read.status_aggregation_generated_behavior: true`;
- `read_data.read.multi_beat_reassembly_generated_behavior: true`;
- generated data/status lane, valid-mask, length, aggregate-status,
  output-init, lane-capture, and aggregate-update lists; and
- `read_data.residue: []` for the selected public sample.

The selected sample removes read-data interleaving and burst-output residue
from the response-demux report. Same-ID ordering remains unrelated future
dynamic residue.

## Preserved Boundaries

The `.238` report-only raw-`ARLEN` sample, `.240` scalar
runtime-validation sample, scalar dynamic single-beat and last-beat read-data
samples, dynamic write/read response-demux samples, and all non-dynamic
multi-beat output-bank samples remain supported.

Multiple or mixed dynamic demux, same-cycle recapture, dynamic same-ID
ordering, queues, scoreboards, direct backend behavior, backend-language
variants outside the selected SystemVerilog path, and VHDL remain fail-closed.

## Validation

Closeout validation covered syntax checks for touched modules/tests, direct
schedule JSON, strict check JSON, semantic JSON, default HDL, and
`--verify-hdl` probes for the new dynamic multi-beat sample, guarded focused
dynamic validation through
`t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t`, and guarded
support-accounting validation through
`t/248-regression-corpus-accounting.t`.

Full `t/1436` was attempted during implementation and was stopped by the
host-memory guard at the default 88% cutoff. Direct parser/CLI probes and the
bounded dynamic suite covered the new public sample after the expectation
updates.

## Rollback

Rollback is the `.243` implementation commit. Reverting it removes the public
dynamic multi-beat PPIF sample, support-accounting entry, dynamic multi-beat
coverage admission, dynamic report-residue recognition, focused coverage, and
docs/facts, restoring `.243` as the active frontier.
