# AXI IAL2 Manager Beat-Count/RLAST Runtime-Validation Contract Selection

Status: selected public contract; no parser, generator, HDL, sample,
support-accounting, check JSON, semantic JSON, or validation behavior changed
by this note.

Owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.68`.

Implementation status: `IAL2-FEATURE-COMPLETENESS-FRONTIER.69` later shipped
the first behavior-bearing runtime-validation slice; see
[docs/AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_RUNTIME_VALIDATION_FIRST_SLICE.md](AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_RUNTIME_VALIDATION_FIRST_SLICE.md).

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

Builds on:

- [docs/AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_VALIDATION_READINESS_AUDIT.md](AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_VALIDATION_READINESS_AUDIT.md)
- [docs/AXI_IAL2_MANAGER_ARLEN_CAPTURE_BEHAVIOR_FIRST_SLICE.md](AXI_IAL2_MANAGER_ARLEN_CAPTURE_BEHAVIOR_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_BEHAVIOR_FIRST_SLICE.md](AXI_IAL2_MANAGER_RLAST_COMPLETION_BEHAVIOR_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_BEHAVIOR_FIRST_SLICE.md](AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_BEHAVIOR_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_BURST_READ_DATA_BEAT_COUNT_METADATA_FIRST_SLICE.md](AXI_IAL2_MANAGER_BURST_READ_DATA_BEAT_COUNT_METADATA_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_BURST_READ_DATA_BEAT_COUNT_CONTRACT_SELECTION.md](AXI_IAL2_MANAGER_BURST_READ_DATA_BEAT_COUNT_CONTRACT_SELECTION.md)

## Purpose

This selector chooses the explicit public validation mode for generated AXI
read-data beat-count and `RLAST` runtime assertions.

The `.67` audit found the lower layers ready after generated raw-ARLEN
capture, but it also found a public-contract blocker: the checked-in syntax
currently says `validation report-only`, and that spelling means metadata
only. It must not silently become runtime checking behavior.

This slice selects only the public contract. It does not parse new syntax,
change schedule JSON, generate counters, add assertions, or change HDL.

## Selected Public Syntax

The existing ARLEN-based `burst-length` clause gains one additional
validation mode:

```text
(burst-length
  (source arlen)
  (signal axi0_arlen (width 8))
  (encoding axlen-plus-one)
  (capture request)
  (max-beats 16)
  (validation runtime-assertion))
```

The existing mode remains valid and keeps its current behavior:

```text
(validation report-only)
```

The selected normalized report spellings are:

```text
report-only        -> report_only
runtime-assertion  -> runtime_assertion
```

`runtime-assertion` is behavior-bearing. A future implementation must not
accept that spelling as a metadata-only mode. Parser support, report metadata,
generated expected-count state, generated beat-count state, generated rules,
generated assertions, tests, and docs should ship together in the next exact
owner.

## Contract Meaning

`validation report-only` means:

- keep reporting ARLEN/max-beats metadata;
- keep generated raw-ARLEN capture behavior when the ARLEN contract is present;
- do not generate expected-count storage;
- do not generate response beat counters;
- do not generate missing, extra, early-`RLAST`, late-`RLAST`, or ARLEN-bound
  runtime assertions;
- keep `generated_beat_count_validation` in read-data residue.

`validation runtime-assertion` means:

- derive the expected beat count from captured raw `ARLEN + 1`;
- generate per-covered-transaction expected-count storage;
- generate per-covered-transaction matched read-response beat-count state;
- count every accepted read response beat whose `RID` matches the active
  transaction, regardless of `RLAST`;
- generate runtime assertions for the selected beat-count/`RLAST` checks;
- report generated validation artifacts explicitly;
- remove `generated_beat_count_validation` from read-data residue.

## Static Contract

The implementation owner must preserve the current structural constraints and
extend only the validation-mode choice:

- `runtime-assertion` is accepted only under `read-data.read.burst-length`;
- the surrounding `read-data` contract must be `capture-scope last-beat`;
- the surrounding response demux must be generated
  `response_scope burst_last`;
- the burst-length source must be `arlen`;
- the ARLEN signal width must be 8;
- the encoding must be `axlen-plus-one`;
- the capture boundary must be `request`;
- `max-beats` remains required and in `1..256`;
- malformed, duplicate, or unknown validation clauses fail closed;
- unsupported validation spellings fail closed;
- single-beat read-data, missing burst-last response demux, non-ARLEN sources,
  non-request capture, or missing transaction coverage fail closed before
  generation.

The generated expected-count and beat-count state widths must represent the
inclusive range `0..max_beats`, not just raw 8-bit ARLEN. The selected width
formula is:

```text
ceil(log2(max_beats + 1))
```

Examples:

```text
max-beats 16  -> width 5
max-beats 256 -> width 9
```

## Generated Behavior Boundary

The first implementation should stay inside the current single-active
auto-ID transaction boundary. It should not introduce per-ID response queues,
payload storage, or multi-beat reassembly.

For each covered read transaction, generated IAL1 should add:

- one expected-beat-count variable, for example
  `axi0_r0_expected_beats_q`;
- one matched-read-beat counter, for example
  `axi0_r0_read_beat_count_q`;
- request-event rules that initialize expected count and beat count;
- matched-response-beat rules that increment the counter on every accepted
  beat for the active matching `RID`;
- `+assert` carriers for request-time bounds, over-count, early `RLAST`, and
  missing final `RLAST`.

The matched response beat source is the response-demux accepted-beat match:

```text
response_event
AND transaction_active
AND response_id_signal == selected_id_signal
```

It must not require `RLAST`, because `RLAST` is the condition under
validation.

## Assertion Semantics

Recommended per-transaction assertion names are:

```text
axi0_r0_arlen_within_max
axi0_r0_read_beat_before_expected_count
axi0_r0_rlast_on_expected_beat
axi0_r0_expected_final_beat_has_rlast
```

The assertion set must distinguish:

- request-time raw ARLEN exceeding `max_beats - 1`;
- a matched read response beat arriving after the expected count is already
  exhausted;
- `RLAST` asserted before the expected final beat;
- the expected final beat arriving without `RLAST`.

If the beat counter stores the number of already accepted matched beats before
the current beat, the current beat is the final expected beat when:

```text
beat_count_q + 1 == expected_beats_q
```

That expression should drive both the early-`RLAST` and missing-final-`RLAST`
assertions.

## Report Contract

When the implementation ships, schedule JSON for a runtime-assertion contract
should report:

```text
read_data:
  read:
    burst_length_validation: runtime_assertion
    beat_count_validation_generated_behavior: true
    expected_beat_count_encoding: arlen_plus_one
    beat_count_match_source: response_demux_matched_read_beat
    beat_count_width: 5
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

Per-transaction report entries should name that transaction's expected-count
storage, beat-count storage, generated rules, and generated assertions.

For `validation report-only`, the schedule report remains unchanged from the
current shipped behavior:

```text
burst_length_validation: report_only
beat_storage: none
valid_output: none
length_output: none
```

## Residue Movement

For `validation runtime-assertion`, read-data residue should remove:

```text
generated_beat_count_validation
```

and keep:

```text
multi_beat_read_data_reassembly
per_beat_outputs
rresp_aggregation
```

`beat_storage`, `valid_output`, and `length_output` remain `none` unless a
later owner selects public output behavior. Runtime validation does not imply
payload storage or reassembly.

## Selected Implementation Owner

This selector chose the following implementation owner:

```text
IAL2-FEATURE-COMPLETENESS-FRONTIER.69
```

`.69` owns, and later shipped, the first implementation slice for
`(validation runtime-assertion)`. It adds parser support and generated runtime
validation behavior together, because accepting the spelling without emitting
the selected assertions would misrepresent the public contract.

## Explicit Deferrals

This selector does not implement:

- parser support for `(validation runtime-assertion)`;
- schedule JSON changes;
- generated expected-count storage;
- generated beat-count counters;
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

## Validation Gates For `.68`

Because `.68` is contract selection only, validation should run at least:

- `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_data_burst_length.ppif`
- `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_data_last_beat.ppif`
- `bash knowledge-map/scripts/gen_knowledge_map.sh`
- `mdbook build docs/book`
- `prove -Iperl t/1414-docs-relative-paths-audit.t`
- `bash knowledge-map/scripts/check_knowledge_map.sh`
- `scripts/check_memory_architecture.sh`
- `git --no-pager diff --check`
- stale active `.68` frontier search

## Rollback

This selector changes only documentation, task-tree, mdBook, roadmap, memory,
and Knowledge Map state. Reverting it returns the frontier to `.68`, with
`.67` having selected public runtime-validation contract selection but no
concrete validation-mode contract recorded.
