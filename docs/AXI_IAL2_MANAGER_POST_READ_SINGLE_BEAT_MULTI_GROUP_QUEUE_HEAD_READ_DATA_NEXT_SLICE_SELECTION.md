# AXI IAL2 Manager Post Read Single-Beat Multi-Group Queue-Head Read-Data Next Slice Selection

Status: selector for `IAL2-FEATURE-COMPLETENESS-FRONTIER.147` on
2026-06-16.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.147`

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.148`, readiness audit for
generated concrete same-ID queue-head groups deeper than two slots.

No parser, generator, PPIF sample, support-accounting, test, generated
artifact, or HDL behavior changes are made by this selector slice.

## Evidence Read

The selector read:

- `.146` generated read-data over read single-beat multi-group queue-head
  response-demux behavior;
- `.145` readiness audit for that behavior;
- `.143` generated read single-beat multi-group queue-head response-demux
  behavior;
- `.113` one-group single-beat queue-head read-data behavior;
- `.127`, `.130`, and `.135` adjacent multi-group burst-last read-data
  behavior notes;
- current response-demux normalization, same-ID queue planning, queue-state
  generation, transition, assertion, response-state, read-data coverage,
  report, and residue code in
  `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`;
- focused generator and PPIF/CLI tests, public PPIF samples, support
  accounting, README, roadmap, mdBook, task tree, Memory, and Knowledge Map.

## Live Report Findings

The current generated queue-head families are all depth-2 bounded shapes:

```text
ppif/axi_manager_capacity_status_read_single_beat_multi_group_same_id_queue_head_read_data.ppif
  read single-beat queue-head groups: RID 3 d2 [r0,r1], RID 5 d2 [r2,r3]
  read_data: single-beat, completion_validity generated_queue_head_response_demux_completion_pulse

ppif/axi_manager_capacity_status_read_single_beat_multi_group_same_id_queue_head_response_demux.ppif
  read single-beat queue-head groups: RID 3 d2 [r0,r1], RID 5 d2 [r2,r3]
  read_data: absent

ppif/axi_manager_capacity_status_read_single_beat_same_id_queue_head_read_data.ppif
  read single-beat queue-head groups: RID 3 d2 [r0,r1]
  read_data: single-beat, completion_validity generated_queue_head_response_demux_completion_pulse

ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_response_demux.ppif
  read burst-last queue-head groups: RID 3 d2 [r0,r1], RID 5 d2 [r2,r3]
  read_data: absent

ppif/axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_read_data.ppif
  read burst-last queue-head groups: RID 3 d2 [r0,r1], RID 5 d2 [r2,r3]
  read_data: last-beat, completion_validity generated_queue_head_response_demux_last_beat_completion_pulse

ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_read_data.ppif
  read burst-last queue-head groups: RID 3 d2 [r0,r1], RID 5 d2 [r2,r3]
  read_data: multi-beat, response_demux residue [], read_data residue []

ppif/axi_manager_capacity_status_write_multi_group_same_id_queue_head_response_demux.ppif
  write queue-head groups: BID 3 d2 [w0,w1], BID 5 d2 [w2,w3]
  read_data: absent
```

Support accounting has no public deeper-queue corpus entry yet. The public
docs and support prose still correctly defer deeper concrete same-ID queues.

## Code Findings

`_same_id_duplicate_concrete_groups` can describe a duplicate concrete-ID
group with computed depth greater than `2` when more than two transactions
share one concrete ID and the family pending limit admits them.

The generated queue-head behavior builder is not ready to consume that
metadata directly:

- `_build_same_id_issue_order_queue_behavior` rejects any generated group
  whose `depth` is not exactly `2` or whose transaction count is not exactly
  `2`;
- queue storage allocation creates only `slot0` and `slot1`;
- `_same_id_issue_order_queue_transition_specs` destructures only two
  transactions and hand-enumerates the finite depth-2 transition matrix;
- assignment, state, full, compactness, unique-slot, and duplicate-after-
  dequeue helpers are specialized around slots `0` and `1`;
- response-demux response states and read-data coverage can iterate generated
  transactions once behavior exists, but they depend on a valid generated
  queue-head behavior object.

The next behavior-bearing work is therefore not just another narrow builder
gate. It needs an audit of the public first deeper fixture, transition
semantics, compact queue representation, assertions, diagnostics, report
movement, read-data consumers, and preservation boundaries.

## Selection

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.148`, readiness audit for
generated concrete same-ID queue-head groups deeper than two slots.

The `.148` audit boundary is:

- audit-only, with no behavior changes;
- generated queue-head response-demux only;
- duplicate concrete-ID groups where at least one selected group has three or
  more transactions and computed depth greater than `2`;
- read and write families considered as evidence, but no implementation
  family chosen until the audit completes;
- inspect whether the first behavior owner should generalize shared queue
  state first or select a narrower response-demux-only family;
- inspect effects on generated completion signals, read-data coverage,
  queue-head match expressions, assertions, response-demux residue,
  support-accounting, check JSON, semantic JSON, generated HDL, docs, and
  mdBook before any behavior change.

## Deferred Work

The following remain outside `.147` and `.148` unless the audit selects a
separate exact owner:

- implementation behavior changes in `.147`;
- same-family mixed `auto-id-lifecycle` plus concrete queue-head demux;
- group-local simultaneous same-cycle enqueue widening;
- packed burst-vector outputs and alternate payload assembly;
- direct backend lowering;
- VHDL.

## Validation Gates For .148

The audit should run compact schedule/check/semantic probes for:

- existing `.146`, `.143`, `.140`, `.135`, `.132`, `.130`, `.127`, and `.113`
  public samples;
- temporary read single-beat, read burst-last, write, and read-data deeper
  queue shapes, removed after inspection;
- focused generator and PPIF/CLI test ownership for queue-head transition and
  read-data coverage diagnostics;
- support-accounting, README, roadmap, mdBook, task tree, Memory, Knowledge
  Map, and standard continuity gates.

## Rollback Boundary

Because `.147` is selector-only, rollback is documentation, task-tree,
Memory, and Knowledge Map state only.
