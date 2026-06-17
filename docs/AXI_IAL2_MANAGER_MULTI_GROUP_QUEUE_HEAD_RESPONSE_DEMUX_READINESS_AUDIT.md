# AXI IAL2 Manager Multi-Group Queue-Head Response-Demux Readiness Audit

Task-tree owner:
`IAL2-FEATURE-COMPLETENESS-FRONTIER.123`.

Date: `2026-06-15`.

## Purpose

This audit follows the `.122` selector and checks whether the existing AXI
manager same-ID queue-head response-demux path can safely widen from one
duplicate concrete read-ID group to multiple duplicate concrete read-ID groups.

The selected next owner is `IAL2-FEATURE-COMPLETENESS-FRONTIER.124`: generated
multiple independent read burst-last depth-2 concrete same-ID queue-head
response-demux groups.

No parser, generator, PPIF sample, support-accounting, test, generated
artifact, or HDL behavior changes in this audit.

## Evidence Read

- `.122` selector:
  `docs/AXI_IAL2_MANAGER_POST_QUEUE_HEAD_MULTI_BEAT_NEXT_SLICE_SELECTION.md`
- `.121` queue-head multi-beat read-data behavior:
  `docs/AXI_IAL2_MANAGER_QUEUE_HEAD_MULTI_BEAT_READ_DATA_BEHAVIOR.md`
- `.120` selector:
  `docs/AXI_IAL2_MANAGER_POST_QUEUE_HEAD_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION.md`
- `.119` queue-head runtime-validation behavior:
  `docs/AXI_IAL2_MANAGER_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md`
- first read burst-last queue-head behavior:
  `docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_BEHAVIOR_FIRST_SLICE.md`
- admitted request pulse and enqueue-boundary notes:
  `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_ADMITTED_REQUEST_PULSES_FIRST_SLICE.md`
  and
  `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_ADMITTED_ENQUEUE_BOUNDARY_AUDIT.md`
- current queue-head plan, duplicate concrete group detection, queue behavior,
  read-data coverage, report residue, and assertion code in
  `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`
- focused generator and PPIF/CLI tests:
  `t/1437-axi-ial2-manager-capacity-status-generator.t` and
  `t/1436-ial2-ppif-parser-cli.t`
- public queue-head, read-data, burst-length, runtime-validation, and
  support-accounted PPIF samples under `ppif/`
- support accounting, README, roadmap, mdBook, task tree, Memory, and
  Knowledge Map fact cards.

## Current Behavior

The existing public one-group queue-head response-demux sample remains fully
generated:

```text
ppif/axi_manager_capacity_status_same_id_queue_head_response_demux.ppif
  response_demux.read.generated_behavior: true
  response_demux.read.generated_queue_behavior_boundary:
    generated_read_burst_last_queue_head_demux
  response_demux.residue:
    read_data_interleaving
    bursts
  same_id_ordering.residue:
    per_id_issue_order_queues
```

The `.121` queue-head multi-beat read-data sample also remains generated and
residue-clean for its local response-demux and read-data surfaces:

```text
ppif/axi_manager_capacity_status_read_multi_beat_same_id_queue_head_read_data.ppif
  response_demux.read.generated_queue_behavior_boundary:
    generated_read_burst_last_queue_head_demux
  read_data.read.capture_scope: multi_beat
  read_data.read.output_shape: per_beat_output_bank
  read_data.read.completion_validity:
    generated_queue_head_response_demux_last_beat_completion_pulse
  response_demux.residue: []
  read_data.residue: []
```

An in-memory two-group read burst-last probe with `r0`/`r1` sharing concrete
`RID` `3` and `r2`/`r3` sharing concrete `RID` `5` is accepted as a selected
same-ID queue-head contract, but remains selected-not-generated:

```text
response_demux.read.generated_behavior: false
same_id_ordering.read.generated_queue_behavior: false
selected completion signals:
  axi0_r0_complete
  axi0_r1_complete
  axi0_r2_complete
  axi0_r3_complete
planned queue groups:
  read_id3: r0, r1, depth 2
  read_id5: r2, r3, depth 2
response_demux.residue:
  generated_same_id_queue_head_demux
  read_data_interleaving
  bursts
same_id_ordering.residue:
  concrete_id_same_id_ordering
  per_id_issue_order_queues
```

That is the expected pre-`.124` state.

## Code Findings

The queue-head planning path is already multi-group aware:

- `_response_demux_queue_head_plan_for_family` records all duplicate concrete
  read-ID groups and all selected completion signals for the selected family.
- `_same_id_duplicate_concrete_groups` groups concrete transactions by concrete
  ID and emits one planned queue group per duplicated concrete value.
- The report path can already carry more than one `generated_queues` entry.

The generation blocker is intentionally narrow:

- `_build_same_id_issue_order_queue_behavior` currently rejects
  `@$groups != 1`.
- After behavior exists, the queue storage, transition-rule, assertion,
  response-state, response-demux rule, report, and residue helpers are already
  structured around group iteration.
- The group-local generated names already include the concrete ID value, for
  example `axi0_read_id3_*` and `axi0_read_id5_*`, so two groups do not collide
  when they use distinct concrete ID values.

The existing admitted-request boundary must remain explicit:

- admitted request pulse generation emits a family-wide
  `*_issue_order_queue_request_onehot0` assertion across all selected concrete
  read transactions in the family;
- `.124` may therefore generate multiple groups under the current
  one-admitted-read-request-per-cycle capacity/status contract;
- `.124` must not claim group-local simultaneous same-cycle enqueue support for
  different concrete IDs.

Read-data remains intentionally narrower:

- the queue-head read-data coverage path still requires one duplicate concrete
  read-ID group of two transactions;
- `.124` must not enable read-data capture over multiple queue-head groups.

## Selection

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.124`, generated multiple
independent read burst-last depth-2 concrete same-ID queue-head
response-demux groups.

The `.124` implementation boundary is:

- read family only;
- `response-demux.read.response_scope` is `burst-last`;
- generated queue-head response demux only, not read-data consumption;
- two or more duplicate concrete read-ID groups in the same manager object;
- every covered group has exactly two read transactions and computed depth
  `2`;
- generated compact one-hot queue storage, queue update rules, assertions,
  response-demux rules, and completion pulse outputs per group;
- group names include the concrete read ID value and transaction name;
- existing family-wide admitted-request onehot remains the admission contract;
- generated reports list all generated queues and remove
  `generated_same_id_queue_head_demux` residue for the covered response-demux
  family;
- no same-family auto-ID read response demux;
- no read-data capture over multiple groups;
- no write-family expansion;
- no read `single-beat` expansion;
- no queue depth greater than `2`;
- no packed burst-vector outputs or alternate payload assembly;
- no direct backend or VHDL work.

`.124` should add a public support-accounted PPIF sample with two duplicate
concrete read-ID groups, for example `r0`/`r1` at concrete `RID` `3` and
`r2`/`r3` at concrete `RID` `5`, and no read-data clause.

## Validation Gates For .124

The implementation slice should run:

- syntax checks for touched Perl modules and focused tests;
- focused generator and PPIF/CLI suites;
- direct `--emit-schedule-json`, `--strict --check --json`,
  `--strict --emit-semantic-json`, and `--quiet --verify-hdl` probes for the new
  multi-group public PPIF sample;
- preservation probes for existing read burst-last queue-head, read
  single-beat queue-head, write queue-head, queue-head read-data, queue-head
  burst-length, queue-head runtime-validation, and queue-head multi-beat
  read-data samples;
- support-accounting corpus gates after adding the sample;
- Knowledge Map generation/check, mdBook build, docs path audit, memory
  architecture check, diff hygiene, README numbering, and stale/positive
  frontier scans.

## Rollback Boundary

Because `.123` is audit-only, rollback is documentation and task-tree state
only.

For `.124`, rollback should be the new public PPIF sample, support-accounting
entry, focused tests, and the builder/report widening that turns multi-group
queue-head response-demux from selected-not-generated into generated behavior.

## Deferred Work

The following remain outside `.124`:

- read-data capture over multiple queue-head groups;
- additional queue-depth widening beyond the later selected one-group
  depth-3 read single-beat response-demux/read-data shapes;
- same-family mixed auto-ID plus concrete queue-head response demux;
- write-family multi-group queue-head response demux;
- read `single-beat` multi-group queue-head response demux;
- group-local simultaneous same-cycle enqueue widening;
- packed burst-vector outputs or alternate payload assembly;
- direct backend lowering;
- VHDL.
