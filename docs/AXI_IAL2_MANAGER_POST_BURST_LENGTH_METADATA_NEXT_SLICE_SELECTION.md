# AXI IAL2 Manager Post Burst-Length Metadata Next Slice Selection

Status: selection complete; no parser, generator, HDL, sample,
support-accounting, check JSON, semantic JSON, or validation behavior changed
by this note.

Owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.64`.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

Builds on:

- [docs/AXI_IAL2_MANAGER_BURST_READ_DATA_BEAT_COUNT_METADATA_FIRST_SLICE.md](AXI_IAL2_MANAGER_BURST_READ_DATA_BEAT_COUNT_METADATA_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_BURST_READ_DATA_BEAT_COUNT_CONTRACT_SELECTION.md](AXI_IAL2_MANAGER_BURST_READ_DATA_BEAT_COUNT_CONTRACT_SELECTION.md)
- [docs/AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_BEHAVIOR_FIRST_SLICE.md](AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_BEHAVIOR_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_BEHAVIOR_FIRST_SLICE.md](AXI_IAL2_MANAGER_RLAST_COMPLETION_BEHAVIOR_FIRST_SLICE.md)

## Evidence Read

The `.63` burst-length sample reports generated last-beat read-data capture
plus report-only ARLEN metadata:

```text
read_data.generated_behavior: true
read_data.read.burst_length_source: arlen_signal
read_data.read.burst_length_signal: axi0_arlen
read_data.read.burst_length_signal_width: 8
read_data.read.burst_length_encoding: axlen_plus_one
read_data.read.burst_length_capture: transaction_request
read_data.read.max_beats: 16
read_data.read.burst_length_generated_behavior: false
read_data.read.burst_length_validation: report_only
read_data.read.beat_storage: none
read_data.read.valid_output: none
read_data.read.length_output: none
```

The generated artifact lists intentionally omit `axi0_arlen`:

```text
generated_inputs:
  - axi0_rdata
  - axi0_rresp
generated_rules:
  - axi0_r0_read_data_capture
  - axi0_r1_read_data_capture
```

The remaining read-data residue for the opt-in ARLEN sample is:

```text
generated_burst_length_capture
generated_beat_count_validation
multi_beat_read_data_reassembly
per_beat_outputs
rresp_aggregation
```

The generated burst-last read response demux already supplies matched
transaction completion pulses on `RID` plus `RLAST`. Same-ID auto transactions
already have selected-ID/busy state, release rules, and same-ID avoidance
assertions. Those surfaces are enough to identify the owning transaction, but
they do not yet store the request-side burst length.

## Selection

The next exact owner is:

```text
IAL2-FEATURE-COMPLETENESS-FRONTIER.65
```

`.65` owns a readiness audit for generated ARLEN burst-length capture.

The intended follow-up behavior, if the audit confirms no prerequisite, is to
make the report-only `burst-length` metadata generate the `ARLEN` input and
bounded per-read-transaction length capture state through the existing
`IAL2 -> IAL1 -> IAL0 -> SystemVerilog` path. That behavior should remove
`generated_burst_length_capture` from opt-in read-data residue while leaving
beat-count/RLAST validation, storage/reassembly, per-beat outputs, `RRESP`
aggregation, per-ID queues, direct backend lowering, and VHDL deferred.

## Why Audit Before Implementation

Generated ARLEN capture is the right next prerequisite because validation and
reassembly need a transaction-local expected length before they can be made
honest. It is still a generated-behavior slice, not just report text:

- it adds a new public HDL input for the opt-in sample;
- it adds per-transaction generated storage or equivalent generated state;
- it binds capture to request-side transaction events, not response beats;
- it must preserve generated last-beat `RDATA`/`RRESP` capture behavior;
- it must avoid claiming expected-beat validation or payload storage.

The existing substrate likely has the needed pieces: generated inputs,
width-bearing generated variables, guarded rule assignments, request-event
guards, generated artifact reports, support-accounted PPIF samples, check JSON,
semantic JSON, and HDL verification. The audit exists to confirm the exact
request-event binding, storage width, raw-ARLEN versus ARLEN-plus-one
representation, generated artifact names, and diagnostics before code changes.

## Required Decisions For `.65`

The audit must decide:

- whether generated capture stores raw `ARLEN` or a derived expected-beat
  value;
- the generated storage name pattern and width;
- whether any arithmetic-width prerequisite exists for `axlen-plus-one`;
- how capture rules bind to per-transaction request events;
- whether same-cycle multi-request ambiguity needs a static diagnostic,
  runtime assertion, or explicit deferral;
- how the schedule report names generated ARLEN input, generated capture
  rules, generated storage, and residue movement;
- what focused generator, PPIF/CLI, support-accounting, semantic, mdBook,
  Knowledge Map, memory, and stale-frontier gates the behavior slice must run.

## Explicit Non-Goals

This selector does not change public syntax, parser behavior, generated
`.isf`, generated `.fsm`, SystemVerilog HDL, support accounting, check JSON,
semantic JSON, or validation behavior.

`.65` is an audit only. Generated ARLEN capture behavior, beat-count/RLAST
validation, beat-index state, bounded storage for all payload beats, per-beat
outputs, all-beat `RRESP` aggregation, full read-data reassembly, per-ID
queues, queued/blocking policy, profile aliases, full-manager behavior, direct
backend lowering, and VHDL remain future exact-owner work until explicitly
selected.

## Validation Gates For `.64`

Because `.64` is documentation/task-tree selection only, validation should run
at least:

- `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_data_burst_length.ppif`
- `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_data_last_beat.ppif`
- `bash knowledge-map/scripts/gen_knowledge_map.sh`
- `mdbook build docs/book`
- `prove -Iperl t/1414-docs-relative-paths-audit.t`
- `bash knowledge-map/scripts/check_knowledge_map.sh`
- `scripts/check_memory_architecture.sh`
- `git --no-pager diff --check`
- stale active `.64` frontier search

## Rollback

This selector changes only documentation, task-tree, mdBook, roadmap, memory,
and Knowledge Map state. Reverting it returns the frontier to `.64`, with
`.63` parser/report metadata and static validation shipped and no generated
ARLEN capture readiness owner selected.
