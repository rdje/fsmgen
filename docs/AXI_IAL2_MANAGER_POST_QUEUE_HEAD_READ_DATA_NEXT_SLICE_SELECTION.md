# AXI IAL2 Manager Post Queue-Head Read-Data Next-Slice Selection

Task-tree owner:
`IAL2-FEATURE-COMPLETENESS-FRONTIER.114`.

Date: `2026-06-15`.

## Purpose

This selector follows the generated single-beat queue-head read-data behavior
from `.113` and chooses the next exact AXI queue-head/read-data expansion.

The selected next owner is `IAL2-FEATURE-COMPLETENESS-FRONTIER.115`:
generated last-beat `RDATA`/`RRESP` capture for the bounded read burst-last
concrete same-ID queue-head demux shape.

No parser, generator, PPIF sample, support-accounting, test, generated
artifact, or HDL behavior changes in this selector.

## Evidence Read

- `.113` behavior:
  `docs/AXI_IAL2_MANAGER_QUEUE_HEAD_READ_DATA_BEHAVIOR_FIRST_SLICE.md`
- `.112` readiness audit:
  `docs/AXI_IAL2_MANAGER_QUEUE_HEAD_READ_DATA_READINESS_AUDIT.md`
- read burst-last queue-head demux:
  `docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_BEHAVIOR_FIRST_SLICE.md`
- read single-beat queue-head demux:
  `docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md`
- existing generated last-beat read-data behavior:
  `docs/AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_BEHAVIOR_FIRST_SLICE.md`
- existing generated multi-beat read-data behavior:
  `docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_OUTPUT_BANK_BEHAVIOR_FIRST_SLICE.md`
- `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`
- `t/1437-axi-ial2-manager-capacity-status-generator.t`
- `t/1436-ial2-ppif-parser-cli.t`
- public PPIF samples for queue-head demux and read-data behavior.

Live schedule probes confirm the current public samples:

```text
same_id_queue_head_response_demux:
  response_demux.read.response_scope: burst_last
  response_demux.read.generated_queue_behavior_boundary:
    generated_read_burst_last_queue_head_demux
  response_demux.read.generated_completion_signals:
    axi0_r0_complete, axi0_r1_complete

read_single_beat_same_id_queue_head_read_data:
  read_data.read.capture_scope: single_beat
  read_data.read.completion_validity:
    generated_queue_head_response_demux_completion_pulse

read_data_last_beat:
  response_demux.read.transaction_completion_source:
    generated_demux_last_beat
  read_data.read.capture_scope: last_beat
  read_data.read.completion_validity:
    generated_read_response_demux_last_beat_completion_pulse
```

## Selection

Select `.115`, generated last-beat queue-head read-data capture for the
bounded read burst-last concrete same-ID queue-head demux shape.

The `.115` implementation boundary should be:

- read family only;
- `response-demux.read.response_scope` is `burst-last`;
- concrete same-ID queue-head behavior is already generated;
- the queue-head boundary is `generated_read_burst_last_queue_head_demux`;
- exactly one duplicate concrete read-ID group;
- exactly two read transactions in that group;
- computed queue depth is `2`;
- `read-data.read.capture_scope` is `last-beat`;
- `read-data.read.completion_source` remains `response-demux`;
- `read-data.read.status_policy` remains `last-beat`;
- `read-data.read.interleaving` remains `last-beat-by-rid`;
- `RDATA` and `RRESP` are generated inputs with declared widths;
- each transaction gets one generated data output, one generated status
  output, and one normal capture rule guarded by its generated queue-head
  last-beat completion pulse.

The queue-head last-beat path should report:

```text
generated_queue_head_response_demux_last_beat_completion_pulse
```

as the queue-head-specific completion validity. Existing auto-ID last-beat
read-data should keep `generated_read_response_demux_last_beat_completion_pulse`,
and existing queue-head single-beat read-data should keep
`generated_queue_head_response_demux_completion_pulse`.

## Why This Slice

This is the smallest behavior-bearing expansion after `.113`:

- generated read burst-last queue-head demux already exists and already owns
  the `RLAST`-qualified transaction completion pulses;
- generated auto-ID last-beat read-data already proves the scalar
  `RDATA`/`RRESP` capture rule shape for `capture_scope last-beat`;
- `.113` already made read-data transaction coverage source-aware for
  generated queue-head transactions and completion signals;
- no new IAL1, IAL0, or SystemVerilog assignment/port substrate is evident;
- the implementation can remain one public sample and one bounded queue group.

Multi-beat queue-head read-data is intentionally left for later because it
adds request-time `ARLEN` capture, beat-count validation, per-beat output-bank
state, and scalar `RRESP` aggregation on top of queue-head identity. Deeper or
multiple queue groups require queue generator generalization before they are a
safe behavior slice. Mixed same-family auto-ID plus concrete queue-head demux
crosses response ownership and ID-release semantics and remains too broad.

## Deferred Work

The following remain outside `.115`:

- multi-beat queue-head read-data capture;
- queue groups deeper than two slots;
- more than one duplicate concrete-ID group;
- same-family mixed auto-ID plus concrete queue-head demux;
- generalized per-ID issue-order queues;
- report/static residue cleanup not directly required for `.115`;
- direct backend lowering;
- VHDL.

## Validation Gates

The `.115` implementation should run focused syntax checks, generator and
PPIF/CLI tests, direct schedule/check/semantic/HDL probes for the new public
sample, regression probes for existing queue-head single-beat read-data,
auto-ID last-beat read-data, auto-ID multi-beat read-data, and read burst-last
queue-head demux samples, support-accounting corpus gates if a new sample is
added, Knowledge Map generation/check, mdBook build, docs path audit, memory
architecture check, diff hygiene, README numbered-index check, and stale
frontier scans.

## Rollback

Rollback is documentation-only for this selector: revert this note plus the
`.114` task-tree, README, roadmap, mdBook, Memory, and Knowledge Map updates.
No parser, generator, sample, support-accounting, test, generated artifact, or
HDL behavior is changed by `.114`.
