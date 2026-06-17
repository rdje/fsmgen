# AXI IAL2 Manager Write Multi-Group Queue-Head Response-Demux Readiness Audit

Status: readiness audit for `IAL2-FEATURE-COMPLETENESS-FRONTIER.139` on
2026-06-16.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.139`

## Purpose

This audit follows the `.138` selector and checks whether generated
write-family concrete same-ID queue-head response-demux behavior can safely
widen from one duplicate concrete write-ID group to multiple duplicate
concrete write-ID groups.

The selected next owner is `IAL2-FEATURE-COMPLETENESS-FRONTIER.140`:
generated write-family multi-group queue-head response-demux.

No parser, generator, PPIF sample, support-accounting, test, generated
artifact, or HDL behavior changes in this audit.

## Evidence Read

- `.138` selector:
  `docs/AXI_IAL2_MANAGER_POST_SUPPORT_RESIDUE_CLEANUP_NEXT_SLICE_SELECTION.md`
- `.137` support-residue cleanup note:
  `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md`
- one-group write queue-head behavior:
  `docs/AXI_IAL2_MANAGER_WRITE_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md`
- read burst-last multi-group queue-head readiness and behavior:
  `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT.md`
  and
  `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md`
- one-group read single-beat queue-head behavior:
  `docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md`
- current queue-head planner, builder, response-demux rule, assertion,
  report, and residue code in
  `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`
- focused generator and PPIF/CLI tests:
  `t/1437-axi-ial2-manager-capacity-status-generator.t` and
  `t/1436-ial2-ppif-parser-cli.t`
- public queue-head PPIF samples under `ppif/`
- README, roadmap, mdBook, task tree, Memory, and Knowledge Map fact cards.

## Current Behavior

The shipped one-group write queue-head sample remains generated:

```text
ppif/axi_manager_capacity_status_write_same_id_queue_head_response_demux.ppif
generated=1
boundary=generated_write_bid_queue_head_demux
groups=1
same_status=generated_write_bid_queue_head_demux
response_residue=read_response_demux,read_data_interleaving,bursts
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

The shipped read single-beat one-group queue-head sample remains generated:

```text
ppif/axi_manager_capacity_status_read_single_beat_same_id_queue_head_response_demux.ppif
generated=1
boundary=generated_read_single_beat_queue_head_demux
groups=1
same_status=generated_read_single_beat_queue_head_demux
response_residue=read_data_interleaving,bursts
```

A temporary `/tmp/fsmgen_write_multi_group_probe.ppif` source with `w0`/`w1`
sharing concrete `BID` `3` and `w2`/`w3` sharing concrete `BID` `5` is
accepted as selected queue-head metadata, but remains generated-false:

```text
generated=0
groups=2
same_generated=0
same_status=admitted_request_pulses_generated
response_residue=read_response_demux,generated_same_id_queue_head_demux,read_data_interleaving,bursts
same_residue=concrete_id_same_id_ordering,per_id_issue_order_queues
```

That is the expected pre-`.140` state.

## Code Findings

The queue-head planning path is already multi-group aware for write:

- `_response_demux_queue_head_plan_for_family` is family-generic and records
  all duplicate concrete-ID groups plus selected completion signals for the
  selected family.
- `_same_id_duplicate_concrete_groups` groups concrete transactions by
  concrete ID regardless of read/write family.
- The write two-group probe already reports two
  `response_demux.write.same_id_issue_order_queues` entries.

The generation blocker is a narrow admission gate:

- `_build_same_id_issue_order_queue_behavior` currently permits multiple
  groups only when the selected family is read `burst_last` with a one-bit
  `last_signal`.
- For write, this gate returns `undef` when more than one duplicate concrete
  write-ID group exists, leaving the selected queue-head metadata generated
  false and preserving `generated_same_id_queue_head_demux` residue.

The downstream generation path is already group-iterative once behavior
exists:

- queue-state storage names include manager, family, concrete ID, slot, and
  transaction name, so distinct concrete write-ID groups do not collide;
- `_same_id_issue_order_queue_transition_specs` is group-local and uses each
  transaction's admitted pulse plus the group-local queue-head match;
- `_same_id_issue_order_queue_head_match_expr` uses response event, response
  ID equality, optional `last_signal`, and the head slot bit. Write groups have
  no `last_signal`, matching the one-group write behavior;
- `_same_id_issue_order_queue_assertion_specs_for_group` adds the non-last
  no-dequeue assertion only when `last_signal` exists, so write groups keep
  the existing write assertion set;
- response-demux state extraction, rule emission, report movement, generated
  queue reports, and residue movement all iterate groups for both write and
  read families.

The existing admission boundary must stay explicit:

- the same-ID admitted request boundary emits a family-wide onehot assertion
  across all selected write request events;
- `.140` may generate multiple write queue groups under the current
  one-admitted-write-request-per-cycle capacity/status contract;
- `.140` must not claim group-local simultaneous same-cycle enqueue support
  for different concrete write IDs.

No lower-layer prerequisite is evident:

- parser syntax already admits the temporary two-group write source;
- support-accounting can add a bounded public PPIF sample using the existing
  source shape;
- generated IAL1/IAL0/SystemVerilog already lower one-group write queue-head
  behavior and read burst-last multi-group queue-head behavior;
- write response-demux does not interact with read-data, `RLAST`,
  burst-length, read interleaving, or read payload assembly.

## Selection

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.140`, generated write-family
multi-group queue-head response-demux.

The `.140` implementation boundary is:

- write family only;
- generated queue-head response demux only;
- two or more duplicate concrete write-ID groups in the same manager object;
- every covered group has exactly two write transactions and computed depth
  `2`;
- selected `same-id-ordering.write concrete-id-reuse issue-order-queue`;
- no same-family `auto-id-lifecycle` response demux;
- generated compact one-hot queue storage, queue update rules, assertions,
  response-demux rules, and completion pulse outputs per write group;
- group names include the concrete write ID value and transaction name;
- existing family-wide admitted-request onehot remains the admission contract;
- generated reports list all generated write queues and remove
  `generated_same_id_queue_head_demux` residue for the covered response-demux
  family;
- no read-family expansion;
- no read single-beat multi-group behavior;
- no queue depth greater than `2`;
- no group-local simultaneous enqueue widening;
- no packed outputs, alternate payload assembly, direct backend, or VHDL work.

`.140` should add a public support-accounted PPIF sample with two duplicate
concrete write-ID groups, for example `w0`/`w1` at concrete `BID` `3` and
`w2`/`w3` at concrete `BID` `5`.

## Validation Gates For .140

The implementation slice should run:

- syntax checks for touched Perl modules and focused tests;
- focused generator and PPIF/CLI suites or narrow equivalent tests covering
  the new public sample;
- direct `--emit-schedule-json`, `--strict --check --json`,
  `--strict --emit-semantic-json`, and `--quiet --verify-hdl` probes for the
  new write multi-group public PPIF sample;
- preservation probes for existing one-group write queue-head, read burst-last
  multi-group queue-head, read single-beat queue-head, read-data queue-head,
  burst-length, runtime-validation, and multi-beat queue-head samples;
- support-accounting corpus gates after adding the sample;
- Knowledge Map generation/check, mdBook build, docs path audit, memory
  architecture check, diff hygiene, README numbering, and stale/positive
  frontier scans.

## Rollback Boundary

Because `.139` is audit-only, rollback is documentation and task-tree state
only.

For `.140`, rollback should be the new public PPIF sample,
support-accounting entry, focused tests, and the builder/report widening that
turns write multi-group queue-head response-demux from selected-not-generated
into generated behavior.

## Deferred Work

The following remain outside `.140`:

- read single-beat multi-group queue-head behavior;
- additional queue-depth widening beyond the later selected one-group
  depth-3 read single-beat response-demux/read-data shapes;
- same-family mixed auto-ID plus concrete queue-head response demux;
- group-local simultaneous same-cycle enqueue widening;
- packed burst-vector outputs and alternate payload assembly;
- direct backend lowering;
- VHDL.
