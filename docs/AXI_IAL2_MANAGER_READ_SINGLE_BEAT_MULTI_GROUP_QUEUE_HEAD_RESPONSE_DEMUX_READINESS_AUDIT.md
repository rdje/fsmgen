# AXI IAL2 Manager Read Single-Beat Multi-Group Queue-Head Response-Demux Readiness Audit

Status: readiness audit for `IAL2-FEATURE-COMPLETENESS-FRONTIER.142` on
2026-06-16.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.142`

## Purpose

This audit follows the `.141` selector and checks whether generated read
single-beat concrete same-ID queue-head response-demux behavior can safely
widen from one duplicate concrete read-ID group to multiple duplicate concrete
read-ID groups.

The selected next owner is `IAL2-FEATURE-COMPLETENESS-FRONTIER.143`:
generated read single-beat multi-group queue-head response-demux.

No parser, generator, PPIF sample, support-accounting, test, generated
artifact, or HDL behavior changes in this audit.

## Evidence Read

- `.141` selector:
  `docs/AXI_IAL2_MANAGER_POST_WRITE_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md`
- write multi-group queue-head readiness and behavior:
  `docs/AXI_IAL2_MANAGER_WRITE_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT.md`
  and
  `docs/AXI_IAL2_MANAGER_WRITE_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md`
- read burst-last multi-group queue-head readiness and behavior:
  `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT.md`
  and
  `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md`
- one-group read single-beat queue-head behavior:
  `docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md`
- one-group write queue-head behavior:
  `docs/AXI_IAL2_MANAGER_WRITE_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md`
- current queue-head planner, builder, transition, assertion, read-data
  coverage, report, residue, test, public PPIF sample, support accounting,
  README, roadmap, mdBook, task tree, Memory, and Knowledge Map surfaces.

## Current Behavior

The shipped read single-beat one-group queue-head sample remains generated:

```text
ppif/axi_manager_capacity_status_read_single_beat_same_id_queue_head_response_demux.ppif
generated=1
boundary=generated_read_single_beat_queue_head_demux
groups=1
same_status=generated_read_single_beat_queue_head_demux
response_residue=read_data_interleaving,bursts
```

The shipped read burst-last multi-group queue-head sample remains generated:

```text
ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_response_demux.ppif
generated=1
boundary=generated_read_burst_last_queue_head_demux
groups=2
same_status=generated_read_burst_last_queue_head_demux
response_residue=read_data_interleaving,bursts
```

The shipped write multi-group queue-head sample remains generated:

```text
ppif/axi_manager_capacity_status_write_multi_group_same_id_queue_head_response_demux.ppif
generated=1
boundary=generated_write_bid_queue_head_demux
groups=2
same_status=generated_write_bid_queue_head_demux
response_residue=read_response_demux,read_data_interleaving,bursts
```

A temporary `/tmp/fsmgen_read_single_multi_group_probe.ppif` source with
`r0`/`r1` sharing concrete `RID` `3` and `r2`/`r3` sharing concrete `RID` `5`
is accepted as selected queue-head metadata, but remains generated-false:

```text
generated=0
read_generated=0
scope=single_beat
groups=2
selected_signals=axi0_r0_complete,axi0_r1_complete,axi0_r2_complete,axi0_r3_complete
same_status=admitted_request_pulses_generated
response_residue=generated_same_id_queue_head_demux,read_data_interleaving,bursts
same_residue=concrete_id_same_id_ordering,per_id_issue_order_queues
```

That is the expected pre-`.143` state. The temporary probe was removed after
the audit.

## Code Findings

The queue-head planning path is already multi-group aware for read
single-beat:

- `_response_demux_queue_head_plan_for_family` records all duplicate concrete
  read-ID groups plus selected completion signals for the read family;
- `_same_id_duplicate_concrete_groups` is family-generic and already emits one
  queue group per duplicate concrete `RID`;
- `_normalize_response_demux_read` records `response_scope: single_beat`,
  queue groups, and selected completion signals without requiring `RLAST`.

The generation blocker is a narrow admission gate:

- `_build_same_id_issue_order_queue_behavior` accepts read single-beat when a
  single group is present;
- the same helper accepts multiple read groups only when the read scope is
  `burst_last` with a one-bit `last_signal`;
- the same helper accepts multiple write groups after `.140`;
- therefore the read single-beat two-group probe remains selected-not-generated
  solely because multi-group read single-beat is not yet admitted.

Downstream generation is already group-iterative once behavior exists:

- queue-state storage names include manager, read family, concrete ID, slot,
  and transaction name;
- `_same_id_issue_order_queue_transition_specs` is group-local and uses each
  transaction's admitted request pulse plus the group-local queue-head match;
- `_same_id_issue_order_queue_head_match_expr` omits `last_signal` when the
  group has no `last_signal`, matching the shipped one-group read single-beat
  behavior;
- `_same_id_issue_order_queue_assertion_specs_for_group` adds the non-last
  no-dequeue assertion only when `last_signal` exists, so single-beat groups
  keep the shipped read single-beat assertion set;
- response-demux state extraction, rule emission, report movement, generated
  queue reports, and residue movement already iterate groups for read.

Read-data remains intentionally narrower:

- `_read_data_response_demux_transaction_coverage` still requires exactly one
  queue group for read single-beat queue-head read-data coverage;
- `.143` should add no `read_data` clause and should not widen read-data
  capture over multiple single-beat queue-head groups.

The existing admission boundary remains explicit:

- admitted request pulse generation emits a family-wide
  `*_issue_order_queue_request_onehot0` assertion across all selected read
  request events in the manager object;
- `.143` may generate multiple read single-beat queue groups under that
  one-admitted-read-request-per-cycle contract;
- `.143` must not claim group-local simultaneous same-cycle enqueue support
  for different concrete read IDs.

No lower-layer prerequisite is evident:

- parser syntax already admits the temporary two-group read single-beat source;
- support-accounting can add a bounded public PPIF sample using the same
  source shape;
- generated IAL1, IAL0, and SystemVerilog already lower one-group read
  single-beat queue-head behavior and read burst-last multi-group behavior;
- the response-demux-only shape does not interact with read-data payload
  capture, `RLAST`, burst-length, beat-count validation, packed outputs,
  direct backend, or VHDL.

## Selection

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.143`, generated read single-beat
multi-group queue-head response-demux.

The `.143` implementation boundary is:

- read family only;
- `response-demux.read.response-scope single-beat` only;
- generated queue-head response demux only;
- no `last-signal`;
- no `read_data` clause;
- two or more duplicate concrete read-ID groups in the same manager object;
- every covered group has exactly two read transactions and computed depth
  `2`;
- selected `same-id-ordering.read concrete-id-reuse issue-order-queue`;
- no same-family `auto-id-lifecycle` response demux;
- generated compact one-hot queue storage, queue update rules, assertions,
  response-demux rules, and completion pulse outputs per read group;
- group names include the concrete read ID value and transaction name;
- existing family-wide admitted-request onehot remains the admission contract;
- generated reports list all generated read queues and remove
  `generated_same_id_queue_head_demux` residue for the covered response-demux
  family;
- no read-data capture over multiple read single-beat queue-head groups;
- no read burst-last widening beyond `.124`;
- no write-family widening beyond `.140`;
- no queue depth greater than `2`;
- no group-local simultaneous enqueue widening;
- no packed outputs, alternate payload assembly, direct backend, or VHDL work.

`.143` should add a public support-accounted PPIF sample with two duplicate
concrete read-ID groups, for example `r0`/`r1` at concrete `RID` `3` and
`r2`/`r3` at concrete `RID` `5`, and no `read_data` clause.

## Validation Gates For .143

The implementation slice should run:

- syntax checks for touched Perl modules and focused tests;
- focused generator and PPIF/CLI suites or narrow equivalent tests covering
  the new public sample;
- direct `--emit-schedule-json`, `--strict --check --json`,
  `--strict --emit-semantic-json`, and `--quiet --verify-hdl` probes for the
  new read single-beat multi-group public PPIF sample;
- preservation probes for existing one-group read single-beat queue-head, read
  burst-last multi-group queue-head, write multi-group queue-head, queue-head
  read-data, burst-length, runtime-validation, and multi-beat queue-head
  samples;
- support-accounting corpus gates after adding the sample;
- Knowledge Map generation/check, mdBook build, docs path audit, memory
  architecture check, diff hygiene, README numbering, and stale/positive
  frontier scans.

## Rollback Boundary

Because `.142` is audit-only, rollback is documentation and task-tree state
only.

For `.143`, rollback should be the new public PPIF sample,
support-accounting entry, focused tests, and the builder/report widening that
turns read single-beat multi-group queue-head response-demux from
selected-not-generated into generated behavior.

## Deferred Work

The following remain outside `.143`:

- read-data capture over multiple read single-beat queue-head groups;
- queue groups deeper than two slots;
- same-family mixed auto-ID plus concrete queue-head response demux;
- group-local simultaneous same-cycle enqueue widening;
- packed burst-vector outputs and alternate payload assembly;
- direct backend lowering;
- VHDL.
