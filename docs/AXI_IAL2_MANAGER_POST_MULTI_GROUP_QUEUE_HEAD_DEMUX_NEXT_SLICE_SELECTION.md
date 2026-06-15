# AXI IAL2 Manager Post Multi-Group Queue-Head Demux Next Slice Selection

Status: selected next slice.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.125`

Date: `2026-06-15`

## Purpose

This selector follows the `.124` generated multi-group queue-head
response-demux behavior and chooses the next exact IAL2 feature-completeness
owner.

The selected next owner is
`IAL2-FEATURE-COMPLETENESS-FRONTIER.126`: readiness audit for read-data
coverage over multiple generated read burst-last concrete same-ID queue-head
groups.

No parser, generator, PPIF sample, support-accounting, test, generated
artifact, or HDL behavior changes in this selector.

## Evidence Read

- `.124` shipped behavior note:
  `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md`
- `.123` readiness audit:
  `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT.md`
- `.121` queue-head multi-beat read-data behavior:
  `docs/AXI_IAL2_MANAGER_QUEUE_HEAD_MULTI_BEAT_READ_DATA_BEHAVIOR.md`
- current queue-head response-demux, read-data coverage, matched-read-beat,
  multi-beat output-bank, report, and residue code in
  `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`
- focused generator and PPIF/CLI tests for queue-head response demux and
  read-data:
  `t/1437-axi-ial2-manager-capacity-status-generator.t` and
  `t/1436-ial2-ppif-parser-cli.t`
- public queue-head and read-data PPIF samples under `ppif/`
- support accounting, README, roadmap, mdBook, task tree, Memory, and
  Knowledge Map fact cards.

## Live Report Findings

The `.124` public sample now generates response-demux behavior for two read
queue groups and keeps read-data absent:

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
  response_demux.residue:
    read_data_interleaving
    bursts
  read_data: absent
```

The `.121` public sample proves queue-head multi-beat read-data only for one
generated queue group:

```text
ppif/axi_manager_capacity_status_read_multi_beat_same_id_queue_head_read_data.ppif
  response_demux.read.generated_queue_behavior_boundary:
    generated_read_burst_last_queue_head_demux
  response_demux.read.same_id_issue_order_queues:
    - concrete_id: 3
      transactions: [r0, r1]
      depth: 2
  read_data.read.capture_scope: multi_beat
  read_data.read.output_shape: per_beat_output_bank
  read_data.read.completion_validity:
    generated_queue_head_response_demux_last_beat_completion_pulse
  read_data.residue: []
  response_demux.residue: []
```

## Code Findings

The current read-data coverage gate is explicit and local:
`_read_data_response_demux_transaction_coverage` accepts generated queue-head
read-data only when `response_demux.read.same_id_issue_order_queues` contains
exactly one depth-2 read queue group. That guard is what keeps `.124`
response-demux-only.

The downstream substrate already has useful pieces for a future implementation:

- `_same_id_issue_order_queue_response_states_for_family` iterates all
  generated queue groups and emits one matched-read-beat response state per
  transaction.
- queue-head multi-beat read-data already uses
  `response_demux_matched_read_beat`, per-transaction beat counters,
  per-transaction output banks, valid-mask and length outputs, scalar `RRESP`
  aggregation, and runtime beat-count/`RLAST` validation for the one-group
  sample.
- generated queue names include the concrete ID value, and generated read-data
  artifact names are transaction-local, so the obvious naming surface can
  represent more than one group.

The risk is not a missing scalar rule/lowerer substrate. The risk is the
semantic widening: coverage must flatten all generated groups into one
transaction set, preserve one generated completion signal per transaction,
prove diagnostics for partial read-data coverage, define report residue
movement, and keep the existing family-wide admitted-request onehot boundary.

## Selection

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.126`, readiness audit for
read-data coverage over multiple generated read burst-last concrete same-ID
queue-head groups.

The `.126` audit boundary is:

- audit-only, with no behavior changes;
- read family only;
- generated `response-demux.read` boundary
  `generated_read_burst_last_queue_head_demux`;
- two or more generated duplicate concrete read-ID groups, every group exactly
  two transactions at depth `2`;
- inspect whether first behavior should cover last-beat, multi-beat, or a
  narrower prerequisite before enabling all queue-head read-data shapes;
- inspect transaction/output naming, generated completion-signal mapping,
  matched-read-beat state lookup, burst-length/runtime-validation artifacts,
  report residue, diagnostics, support accounting, rollback, and preservation
  probes;
- keep same-family auto-ID plus concrete queue-head demux, deeper queues,
  write-family or read single-beat multiple-group behavior, packed burst-vector
  outputs, alternate payload assembly, direct backend, and VHDL deferred.

## Validation Gates For .126

The audit slice should run:

- compact live schedule probes for the `.124` multi-group response-demux
  sample and the `.121` one-group queue-head multi-beat read-data sample;
- a fail-closed probe or code review confirming the exact one-group read-data
  coverage guard still owns the current blocker;
- Knowledge Map generation/check, mdBook build, docs path audit, memory
  architecture check, diff hygiene, README numbering, and stale/positive
  frontier scans.

## Rollback Boundary

Because `.125` is selector-only, rollback is documentation, task-tree, Memory,
and Knowledge Map state only.

## Deferred Work

The following remain outside `.125` and `.126` until the audit selects a
behavior owner:

- generated read-data over multiple queue-head groups;
- queue groups deeper than two slots;
- same-family mixed auto-ID plus concrete queue-head response demux;
- write-family multiple-group queue-head behavior;
- read single-beat multiple-group queue-head behavior;
- packed burst-vector outputs and alternate payload assembly;
- direct backend lowering;
- VHDL.
