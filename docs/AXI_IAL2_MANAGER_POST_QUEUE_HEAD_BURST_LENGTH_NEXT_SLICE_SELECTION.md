# AXI IAL2 Manager Post Queue-Head Burst-Length Next-Slice Selection

Task-tree owner:
`IAL2-FEATURE-COMPLETENESS-FRONTIER.118`.

Date: `2026-06-15`.

## Purpose

This selector follows generated report-only raw-`ARLEN` capture for the
bounded read burst-last concrete same-ID queue-head last-beat read-data shape
from `.117` and chooses the next exact queue-head/read-data expansion.

The selected next owner is `IAL2-FEATURE-COMPLETENESS-FRONTIER.119`:
generated queue-head beat-count/`RLAST` runtime validation for the same
bounded queue-head last-beat read-data shape.

No parser, generator, PPIF sample, support-accounting, test, generated
artifact, or HDL behavior changes in this selector.

## Evidence Read

- `.117` behavior:
  `docs/AXI_IAL2_MANAGER_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md`
- `.116` selector:
  `docs/AXI_IAL2_MANAGER_POST_QUEUE_HEAD_LAST_BEAT_READ_DATA_NEXT_SLICE_SELECTION.md`
- `.115` queue-head last-beat read-data behavior:
  `docs/AXI_IAL2_MANAGER_QUEUE_HEAD_LAST_BEAT_READ_DATA_BEHAVIOR.md`
- auto-ID beat-count/`RLAST` runtime validation:
  `docs/AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_RUNTIME_VALIDATION_FIRST_SLICE.md`
- auto-ID multi-beat metadata and output-bank behavior:
  `docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_METADATA_FIRST_SLICE.md`
  and
  `docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_OUTPUT_BANK_BEHAVIOR_FIRST_SLICE.md`
- `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`
- `t/1437-axi-ial2-manager-capacity-status-generator.t`
- `t/1436-ial2-ppif-parser-cli.t`
- public PPIF samples for queue-head burst-length, queue-head last-beat
  read-data, auto-ID runtime-validation burst-length, and auto-ID multi-beat
  read-data.

Live schedule probes confirmed the current shipped surface:

```text
read_last_beat_same_id_queue_head_burst_length:
  response_demux.read.response_scope: burst_last
  response_demux.read.generated_queue_behavior_boundary:
    generated_read_burst_last_queue_head_demux
  response_demux.read.transaction_completion_source:
    generated_queue_head_demux
  read_data.read.capture_scope: last_beat
  read_data.read.completion_validity:
    generated_queue_head_response_demux_last_beat_completion_pulse
  read_data.read.burst_length_source: arlen_signal
  read_data.read.burst_length_validation: report_only
  read_data.read.burst_length_generated_behavior: true
  read_data.residue:
    generated_beat_count_validation
    multi_beat_read_data_reassembly
    per_beat_outputs
    rresp_aggregation

read_data_burst_length_runtime_assertion:
  read_data.read.burst_length_validation: runtime_assertion
  read_data.read.beat_count_validation_generated_behavior: true
  read_data.read.beat_count_match_source:
    response_demux_matched_read_beat
  read_data.read.generated_expected_beat_count_storage:
    axi0_r0_expected_beats_q
    axi0_r1_expected_beats_q
  read_data.read.generated_beat_count_storage:
    axi0_r0_read_beat_count_q
    axi0_r1_read_beat_count_q

read_data_multi_beat:
  read_data.read.capture_scope: multi_beat
  read_data.read.burst_length_validation: runtime_assertion
  read_data.read.beat_count_validation_generated_behavior: true
  read_data.read.multi_beat_reassembly_generated_behavior: true
```

A temporary PPIF variant of the queue-head burst-length sample with
`(validation runtime-assertion)` still fails closed today with:

```text
AXI manager capacity/status IAL2 contract read_data.read queue-head burst_length runtime validation is not supported in this slice
```

The implementation substrate is already close to the needed boundary:

- queue-head read-data coverage now derives transactions and completion
  signals from generated queue-head metadata;
- generated queue-head response states already expose per-transaction
  queue-head match expressions;
- `_read_data_matched_read_beat_expr` uses the raw read response event plus
  the transaction match expression, so queue-head runtime validation can count
  matched beats independently of `RLAST`;
- the current blocker is an explicit normalization guard that rejects
  queue-head `burst_length.validation runtime-assertion`.

No lower IAL1, IAL0, or SystemVerilog prerequisite is evident for the first
bounded queue-head runtime-validation slice.

## Selection

Select `.119`, generated queue-head beat-count/`RLAST` runtime validation for
the bounded queue-head last-beat read-data shape.

The `.119` implementation boundary should be:

- read family only;
- `response-demux.read.response_scope` is `burst-last`;
- the generated queue-head boundary is
  `generated_read_burst_last_queue_head_demux`;
- exactly one duplicate concrete read-ID group;
- exactly two read transactions in that group;
- computed queue depth is `2`;
- `read-data.read.capture_scope` remains `last-beat`;
- `read-data.read.completion_source` remains `response-demux`;
- `read-data.read.status_policy` remains `last-beat`;
- `read-data.read.interleaving` remains `last-beat-by-rid`;
- `read-data.read.burst-length` uses `source arlen`, signal width `8`,
  `encoding axlen-plus-one`, `capture request`, and
  `validation runtime-assertion`;
- raw `ARLEN` capture remains request-bound with one storage register and one
  capture rule per covered read transaction;
- last-beat `RDATA`/`RRESP` capture keeps the queue-head last-beat completion
  validity:
  `generated_queue_head_response_demux_last_beat_completion_pulse`;
- beat-count increments are guarded by the matched queue-head read beat:
  raw read response event plus concrete `RID` plus active queue-head
  transaction identity, without requiring `RLAST`;
- generated runtime assertions cover request-time `ARLEN` bound,
  over-count/extra beat, early `RLAST`, and missing final `RLAST`;
- report JSON should set `burst_length_validation: runtime_assertion`,
  `beat_count_validation_generated_behavior: true`,
  `beat_count_match_source: response_demux_matched_read_beat`, and list the
  expected-count storage, beat-count storage, beat-count rules, and
  assertions.

The expected generated validation artifact family should match the existing
auto-ID runtime-validation names for the same transaction names:

```text
generated_expected_beat_count_storage:
  - axi0_r0_expected_beats_q
  - axi0_r1_expected_beats_q
generated_beat_count_storage:
  - axi0_r0_read_beat_count_q
  - axi0_r1_read_beat_count_q
generated_beat_count_rules:
  - axi0_r0_beat_count_init
  - axi0_r0_read_beat_count
  - axi0_r1_beat_count_init
  - axi0_r1_read_beat_count
generated_beat_count_assertions:
  - axi0_r0_arlen_within_max
  - axi0_r0_read_beat_before_expected_count
  - axi0_r0_rlast_on_expected_beat
  - axi0_r0_expected_final_beat_has_rlast
  - axi0_r1_arlen_within_max
  - axi0_r1_read_beat_before_expected_count
  - axi0_r1_rlast_on_expected_beat
  - axi0_r1_expected_final_beat_has_rlast
```

The existing report-only queue-head burst-length sample must remain behavior
compatible and continue to report no generated beat-count validation state.

## Why This Slice

This is the smallest behavior-bearing expansion after `.117`:

- raw `ARLEN` capture is already generated for the queue-head last-beat shape;
- the auto-ID runtime-validation path already proves expected-count storage,
  beat counters, generated assertions, report fields, and HDL lowering;
- queue-head response state already exposes a matched-read-beat expression
  that counts all accepted beats for the active queue-head transaction and
  leaves `RLAST` as the validation condition;
- multi-beat queue-head read-data should not ship before queue-head
  beat-count/`RLAST` validation exists, because the multi-beat output-bank
  contract depends on reliable beat indexes and expected length.

Directly jumping to multi-beat queue-head read-data would combine runtime
validation, beat-index state, per-beat output-bank writes, valid-mask/length
outputs, and scalar `RRESP` aggregation in one slice.

## Deferred Work

The following remain outside `.119`:

- multi-beat queue-head read-data capture and output banks;
- queue groups deeper than two slots;
- more than one duplicate concrete-ID group;
- same-family mixed auto-ID plus concrete queue-head response demux;
- generalized per-ID issue-order queues;
- packed burst-vector outputs and alternate payload assembly;
- direct backend lowering;
- VHDL.

## Validation Gates

The `.119` implementation should run focused syntax checks, generator and
PPIF/CLI tests, direct schedule/check/semantic/HDL probes for the new public
runtime-validation queue-head sample, regression probes for the report-only
queue-head burst-length sample, queue-head last-beat read-data, queue-head
single-beat read-data, auto-ID runtime-validation burst-length, auto-ID
multi-beat read-data, and read burst-last queue-head samples,
support-accounting corpus gates if a new sample is added, Knowledge Map
generation/check, mdBook build, docs path audit, memory architecture check,
diff hygiene, README numbered-index check, and stale frontier scans.

## Rollback

Rollback is documentation-only for this selector: revert this note plus the
`.118` task-tree, README, roadmap, mdBook, Memory, and Knowledge Map updates.
No parser, generator, sample, support-accounting, test, generated artifact, or
HDL behavior is changed by `.118`.
