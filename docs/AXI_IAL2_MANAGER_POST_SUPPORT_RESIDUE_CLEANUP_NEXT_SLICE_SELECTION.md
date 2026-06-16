# AXI IAL2 Manager Post Support Residue Cleanup Next Slice Selection

Status: selector for `IAL2-FEATURE-COMPLETENESS-FRONTIER.138` on
2026-06-16.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.138`

## Context

`IAL2-FEATURE-COMPLETENESS-FRONTIER.137` cleaned the stale AXI ID/order
support-detail residue after generated runtime-validation multi-group
queue-head scalar last-beat read-data. The live `.135`, `.132`, `.130`,
`.127`, `.124`, and `.119` schedule reports remained unchanged.

The remaining queue-head gaps are now behavior gaps rather than stale report
prose:

- deeper concrete same-ID issue-order queues;
- same-family mixed `auto_id_lifecycle` plus concrete queue-head demux;
- write-family multi-group queue-head behavior;
- read single-beat multi-group queue-head behavior;
- group-local enqueue boundary refinement;
- packed burst-vector outputs and alternate payload assembly;
- direct backend lowering; and
- VHDL backend and reroute behavior.

## Live Probes

The shipped one-group write queue-head sample remains generated:

```text
ppif/axi_manager_capacity_status_write_same_id_queue_head_response_demux.ppif
write_mode=bounded_write_bid_queue_head_demux_contract
write_boundary=generated_write_bid_queue_head_demux
write_groups=1
same_status=generated_write_bid_queue_head_demux
```

A temporary `/tmp/fsmgen_write_multi_group_probe.ppif` source with `w0`/`w1`
sharing concrete `BID` `3` and `w2`/`w3` sharing concrete `BID` `5` stays
metadata-only under the current implementation:

```text
write_generated=0
write_mode=bounded_write_bid_queue_head_demux_contract
write_groups=2
same_generated=0
same_status=admitted_request_pulses_generated
response_residue=read_response_demux,generated_same_id_queue_head_demux,read_data_interleaving,bursts
same_residue=concrete_id_same_id_ordering,per_id_issue_order_queues
```

The current builder already records multiple duplicate concrete write-ID
groups in the report, but generated queue behavior still rejects multiple
groups unless the selected family is read `burst_last`.

## Selection

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.139`, readiness audit for generated
write-family multi-group queue-head response-demux behavior.

This is the narrowest behavior-facing next owner after `.137` because:

- one-group write queue-head behavior is already shipped by `.108`;
- multiple read burst-last queue-head groups are already shipped by `.124`;
- the current temporary write probe proves the next gap is a concrete
  generation gate, not parser syntax or support-accounting syntax;
- write-family response-demux-only behavior avoids read-data, `RLAST`,
  burst-length, and read interleaving concerns; and
- the implementation, if the audit finds it ready, can plausibly reuse the
  existing group-iterative queue-state, transition, assertion, report, and
  residue helpers while preserving the current family-wide admitted-request
  boundary.

The `.139` audit must decide whether a direct `.140` implementation owner is
safe, or whether group-local enqueue refinement or another prerequisite is
needed first.

## Deferred Outside .139

The following remain outside the selected audit:

- read single-beat multi-group queue-head behavior;
- deeper concrete same-ID queues;
- same-family mixed `auto_id_lifecycle` plus concrete queue-head demux;
- generated write read-data behavior, which is not applicable to AXI write
  responses in this capacity/status shell;
- packed burst-vector outputs and alternate payload assembly;
- direct backend lowering;
- VHDL backend and reroute behavior.

## Validation Gates For .139

The selected audit should run:

- live schedule probes for the one-group write queue-head sample, the
  temporary or future two-group write probe, the `.124` read burst-last
  multi-group sample, and the `.110` read single-beat one-group sample;
- code review over the queue-head planner, same-ID admitted request boundary,
  generated queue-state builder, response-demux rule generation, assertion
  generation, report movement, residue movement, and focused test helpers;
- diagnostics review proving the current two-group write boundary is
  metadata-only/generated-false before any implementation slice;
- docs, mdBook, README, roadmap, task-tree, Memory, and Knowledge Map sync;
  and
- standard continuity gates before commit.

## Rollback Boundary

This selector is documentation/task-tree state only. Rolling it back removes
this note, the `.138` task-tree/log updates, live-doc references, Memory, and
Knowledge Map updates. It does not change parser, generator, PPIF sample,
support-accounting, generated artifact, or HDL behavior.
