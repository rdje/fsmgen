# AXI IAL2 Manager Post Read Single-Beat Multi-Group Queue-Head Response-Demux Next Slice Selection

Status: selector for `IAL2-FEATURE-COMPLETENESS-FRONTIER.144` on
2026-06-16.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.144`

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.145`, readiness audit for
generated read-data over read single-beat multi-group queue-head response-demux.

No parser, generator, PPIF sample, support-accounting, test, generated
artifact, or HDL behavior changes in this selector slice.

## Evidence Read

The selector read the `.143` behavior note and implementation, `.142`
readiness audit, `.140` write multi-group response-demux behavior, `.124`
read burst-last multi-group response-demux behavior, `.110` read single-beat
one-group response-demux behavior, `.113` one-group queue-head read-data
behavior, `.127` multi-group multi-beat queue-head read-data behavior, and
the scalar burst-last multi-group read-data slices `.130`, `.132`, and `.135`.

It also read the current response-demux, same-ID queue, read-data coverage,
capture, report, and residue code in
`perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; the PPIF read-data
parser; focused generator and PPIF/CLI tests; public PPIF samples; support
accounting; README; roadmap; mdBook; task tree; Memory; and Knowledge Map fact
cards.

## Live Report Findings

The `.143` public sample generates response-demux behavior for two read
single-beat queue groups and intentionally keeps read-data absent:

```text
ppif/axi_manager_capacity_status_read_single_beat_multi_group_same_id_queue_head_response_demux.ppif
  read_demux boundary=generated_read_single_beat_queue_head_demux
  generated=1
  scope=single_beat
  queues=2
  completions=4
  response_demux_residue=read_data_interleaving,bursts
```

The one-group single-beat queue-head read-data sample is generated:

```text
ppif/axi_manager_capacity_status_read_single_beat_same_id_queue_head_read_data.ppif
  read_demux boundary=generated_read_single_beat_queue_head_demux
  queues=1
  completions=2
  read_data completion_validity=generated_queue_head_response_demux_completion_pulse
  read_data transactions=2
```

Adjacent multi-group burst-last queue-head read-data is already generated for
the selected scalar and multi-beat shapes:

```text
ppif/axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_read_data.ppif
  read_demux boundary=generated_read_burst_last_queue_head_demux
  queues=2
  completions=4
  read_data completion_validity=generated_queue_head_response_demux_last_beat_completion_pulse
  read_data transactions=4

ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_read_data.ppif
  read_demux boundary=generated_read_burst_last_queue_head_demux
  queues=2
  completions=4
  read_data output_shape=per_beat_output_bank
  read_data residue=[]
  response_demux residue=[]
```

The support-detail residue still explicitly defers read-data over multiple
read single-beat queue-head groups. That is the current public boundary.

## Code Findings

The current blocker is localized in
`_read_data_response_demux_transaction_coverage`. For generated queue-head
read-data, the function accepts:

- `generated_read_single_beat_queue_head_demux` only for the existing
  exact-one-depth-2-group single-beat shape;
- `generated_read_burst_last_queue_head_demux` for selected last-beat and
  multi-beat multi-group shapes.

The parser already accepts explicit single-beat `read-data` transaction
bindings. The one-group single-beat queue-head read-data capture rules already
guard scalar `RDATA`/`RRESP` assignments by generated queue-head completion
pulses. The `.143` response-demux-only sample already provides one generated
completion signal per covered transaction across multiple groups.

The risk is not a new parser or lowerer prerequisite. The risk is widening
coverage without auditing sample shape, report residue movement, diagnostics
for partial transaction coverage, same-family mixed auto-ID fail-closed
behavior, and preservation of deeper-queue and group-local enqueue deferrals.

## Selection

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.145`, readiness audit for generated
read-data over read single-beat multi-group queue-head response-demux.

The `.145` audit boundary is:

- audit-only, with no behavior changes;
- read family only;
- generated `response-demux.read` boundary
  `generated_read_single_beat_queue_head_demux`;
- `response-scope single-beat`;
- two or more generated duplicate concrete read-ID groups, every group exactly
  two transactions at depth `2`;
- scalar single-beat `RDATA`/`RRESP` capture bindings for every covered
  transaction;
- inspect whether a direct behavior owner can safely widen the queue-head
  read-data coverage gate from exactly one depth-2 group to one-or-more
  depth-2 groups;
- inspect support-accounting, check JSON, semantic JSON, generated HDL,
  report/residue prose, diagnostics, preservation probes, rollback, and
  mdBook/roadmap documentation before any behavior change.

## Deferred Work

The following remain outside `.144` and `.145` unless the audit selects a
separate exact owner:

- implementation behavior changes in `.144`;
- queue groups deeper than two slots;
- same-family mixed auto-ID plus concrete queue-head response demux;
- group-local simultaneous enqueue widening;
- packed burst-vector outputs and alternate payload assembly;
- direct backend lowering;
- VHDL.

## Validation Gates For .145

The audit should run compact schedule/check/semantic probes for:

- `.143` read single-beat multi-group response-demux-only sample;
- one-group single-beat queue-head read-data sample;
- read burst-last multi-group response-demux sample;
- scalar last-beat multi-group queue-head read-data samples, including
  report-only raw-`ARLEN` and runtime-validation variants;
- multi-beat multi-group queue-head read-data sample;
- write multi-group response-demux preservation sample.

It should also inspect focused generator and PPIF/CLI tests, support
accounting, README, roadmap, mdBook, task tree, Memory, Knowledge Map, and
standard continuity gates before selecting a behavior owner or prerequisite.

## Rollback Boundary

Because `.144` is selector-only, rollback is documentation, task-tree, Memory,
and Knowledge Map state only.
