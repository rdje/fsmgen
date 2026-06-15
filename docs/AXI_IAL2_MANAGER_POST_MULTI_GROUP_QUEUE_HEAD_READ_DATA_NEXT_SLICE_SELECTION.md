# AXI IAL2 Manager Post Multi-Group Queue-Head Read-Data Next Slice Selection

Status: selected next slice.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.128`

Date: `2026-06-15`

## Purpose

This selector follows the `.127` generated multi-group queue-head multi-beat
read-data output-bank behavior and chooses the next exact AXI manager
feature-completeness owner.

The selected next owner is `IAL2-FEATURE-COMPLETENESS-FRONTIER.129`:
readiness audit for last-beat-only read-data over multiple generated read
burst-last concrete same-ID queue-head groups.

No parser, generator, PPIF sample, support-accounting, test, generated
artifact, or HDL behavior changes in this selector.

## Evidence Read

- `.127` behavior:
  `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_READ_DATA_BEHAVIOR.md`
- `.126` readiness audit:
  `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_READ_DATA_READINESS_AUDIT.md`
- `.124` multi-group response-demux behavior:
  `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md`
- `.121` queue-head multi-beat read-data behavior:
  `docs/AXI_IAL2_MANAGER_QUEUE_HEAD_MULTI_BEAT_READ_DATA_BEHAVIOR.md`
- current response-demux, same-ID queue, read-data coverage, report, and
  residue code in `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`
- focused generator and PPIF/CLI tests:
  `t/1437-axi-ial2-manager-capacity-status-generator.t` and
  `t/1436-ial2-ppif-parser-cli.t`
- public queue-head and read-data PPIF samples under `ppif/`
- support accounting, README, roadmap, mdBook, task tree, Memory, and
  Knowledge Map fact cards.

## Live Report Findings

The `.127` public sample is the current residue-clean multi-group read-data
shape:

```text
ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_read_data.ppif
  response_demux.read.generated_queue_behavior_boundary:
    generated_read_burst_last_queue_head_demux
  response_demux.read.same_id_issue_order_queues:
    - concrete_id: 3
      transactions: [r0, r1]
      depth: 2
    - concrete_id: 5
      transactions: [r2, r3]
      depth: 2
  read_data.read.capture_scope: multi_beat
  read_data.read.completion_validity:
    generated_queue_head_response_demux_last_beat_completion_pulse
  read_data.read.beat_match_source:
    response_demux_matched_read_beat
  read_data.read.output_shape: per_beat_output_bank
  read_data.read.transactions: [r0, r1, r2, r3]
  read_data.residue: []
  response_demux.residue: []
```

The `.124` public sample remains response-demux-only:

```text
ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_response_demux.ppif
  response_demux.read.generated_queue_behavior_boundary:
    generated_read_burst_last_queue_head_demux
  response_demux.read.same_id_issue_order_queues:
    - concrete_id: 3
      transactions: [r0, r1]
      depth: 2
    - concrete_id: 5
      transactions: [r2, r3]
      depth: 2
  read_data: absent
  response_demux.residue:
    read_data_interleaving
    bursts
```

The `.121` public sample preserves one-group queue-head multi-beat read-data:

```text
ppif/axi_manager_capacity_status_read_multi_beat_same_id_queue_head_read_data.ppif
  response_demux.read.same_id_issue_order_queues:
    - concrete_id: 3
      transactions: [r0, r1]
      depth: 2
  read_data.read.capture_scope: multi_beat
  read_data.read.output_shape: per_beat_output_bank
  read_data.residue: []
  response_demux.residue: []
```

## Code Findings

`_read_data_response_demux_transaction_coverage` now deliberately permits
multiple generated queue-head groups only for `capture_scope multi-beat`.
`single-beat` and `last-beat` queue-head read-data still require exactly one
depth-2 concrete same-ID read queue group.

The downstream scalar last-beat capture substrate is likely small enough for a
future implementation: read-data output bindings are transaction-local,
generated completion signals are already mapped per transaction, and the
scalar capture rule simply uses the generated last-beat completion pulse.

The risk is boundary control. The coverage helper currently receives response
demux metadata and capture scope before later normalization records whether
`burst_length` metadata is present and whether validation is report-only or
runtime-assertion. Broadening every `last-beat` queue-head group would also
enable report-only raw-`ARLEN` and runtime-validation-only variants unless the
next implementation owner adds an explicit gate for the selected public
shape.

## Selection

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.129`, readiness audit for
last-beat-only read-data over multiple generated read burst-last concrete
same-ID queue-head groups.

The `.129` audit boundary is:

- audit-only, with no behavior changes;
- read family only;
- generated `response-demux.read` boundary
  `generated_read_burst_last_queue_head_demux`;
- two or more generated duplicate concrete read-ID groups, every group exactly
  two transactions at computed depth `2`;
- first candidate behavior is scalar `capture_scope last-beat` with
  per-transaction `data_output` and `status_output` bindings for every covered
  transaction;
- inspect whether the implementation can keep report-only raw-`ARLEN`,
  runtime-validation-only, and multi-beat output-bank variants as separate
  selected owners;
- preserve `.127` multi-group multi-beat behavior, `.124` response-demux-only
  behavior, and `.121` one-group multi-beat behavior;
- keep deeper queues, same-family mixed auto-ID plus concrete queue-head
  demux, write-family or read single-beat multi-group behavior, group-local
  enqueue boundary refinement, packed burst-vector outputs, alternate payload
  assembly, direct backend, and VHDL deferred.

## Why This Slice

Last-beat-only multi-group read-data is the narrowest useful payload expansion
after `.127`. It reuses the already generated last-beat queue-head completion
pulses and scalar `RDATA`/`RRESP` capture surface, but it does not require
new queue topology, output-bank shape, packed burst payloads, group-local
enqueue semantics, mixed auto-ID demux, direct backend lowering, or VHDL work.

It still needs an audit first because a naive guard relaxation can widen more
than the selected scalar last-beat shape.

## Validation Gates For .129

The audit slice should run:

- compact live schedule probes for the `.127` multi-group read-data sample,
  the `.124` multi-group response-demux-only sample, the `.121` one-group
  queue-head multi-beat sample, and the one-group queue-head last-beat sample;
- code review or a temporary fail-closed probe confirming current last-beat
  multi-group read-data remains blocked before implementation;
- explicit inspection of how to gate multi-group last-beat coverage without
  admitting report-only raw-`ARLEN` or runtime-validation-only variants;
- Knowledge Map generation/check, mdBook build, docs path audit, memory
  architecture check, diff hygiene, README numbering, and stale/positive
  frontier scans.

## Rollback Boundary

Because `.128` is selector-only, rollback is documentation, task-tree, Memory,
and Knowledge Map state only.

## Deferred Work

The following remain outside `.128` and `.129`:

- report-only raw-`ARLEN` and runtime-validation-only multi-group queue-head
  read-data variants;
- deeper concrete same-ID issue-order queues;
- same-family mixed auto-ID plus concrete queue-head demux;
- write-family multiple-group queue-head behavior;
- read single-beat multiple-group queue-head behavior;
- group-local enqueue boundary refinement;
- packed burst-vector outputs and alternate payload assembly;
- direct backend lowering;
- VHDL.
