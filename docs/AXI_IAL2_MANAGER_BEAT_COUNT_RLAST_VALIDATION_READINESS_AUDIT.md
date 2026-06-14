# AXI IAL2 Manager Beat-Count/RLAST Validation Readiness Audit

Status: audit complete; no parser, generator, HDL, sample,
support-accounting, check JSON, semantic JSON, or validation behavior changed
by this note.

Owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.67`.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

Builds on:

- [docs/AXI_IAL2_MANAGER_ARLEN_CAPTURE_BEHAVIOR_FIRST_SLICE.md](AXI_IAL2_MANAGER_ARLEN_CAPTURE_BEHAVIOR_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_ARLEN_CAPTURE_READINESS_AUDIT.md](AXI_IAL2_MANAGER_ARLEN_CAPTURE_READINESS_AUDIT.md)
- [docs/AXI_IAL2_MANAGER_BURST_READ_DATA_BEAT_COUNT_METADATA_FIRST_SLICE.md](AXI_IAL2_MANAGER_BURST_READ_DATA_BEAT_COUNT_METADATA_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_BURST_READ_DATA_BEAT_COUNT_CONTRACT_SELECTION.md](AXI_IAL2_MANAGER_BURST_READ_DATA_BEAT_COUNT_CONTRACT_SELECTION.md)
- [docs/AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_BEHAVIOR_FIRST_SLICE.md](AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_BEHAVIOR_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_BEHAVIOR_FIRST_SLICE.md](AXI_IAL2_MANAGER_RLAST_COMPLETION_BEHAVIOR_FIRST_SLICE.md)

## Evidence Read

The `.66` raw-ARLEN behavior now supplies the missing request-side length
capture:

```text
(input axi0_arlen (width 8))

(var axi0_r0_arlen_q (width 8))
(var axi0_r1_arlen_q (width 8))

(rule axi0_r0_burst_length_capture axi0_r0_request
  (axi0_r0_arlen_q axi0_arlen))
```

The captured value is raw AXI `ARLEN`. The public metadata says
`burst_length_encoding: axlen_plus_one`, so any validation owner must derive
the expected beat count as raw `ARLEN + 1`.

Generated burst-last response demux already identifies accepted read beats and
matched last beats:

```text
response_event: axi0_read_complete
response_id_signal: axi0_rid
last_signal: axi0_rlast
transaction_completion_semantics: matched_rid_and_last_signal
```

The generated completion pulse fires only on matched `RLAST`, so beat-count
validation cannot count only completion pulses. It must use the accepted read
response beat event plus the same active-transaction/RID match expression used
by response demux, without requiring `RLAST`.

Generated last-beat `RDATA`/`RRESP` capture is already driven by the matched
last-beat completion pulse and remains intact. It does not store intermediate
payload beats, expose per-beat valid outputs, or aggregate all-beat `RRESP`.

The existing IAL1/IAL0/SystemVerilog path already proves the required
substrate pieces:

- width-bearing generated inputs and storage variables;
- guarded generated rules with expression RHS text;
- generated assertions lowered through ISF `+assert` carriers;
- clocked, reset-disabled SystemVerilog assertion projection;
- equality, logical, comparison, and arithmetic expression rendering;
- generated counter/storage widths through explicit `(width N)` declarations.

## Public Contract Boundary

The lower layers are ready for generated validation, but the public contract is
not. The current checked-in sample still says:

```text
(validation report-only)
```

That mode was selected to mean report metadata only: no counters, assertions,
missing-beat checks, extra-beat checks, early-`RLAST` checks, late-`RLAST`
checks, or storage beyond raw ARLEN capture. A behavior slice must not
silently turn `report-only` into runtime validation.

Therefore the next exact owner is a public contract selector, not direct
behavior:

```text
IAL2-FEATURE-COMPLETENESS-FRONTIER.68
```

`.68` should select the explicit validation mode for generated runtime checks,
with `validation report-only` preserved as the no-runtime-check mode. The
recommended spelling for the generated mode is:

```text
(validation runtime-assertion)
```

The normalized report spelling should be `runtime_assertion`.

## Readiness Conclusion

No new IAL1, IAL0, or SystemVerilog substrate prerequisite is needed once the
public validation contract is selected and parsed.

The implementation can be a direct generated behavior slice after the public
syntax/report metadata owner exists.

## Selected Behavior Shape After The Contract Prerequisite

For each covered read transaction, the generated validation behavior should
own:

- an expected-beat-count storage variable, derived from raw `ARLEN + 1`;
- a response-beat counter or index state;
- generated rules that initialize state on transaction request;
- generated rules that count every accepted response beat whose `RID` matches
  the active transaction, not just the last-beat completion pulse;
- generated runtime assertions for request length bounds, early `RLAST`,
  missing `RLAST` on the expected final beat, and extra beats beyond the
  expected count.

Expected-beat storage must not be 8-bit raw-ARLEN width. AXI `ARLEN` is 8
bits but `ARLEN + 1` can be 256. The generated expected-count and beat-count
state widths should be based on `max_beats`, using a width that represents
the inclusive count range `0..max_beats`. For `max-beats 16`, that is width
5; for `max-beats 256`, that is width 9.

The first generated validation slice should stay within the existing
single-active auto-ID transaction boundary. Same-cycle reissue of the same
logical read transaction while it is still busy remains rejected by the
existing auto-ID lifecycle assertions.

## Diagnostics

The generated assertion set should use stable, reportable names. Recommended
per-transaction names are:

```text
axi0_r0_arlen_within_max
axi0_r0_read_beat_before_expected_count
axi0_r0_rlast_on_expected_beat
axi0_r0_expected_final_beat_has_rlast
```

The assertions should distinguish:

- request-time raw ARLEN exceeding `max_beats - 1`;
- a matched read response beat arriving after the expected count is already
  exhausted;
- `RLAST` asserted before the expected final beat;
- the expected final beat arriving without `RLAST`.

An extra beat after a correctly matched `RLAST` is also covered by the
existing active-match response-demux assertion after auto-ID release, but the
validation owner should still catch over-count while the transaction remains
active.

## Report Contract After The Contract Prerequisite

The future generated behavior should add explicit report fields rather than
overloading raw ARLEN capture:

```text
read_data:
  read:
    burst_length_validation: runtime_assertion
    beat_count_validation_generated_behavior: true
    expected_beat_count_encoding: arlen_plus_one
    beat_count_match_source: response_demux_matched_read_beat
    generated_expected_beat_count_storage:
      - axi0_r0_expected_beats_q
      - axi0_r1_expected_beats_q
    generated_beat_count_storage:
      - axi0_r0_read_beat_count_q
      - axi0_r1_read_beat_count_q
    generated_beat_count_rules:
      - ...
    generated_beat_count_assertions:
      - axi0_r0_arlen_within_max
      - axi0_r0_read_beat_before_expected_count
      - axi0_r0_rlast_on_expected_beat
      - axi0_r0_expected_final_beat_has_rlast
```

When generated validation ships, `read_data.residue` should remove
`generated_beat_count_validation` and keep:

```text
multi_beat_read_data_reassembly
per_beat_outputs
rresp_aggregation
```

`beat_storage`, `valid_output`, and `length_output` should remain `none`
unless a later owner selects public output behavior.

## Explicit Deferrals

This audit and the selected `.68` contract prerequisite do not implement:

- parser support for `validation runtime-assertion`;
- generated expected-count storage;
- generated beat counters;
- generated validation assertions;
- beat-index public outputs;
- payload storage or multi-beat reassembly;
- per-beat or packed-burst outputs;
- all-beat `RRESP` aggregation;
- per-ID read-data queues;
- same-cycle logical transaction reissue;
- queued/blocking policy, profile aliases, or full-manager syntax;
- direct backend lowering;
- VHDL backend or reroute behavior.

## Validation Gates For `.67`

Because `.67` is documentation/task-tree audit only, validation should run at
least:

- `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_data_burst_length.ppif`
- `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_data_last_beat.ppif`
- `bash knowledge-map/scripts/gen_knowledge_map.sh`
- `mdbook build docs/book`
- `prove -Iperl t/1414-docs-relative-paths-audit.t`
- `bash knowledge-map/scripts/check_knowledge_map.sh`
- `scripts/check_memory_architecture.sh`
- `git --no-pager diff --check`
- stale active `.67` frontier search

## Rollback

This audit changes only documentation, task-tree, mdBook, roadmap, memory, and
Knowledge Map state. Reverting it returns the frontier to `.67`, with `.66`
having shipped generated raw-ARLEN capture but no selected public validation
contract prerequisite.
