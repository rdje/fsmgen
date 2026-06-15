# AXI IAL2 Manager Post Queue-Head Multi-Beat Next-Slice Selection

Task-tree owner:
`IAL2-FEATURE-COMPLETENESS-FRONTIER.122`.

Date: `2026-06-15`.

## Purpose

This selector follows generated queue-head multi-beat read-data output-bank
behavior for the bounded read burst-last concrete same-ID queue-head sample
from `.121` and chooses the next exact queue-head/read-data expansion.

The selected next owner is `IAL2-FEATURE-COMPLETENESS-FRONTIER.123`: a
readiness audit for multiple independent read burst-last depth-2 concrete
same-ID queue-head response-demux groups.

No parser, generator, PPIF sample, support-accounting, test, generated
artifact, or HDL behavior changes in this selector.

## Evidence Read

- `.121` behavior:
  `docs/AXI_IAL2_MANAGER_QUEUE_HEAD_MULTI_BEAT_READ_DATA_BEHAVIOR.md`
- `.120` selector:
  `docs/AXI_IAL2_MANAGER_POST_QUEUE_HEAD_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION.md`
- `.119` runtime-validation behavior:
  `docs/AXI_IAL2_MANAGER_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md`
- auto-ID multi-beat output-bank and scalar `RRESP` aggregation behavior:
  `docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_OUTPUT_BANK_BEHAVIOR_FIRST_SLICE.md`
  and
  `docs/AXI_IAL2_MANAGER_RRESP_AGGREGATION_BEHAVIOR_FIRST_SLICE.md`
- current response-demux, same-ID queue, read-data coverage, and report code in
  `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`
- focused generator and PPIF/CLI tests:
  `t/1437-axi-ial2-manager-capacity-status-generator.t` and
  `t/1436-ial2-ppif-parser-cli.t`
- public queue-head, read-data, and burst-length PPIF samples under `ppif/`
- support accounting, README, roadmap, mdBook, task tree, Memory, and
  Knowledge Map fact cards.

Live schedule probes confirmed the current shipped surface:

```text
read_multi_beat_same_id_queue_head_read_data:
  response_demux.read.generated_queue_behavior_boundary:
    generated_read_burst_last_queue_head_demux
  response_demux.read.transaction_completion_source:
    generated_queue_head_demux
  response_demux.residue: []
  read_data.read.capture_scope: multi_beat
  read_data.read.completion_validity:
    generated_queue_head_response_demux_last_beat_completion_pulse
  read_data.read.beat_match_source:
    response_demux_matched_read_beat
  read_data.read.output_shape: per_beat_output_bank
  read_data.read.valid_output: per_transaction_valid_mask
  read_data.read.length_output: per_transaction_beat_count
  read_data.read.status_aggregation: worst_observed
  read_data.residue: []
  same_id_ordering.residue:
    per_id_issue_order_queues

read_last_beat_same_id_queue_head_burst_length_runtime_assertion:
  response_demux.read.generated_queue_behavior_boundary:
    generated_read_burst_last_queue_head_demux
  read_data.read.capture_scope: last_beat
  read_data.read.burst_length_validation: runtime_assertion
  read_data.read.beat_count_validation_generated_behavior: true
  read_data.residue:
    multi_beat_read_data_reassembly
    per_beat_outputs
    rresp_aggregation

read_data_multi_beat:
  response_demux.read.generated_queue_behavior_boundary:
    generated_read_burst_last_auto_id_demux
  read_data.read.output_shape: per_beat_output_bank
  read_data.read.status_aggregation: worst_observed
  read_data.residue: []
  same_id_ordering.residue:
    concrete_id_same_id_ordering
    per_id_issue_order_queues
```

The `.121` bounded sample clears the local read-data and response-demux
residue. The remaining honest expansion surface is queue topology, not
payload lane storage.

## Selection

Select `.123`, readiness audit for multiple independent read burst-last
depth-2 concrete same-ID queue-head response-demux groups.

The `.123` audit boundary should be:

- read family only;
- `response-demux.read.response_scope` is `burst-last`;
- generated queue-head response demux only, not read-data consumption;
- two or more duplicate concrete read-ID groups in the same manager object;
- every covered group has exactly two read transactions and computed depth
  `2`;
- no same-family auto-ID read response demux;
- no write-family expansion;
- no read `single-beat` expansion;
- no queue depth greater than `2`;
- no mixed `single-beat` and `burst-last` response scopes in the same audit;
- no packed burst-vector outputs or alternate payload assembly;
- no direct backend or VHDL work.

The audit must decide whether `.124` can implement that exact response-demux
shape or whether a narrower prerequisite is needed first.

## Why This Slice

The next useful risk boundary after `.121` is queue topology:

- `.121` proves the bounded read burst-last queue-head path can drive
  multi-beat payload/status output banks with empty local read-data and
  response-demux residue;
- the current queue behavior is intentionally limited to exactly one duplicate
  concrete-ID group per generated queue-head family;
- the compact one-hot transaction-slot representation is per group, so a
  read-only, burst-last-only, depth-2 multi-group audit can inspect whether the
  existing group-local naming, storage, transitions, assertions, completion
  pulses, report residue, and lowerer behavior scale without changing the
  payload contract.

This is narrower than deeper queues, mixed auto-ID plus concrete queue-head
demux, or read-data over multiple groups. It also avoids new public output
shapes.

## Deferred Work

The following remain outside `.123`:

- queue depths greater than two slots;
- generated read-data capture over multiple queue-head groups;
- same-family mixed auto-ID plus concrete queue-head response demux;
- write-family multi-group queue-head response demux;
- read `single-beat` multi-group queue-head response demux;
- generalized per-ID issue-order queues;
- packed burst-vector outputs and alternate payload assembly;
- aggregate-only status output shapes beyond the selected scalar aggregation
  path;
- direct backend lowering;
- VHDL.

## Validation Gates

The `.123` audit should run live schedule probes for the `.121` queue-head
multi-beat sample, `.119` queue-head runtime-validation sample, existing
queue-head response-demux/read-data/burst-length samples, and auto-ID
multi-beat sample. If the audit creates temporary multi-group probes, they
must remain outside tracked source unless a later implementation owner selects
them. The slice should also run Knowledge Map generation/check, mdBook build,
docs path audit, memory architecture check, diff hygiene, README numbering,
and stale frontier scans.

## Rollback

Rollback is documentation-only for this selector: revert this note plus the
`.122` task-tree, README, roadmap, mdBook, Memory, and Knowledge Map updates.
No parser, generator, PPIF sample, support-accounting, test, generated
artifact, or HDL behavior is changed by `.122`.
