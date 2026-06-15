# AXI IAL2 Manager Post Queue-Head Last-Beat Read-Data Next-Slice Selection

Task-tree owner:
`IAL2-FEATURE-COMPLETENESS-FRONTIER.116`.

Date: `2026-06-15`.

## Purpose

This selector follows generated last-beat `RDATA`/`RRESP` capture for the
bounded read burst-last concrete same-ID queue-head demux from `.115` and
chooses the next exact queue-head/read-data expansion.

The selected next owner is `IAL2-FEATURE-COMPLETENESS-FRONTIER.117`:
generated raw-`ARLEN` burst-length capture for the bounded queue-head
last-beat read-data shape.

No parser, generator, PPIF sample, support-accounting, test, generated
artifact, or HDL behavior changes in this selector.

## Evidence Read

- `.115` behavior:
  `docs/AXI_IAL2_MANAGER_QUEUE_HEAD_LAST_BEAT_READ_DATA_BEHAVIOR.md`
- `.114` selector:
  `docs/AXI_IAL2_MANAGER_POST_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION.md`
- `.113` queue-head single-beat read-data behavior:
  `docs/AXI_IAL2_MANAGER_QUEUE_HEAD_READ_DATA_BEHAVIOR_FIRST_SLICE.md`
- auto-ID burst-length metadata:
  `docs/AXI_IAL2_MANAGER_BURST_READ_DATA_BEAT_COUNT_METADATA_FIRST_SLICE.md`
- generated raw-`ARLEN` capture:
  `docs/AXI_IAL2_MANAGER_ARLEN_CAPTURE_BEHAVIOR_FIRST_SLICE.md`
- existing auto-ID multi-beat read-data behavior:
  `docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_OUTPUT_BANK_BEHAVIOR_FIRST_SLICE.md`
- `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`
- `t/1437-axi-ial2-manager-capacity-status-generator.t`
- `t/1436-ial2-ppif-parser-cli.t`
- public PPIF samples for queue-head demux/read-data, auto-ID last-beat
  read-data, auto-ID burst-length, and auto-ID multi-beat read-data.

Live schedule probes confirmed the current shipped surface:

```text
read_last_beat_same_id_queue_head_read_data:
  response_demux.read.response_scope: burst_last
  response_demux.read.generated_queue_behavior_boundary:
    generated_read_burst_last_queue_head_demux
  response_demux.read.transaction_completion_source:
    generated_queue_head_demux
  read_data.read.capture_scope: last_beat
  read_data.read.completion_validity:
    generated_queue_head_response_demux_last_beat_completion_pulse
  read_data.read.burst_length_source: rlast_only
  read_data.read.burst_length_validation: not_generated

read_data_burst_length:
  read_data.read.capture_scope: last_beat
  read_data.read.completion_validity:
    generated_read_response_demux_last_beat_completion_pulse
  read_data.read.burst_length_source: arlen_signal
  read_data.read.burst_length_validation: report_only
```

The implementation already has request-bound raw-`ARLEN` capture rules for
last-beat read-data contracts with `burst-length` metadata. The remaining
queue-head blocker is the explicit fail-closed guard for queue-head last-beat
read-data plus `burst_length` metadata.

## Selection

Select `.117`, generated raw-`ARLEN` burst-length capture for the bounded
queue-head last-beat read-data shape.

The `.117` implementation boundary should be:

- read family only;
- `response-demux.read.response_scope` is `burst-last`;
- the generated queue-head boundary is
  `generated_read_burst_last_queue_head_demux`;
- exactly one duplicate concrete read-ID group;
- exactly two read transactions in that group;
- computed queue depth is `2`;
- `read-data.read.capture_scope` is `last-beat`;
- `read-data.read.completion_source` remains `response-demux`;
- `read-data.read.status_policy` remains `last-beat`;
- `read-data.read.interleaving` remains `last-beat-by-rid`;
- `read-data.read.burst-length` uses `source arlen`, signal width `8`,
  `encoding axlen-plus-one`, `capture request`, and `validation report-only`;
- raw `ARLEN` capture is generated with one storage register and one
  request-guarded capture rule per covered read transaction;
- last-beat `RDATA`/`RRESP` capture keeps the queue-head last-beat completion
  validity:
  `generated_queue_head_response_demux_last_beat_completion_pulse`.

The expected generated burst-length artifacts are the same raw-`ARLEN`
artifact family already used by the auto-ID burst-length sample:

```text
generated_burst_length_inputs:
  - axi0_arlen
generated_burst_length_storage:
  - axi0_r0_arlen_q
  - axi0_r1_arlen_q
generated_burst_length_rules:
  - axi0_r0_burst_length_capture
  - axi0_r1_burst_length_capture
```

Queue-head `burst-length` runtime beat-count validation remains deferred. The
next implementation should reject queue-head `burst-length` contracts with
`validation runtime-assertion` unless it explicitly audits and owns the
queue-head matched-read-beat state needed by the runtime assertions.

## Why This Slice

This is the smallest behavior-bearing expansion after `.115`:

- generated queue-head last-beat read-data already proves the queue-head
  completion source and scalar last-beat payload/status capture;
- generated auto-ID raw-`ARLEN` capture already proves request-bound length
  capture, generated input/storage/rule naming, and schedule-report fields;
- raw-`ARLEN` capture is independent of per-beat output-bank payload storage;
- the implementation can remain one public sample and one bounded queue group.

Multi-beat queue-head read-data is still too broad for the next slice because
it combines queue-head identity with raw-`ARLEN` capture, beat-count/RLAST
validation, beat-index state, per-beat output-bank writes, valid-mask/length
outputs, and scalar `RRESP` aggregation. Deeper or multiple queue groups
require queue generator generalization. Mixed same-family auto-ID plus
concrete queue-head demux crosses response ownership and ID-release
semantics.

## Deferred Work

The following remain outside `.117`:

- queue-head `burst-length` runtime beat-count/RLAST validation;
- multi-beat queue-head read-data capture;
- queue groups deeper than two slots;
- more than one duplicate concrete-ID group;
- same-family mixed auto-ID plus concrete queue-head demux;
- generalized per-ID issue-order queues;
- direct backend lowering;
- VHDL.

## Validation Gates

The `.117` implementation should run focused syntax checks, generator and
PPIF/CLI tests, direct schedule/check/semantic/HDL probes for the new public
sample, regression probes for existing queue-head last-beat read-data,
queue-head single-beat read-data, auto-ID burst-length, auto-ID last-beat,
auto-ID multi-beat, and read burst-last queue-head samples, support-accounting
corpus gates if a new sample is added, Knowledge Map generation/check, mdBook
build, docs path audit, memory architecture check, diff hygiene, README
numbered-index check, and stale frontier scans.

## Rollback

Rollback is documentation-only for this selector: revert this note plus the
`.116` task-tree, README, roadmap, mdBook, Memory, and Knowledge Map updates.
No parser, generator, sample, support-accounting, test, generated artifact, or
HDL behavior is changed by `.116`.
