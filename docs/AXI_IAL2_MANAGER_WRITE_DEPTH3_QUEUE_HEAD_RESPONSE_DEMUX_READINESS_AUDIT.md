# AXI IAL2 Manager Write Depth-3 Queue-Head Response-Demux Readiness Audit

Status: readiness audit for `IAL2-FEATURE-COMPLETENESS-FRONTIER.170` on
2026-06-17.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.170`

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.171`, direct bounded
implementation of generated write-family depth-3 concrete same-ID queue-head
response-demux behavior.

This audit makes no parser, generator, PPIF sample, support-accounting, test,
generated artifact, or HDL behavior change. It only records that the next
behavior-bearing work can be owned by `.171`.

## Evidence Read

The audit read:

- the `.169` selector;
- the `.168` read burst-last depth-3 queue-head multi-beat behavior;
- the `.149` read single-beat depth-3 queue-head response-demux behavior;
- the `.156` read burst-last depth-3 queue-head response-demux behavior;
- the `.108` write depth-2 queue-head response-demux behavior;
- the `.140` write multi-group depth-2 queue-head response-demux behavior;
- current same-ID issue-order queue admission, transition, storage,
  assertion, response-demux, report, focused-test, PPIF/CLI, support
  accounting, README, roadmap, mdBook, task-tree, Memory, and Knowledge Map
  surfaces.

## Live Probe Findings

The existing one-group write depth-2 sample remains generated and
support-accounted:

```text
ppif/axi_manager_capacity_status_write_same_id_queue_head_response_demux.ppif
  generated=1
  implementation_status=generated
  boundary=generated_write_bid_queue_head_demux
  queue=3:w0/w1:d2
  completion_signals=2
  response_demux_rules=2
  response_demux_assertions=2
  queue_storage=4
  queue_update_rules=12
  queue_assertions=11
  strict_check.success=1
  support_accounting.entry=intent.ppif_axi_manager_capacity_status_write_same_id_queue_head_response_demux
```

The existing write multi-group depth-2 sample remains generated and
support-accounted:

```text
ppif/axi_manager_capacity_status_write_multi_group_same_id_queue_head_response_demux.ppif
  generated=1
  implementation_status=generated
  boundary=generated_write_bid_queue_head_demux
  queues=3:w0/w1:d2,5:w2/w3:d2
  completion_signals=4
  response_demux_rules=4
  response_demux_assertions=7
  per_queue_storage=4
  per_queue_update_rules=12
  per_queue_assertions=11
  strict_check.success=1
  support_accounting.entry=intent.ppif_axi_manager_capacity_status_write_multi_group_same_id_queue_head_response_demux
```

The generated read depth-3 siblings prove the queue-state machinery already
handles one depth-3 duplicate concrete-ID group:

```text
ppif/axi_manager_capacity_status_read_single_beat_depth3_same_id_queue_head_response_demux.ppif
  generated=1
  boundary=generated_read_single_beat_queue_head_demux
  queue=3:r0/r1/r2:d3
  completion_signals=3
  response_demux_rules=3
  response_demux_assertions=4
  queue_storage=9
  queue_update_rules=54
  queue_assertions=14
  strict_check.success=1

ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_response_demux.ppif
  generated=1
  boundary=generated_read_burst_last_queue_head_demux
  queue=3:r0/r1/r2:d3
  completion_signals=3
  response_demux_rules=3
  response_demux_assertions=4
  queue_storage=9
  queue_update_rules=54
  queue_assertions=15
  strict_check.success=1
```

A temporary `/tmp` write depth-3 candidate with `w0`, `w1`, and `w2` sharing
concrete `BID` `3`, `write-max-pending 3`, selected
`same-id-ordering.write concrete-id-reuse issue-order-queue`, and generated
write response-demux passes strict check with no diagnostics but remains
selected-not-generated:

```text
/tmp/fsmgen_write_depth3_audit_probe.ppif
  mode=bounded_write_bid_queue_head_demux_contract
  generated=0
  implementation_status=selected_not_generated
  queue=3:w0/w1/w2:d3
  response_demux.residue=read_response_demux,generated_same_id_queue_head_demux,read_data_interleaving,bursts
  same_id_ordering.residue=concrete_id_same_id_ordering,per_id_issue_order_queues
  strict_check.success=1
  diagnostics=0
  support_accounting.matched=0
  semantic_support_accounting.matched=0
```

## Code Findings

The local gate is `_build_same_id_issue_order_queue_behavior` in
`perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`. It already admits:

- one or more depth-2 generated groups for read single-beat, read burst-last,
  or write response-demux;
- exactly one read single-beat depth-3 group;
- exactly one read burst-last depth-3 group.

It does not yet admit exactly one write depth-3 group. After admission, the
downstream helpers are already depth/group driven:

- queue storage iterates `0 .. depth - 1` slots and all transactions;
- transition generation enumerates compact queue states for the supplied
  depth;
- response-demux states and rules iterate the generated queue transactions;
- response-demux assertions derive from the generated states;
- same-ID ordering reports expose generated queues, storage, transition
  rules, and assertions from the same queue group;
- the focused write report helper already accepts explicit expected queues,
  completion signals, generated rules, and generated assertions.

The read single-beat depth-3 sibling shows the exact non-`RLAST` depth-3
queue shape `.171` should mirror for the write family: 9 queue slot storage
signals, 54 queue update rules, 14 queue assertions, 3 response-demux rules, 3
generated completion signals, and 4 response-demux assertions.

## Selected .171 Boundary

`.171` should implement only:

- write family only;
- generated `response-demux.write`;
- raw write response event `axi0_write_complete`;
- generated transaction completion ownership;
- generated queue-head response-demux boundary
  `generated_write_bid_queue_head_demux`;
- exactly one duplicate concrete write-ID group;
- exactly three write transactions, `w0`, `w1`, and `w2`;
- concrete `BID` `3`;
- computed write queue depth `3`;
- selected `same-id-ordering.write concrete-id-reuse issue-order-queue`;
- public sample
  `ppif/axi_manager_capacity_status_write_depth3_same_id_queue_head_response_demux.ppif`;
- support-accounting entry
  `intent.ppif_axi_manager_capacity_status_write_depth3_same_id_queue_head_response_demux`;
- coverage bucket
  `ial2_ppif_manager_capacity_status_write_depth3_same_id_queue_head_response_demux_pipeline_cli`.

Expected generated artifacts for the covered sample:

- generated `axi0_bid` input and raw `axi0_write_complete` response event;
- generated completion outputs `axi0_w0_complete`, `axi0_w1_complete`, and
  `axi0_w2_complete`;
- generated queue storage for `slot0`, `slot1`, and `slot2` across `w0`,
  `w1`, and `w2`;
- 54 queue update rules;
- 14 queue assertions;
- response-demux rules `axi0_w0_response_demux`,
  `axi0_w1_response_demux`, and `axi0_w2_response_demux`;
- response-demux assertions `axi0_write_response_demux_active_match`,
  `axi0_w0_w1_write_response_demux_unique_match`,
  `axi0_w0_w2_write_response_demux_unique_match`, and
  `axi0_w1_w2_write_response_demux_unique_match`;
- `response_demux.residue` without `generated_same_id_queue_head_demux`;
- same-ID write policy reporting `accepted_same_id_reuse: true`,
  `generated_queue_behavior: true`, and
  `implementation_status: generated_write_bid_queue_head_demux`.

`.171` must preserve the existing write depth-2 one-group and multi-group
samples, all read depth-3 response-demux/read-data/burst-length/runtime
validation/multi-beat samples, support accounting, and HDL verification.

## Non-Goals

`.171` must not enable read-data, burst-length, runtime-validation,
multi-beat payload, read response-demux, `RLAST`, write multi-group depth-3,
mixed read/write depth-3, mixed depth-2/depth-3 generated groups, same-family
mixed auto-ID plus concrete queue-head demux, group-local simultaneous enqueue
widening, packed outputs, alternate burst assembly, direct backend,
verification-output generation, VHDL, or backend-language variants.

## Validation Scope

The implementation leaf should run focused syntax checks, direct
schedule/check/semantic/verify-HDL probes for the new PPIF sample, focused
generator and PPIF/CLI tests, regression-corpus accounting, supported-corpus
check JSON and normalized semantic JSON gates, Knowledge Map generation/check,
mdBook build, docs relative-path audit, memory architecture check, diff
hygiene, README numbering, and stale/positive frontier scans.
