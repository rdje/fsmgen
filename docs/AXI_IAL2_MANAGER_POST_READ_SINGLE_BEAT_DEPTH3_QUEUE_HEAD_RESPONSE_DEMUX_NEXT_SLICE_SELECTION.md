# AXI IAL2 Manager Post Read Single-Beat Depth-3 Queue-Head Response-Demux Next Slice Selection

Status: selector for `IAL2-FEATURE-COMPLETENESS-FRONTIER.150` on
2026-06-17.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.150`

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.151`, support-detail expectation
alignment after generated read single-beat depth-3 queue-head response-demux.

No parser, generator, PPIF sample, support-accounting, generated artifact, or
HDL behavior changes are made by this selector slice.

## Evidence Read

The selector read:

- `.149` generated read single-beat depth-3 queue-head response-demux behavior;
- `.148` deeper queue-head readiness audit;
- adjacent depth-2 queue-head response-demux and read-data behavior notes;
- current response-demux, same-ID queue, read-data coverage, report, and
  residue code in
  `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`;
- focused generator and PPIF/CLI tests, public PPIF samples, support
  accounting, README, roadmap, mdBook, task tree, Memory, and Knowledge Map.

## Live Findings

The support-accounted `.149` sample remains generated only for read
single-beat response-demux:

```text
ppif/axi_manager_capacity_status_read_single_beat_depth3_same_id_queue_head_response_demux.ppif
  response_generated=1
  read_boundary=generated_read_single_beat_queue_head_demux
  signals=axi0_r0_complete,axi0_r1_complete,axi0_r2_complete
  groups=3:3:r0,r1,r2
  residue=read_data_interleaving,bursts
  same_id_generated=1
```

`read_data` over generated queue-head response-demux remains intentionally
bounded to depth-2 groups today. The depth-3 public sample has no `read_data`
clause and keeps read-data over depth-3 queues deferred.

Focused PPIF parser/CLI validation exposed a narrower validation drift: the
production support-detail string now explicitly names independent `depth-2`
queue-head groups for shipped multi-group read-data and burst behavior, while
the focused regex still expected the older phrase without the `depth-2`
qualifier.

## Selection

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.151`, support-detail expectation
alignment, before any feature widening.

This is the next smallest safe owner because:

- the depth-3 response-demux behavior shipped in `.149` is already
  support-accounted;
- read-data over depth-3 queue-head demux still requires a separate behavior
  owner because the current coverage gate is depth-2-specific;
- the focused PPIF failure is a validation-surface drift, not a report or HDL
  behavior failure; and
- keeping the baseline green before widening behavior protects the next
  feature slice from carrying unrelated stale expectations.

## Deferred Work

The following remain outside `.150` and `.151` unless separately selected:

- read-data over depth-3 queue-head response-demux;
- read burst-last depth-3 response-demux;
- write depth-3 response-demux;
- multiple or mixed depth-3 queue-head groups;
- same-family mixed auto-ID plus concrete queue-head demux;
- group-local simultaneous enqueue boundary refinement;
- packed burst-vector outputs and alternate payload assembly;
- direct backend lowering; and
- VHDL.

## Validation Gates For .151

The selected alignment slice should run:

- the focused PPIF parser/CLI validation that currently owns the stale
  support-detail expectation;
- the focused AXI manager generator suite for preservation;
- Knowledge Map, mdBook, memory-architecture, and diff hygiene gates; and
- any additional focused check needed if the expectation repair reveals a real
  report contract mismatch.

## Rollback Boundary

Because `.150` is selector-only, rollback is documentation, task-tree, Memory,
and Knowledge Map state only. `.151` must preserve parser, generator, sample,
support-accounting, generated artifact, and HDL behavior unless a separate
owner is selected.
