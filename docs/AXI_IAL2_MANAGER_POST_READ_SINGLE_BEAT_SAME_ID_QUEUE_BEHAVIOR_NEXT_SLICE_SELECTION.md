# AXI IAL2 Manager Post-Read-Single-Beat Same-ID Queue Behavior Next-Slice Selection

Task-tree owner:
`IAL2-FEATURE-COMPLETENESS-FRONTIER.111`.

Date: `2026-06-15`.

## Purpose

This selector audits the remaining AXI concrete same-ID queue-head work after
three bounded generated queue-head behaviors have shipped:

- read burst-last depth-2 queue-head demux:
  `generated_read_burst_last_queue_head_demux`;
- write depth-2 queue-head `BID` demux:
  `generated_write_bid_queue_head_demux`;
- read single-beat depth-2 queue-head `RID` demux:
  `generated_read_single_beat_queue_head_demux`.

The selected next owner is
`IAL2-FEATURE-COMPLETENESS-FRONTIER.112`: readiness audit for AXI read-data
consumption of generated concrete same-ID queue-head demux.

No parser, generator, support-accounting, sample, test, generated artifact, or
HDL behavior changes in this selector.

## Current State

The queue-head implementation now covers the minimal read/write family
variants for one duplicate concrete ID group of two transactions at depth 2.
All three covered public samples generate compact one-hot queue state,
admitted request enqueue pulses, queue update rules, generated transaction
completion pulse outputs, queue-head response-demux rules, and report/residue
movement.

The read single-beat queue-head sample proves the no-`RLAST` read path. The
read burst-last queue-head sample proves the `RLAST`-qualified dequeue path.
The write queue-head sample proves the no-last-signal write path.

The existing generated read-data path is different: it consumes generated
auto-ID read response-demux completion pulses, not concrete queue-head demux
metadata. Current normalization intentionally rejects a `read_data` clause when
`response_demux.read.transaction_completion_source` is
`generated_queue_head_demux`:

```text
read_data cannot consume concrete same-ID queue-head response_demux.read metadata
```

The test suite also locks that fail-closed diagnostic. Same-family mixed
`auto_id_lifecycle` plus concrete same-ID queue-head demux is still guarded
separately.

## Selection

Select `.112`, a readiness audit before any behavior change. The audit should
answer whether the first safe behavior-bearing slice can reuse the existing
read-data capture substrate with generated concrete queue-head read completion
pulses.

The likely first behavior boundary, if the audit confirms it, is:

- read family only;
- `response-demux.read.response_scope` is `single-beat`;
- concrete same-ID queue-head behavior is already generated;
- exactly one duplicate concrete read-ID group;
- exactly two read transactions in that group;
- computed queue depth is `2`;
- a `read-data` single-beat capture contract consumes the generated
  queue-head completion pulses for those transactions;
- `RDATA` and `RRESP` source inputs and transaction-bound outputs reuse the
  existing generated read-data capture rule shape;
- no `RLAST`, burst, multi-beat output-bank, deeper queue, multiple group, or
  mixed auto-ID behavior is added in the first candidate behavior slice.

The audit may instead select a smaller prerequisite if the existing read-data
normalization/report shape, artifact lists, residue accounting, or diagnostics
need metadata alignment before behavior can safely change.

## Why This Slice

Read-data consumption is the smallest useful next expansion after `.110`
because:

- both bounded read queue-head response scopes are now generated;
- the existing read-data generator already knows how to capture `RDATA` and
  `RRESP` on per-transaction generated completion pulses;
- the current blocker is an explicit queue-head-consumption guard, not an
  absent lower-layer assignment or port-width substrate;
- deeper queues and multiple duplicate-ID groups require a broader queue
  generator generalization;
- mixed auto-ID plus concrete queue-head demux crosses response ownership and
  ID-release policy in the same family.

This keeps the next step focused on validating whether generated queue-head
completion pulses can become an accepted read-data completion source.

## Deferred Work

The following remain outside `.112` unless it explicitly selects one of them
as a later owner:

- generated read-data behavior changes;
- read burst-last or multi-beat queue-head read-data consumption;
- queue groups deeper than two slots;
- more than one duplicate concrete-ID group;
- same-family mixed auto-ID plus concrete queue-head demux;
- generalized per-ID issue-order queues;
- direct backend lowering;
- VHDL.

## Validation Gates

The `.112` audit should include:

- live schedule probes for the read single-beat, read burst-last, and write
  queue-head public samples;
- current diagnostic coverage for `read_data` consuming queue-head read demux;
- current generated read-data capture docs/tests/report reads;
- code reads for response-demux, same-ID queue behavior, read-data
  normalization, generated artifact reporting, and residue movement;
- README, roadmap, mdBook, task tree, Memory, and Knowledge Map sync;
- `scripts/check_memory_architecture.sh`, Knowledge Map check, mdBook build,
  docs path audit, and diff hygiene.

## Rollback

Rollback is documentation-only for this selector: revert this note plus the
`.111` task-tree, README, roadmap, mdBook, Memory, and Knowledge Map updates.
No parser, generator, sample, support-accounting, test, generated artifact, or
HDL behavior is changed by `.111`.
